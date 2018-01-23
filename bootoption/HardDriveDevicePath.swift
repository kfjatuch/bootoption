/*
 * File: HardDriveDevicePath.swift
 *
 * bootoption © vulgo 2017-2018 - A command line utility for managing a
 * firmware's EFI boot menu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation

struct HardDriveDevicePath {
        
        /* Data */
        
        private let type = Data(bytes: [4])
        private let subType = Data(bytes: [1])
        private let length = Data(bytes: [42, 0])
        private var partitionNumber: UInt32 = 0
        private var partitionStart: UInt64 = 0
        private var partitionSize: UInt64 = 0
        private var partitionSignature: Data?
        private var partitionFormat: UInt8 = 2 // GPT
        private var signatureType: UInt8 = 2 // GPT UUID
        
        /* Properties */
        
        var data: Data {
                get {
                        var partitionStartValue: UInt64 = partitionStart
                        var partitionSizeValue: UInt64 = partitionSize
                        var partitionNumberValue: UInt32 = partitionNumber
                        guard let partitionSignature = self.partitionSignature else {
                                Log.logExit(EX_DATAERR)
                        }
                        var buffer = Data()
                        buffer.append(type)
                        buffer.append(subType)
                        buffer.append(length)
                        buffer.append(UnsafeBufferPointer(start: &partitionNumberValue, count: 1))
                        buffer.append(UnsafeBufferPointer(start: &partitionStartValue, count: 1))
                        buffer.append(UnsafeBufferPointer(start: &partitionSizeValue, count: 1))
                        buffer.append(partitionSignature)
                        buffer.append(partitionFormat)
                        buffer.append(signatureType)
                        return buffer
                }
        }
        var mountPoint = String()
        var partitionUuid: String? {
                get {
                        if var buffer = partitionSignature {
                                var string = String()
                                string += String(format:"%08X", buffer.remove32()) + "-"
                                string += String(format:"%04X", buffer.remove16()) + "-"
                                string += String(format:"%04X", buffer.remove16()) + "-"
                                string += String(format:"%04X", buffer.remove16().byteSwapped) + "-"
                                string += String(format:"%04X", buffer.remove16().byteSwapped)
                                string += String(format:"%08X", buffer.remove32().byteSwapped)
                                return string
                        }
                        return nil
                }
                set {
                        if var components: [String] = newValue?.components(separatedBy: "-") {
                                var buffer = Data()
                                buffer.append(components[0].hexToData(byteSwapped: true)!)
                                buffer.append(components[1].hexToData(byteSwapped: true)!)
                                buffer.append(components[2].hexToData(byteSwapped: true)!)
                                buffer.append(components[3].hexToData()!)
                                buffer.append(components[4].hexToData()!)
                                partitionSignature = buffer
                        } else {
                                Log.logExit(EX_DATAERR, "Error setting partition signature")
                        }
                }
        }
        
        /* Methods */
        
        mutating func parseHardDriveDevicePath(data: Data) -> Bool {
                var buffer: Data = data
                partitionNumber = buffer.remove32()
                partitionStart = buffer.remove64()
                partitionSize = buffer.remove64()
                partitionSignature = buffer.remove(bytesAsData: 16)
                partitionFormat = buffer.remove8()
                signatureType = buffer.remove8()
                if !buffer.isEmpty {
                        print("parseHardDriveDevicePath(): Error", to: &standardError)
                        return false
                }
                if signatureType != 2 || partitionFormat != 2 {
                        print("parseHardDriveDevicePath(): Only GPT is supported at this time", to: &standardError)
                        return false
                }
                return true
        }
        
        /* Init */
        
        init() {
                // Default values
        }
        
        /* Init from local filesystem path to loader executable */
        
        init(createUsingFilePath path: String) {
                
                let fileManager: FileManager = FileManager()
                guard fileManager.fileExists(atPath: path) else {
                        Log.logExit(EX_IOERR, "Loader not found at specified path")
                }
                guard let session:DASession = DASessionCreate(kCFAllocatorDefault) else {
                        Log.logExit(EX_UNAVAILABLE, "Failed to create DASession")
                }
                guard var volumes:[URL] = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil) else {
                        Log.logExit(EX_UNAVAILABLE, "Failed to get mounted volume URLs")
                }
                volumes = volumes.filter { $0.isFileURL }
                
                /*  Find a mounted volume path from our loader path */
                
                var longestMatch: Int = 0
                var mountedVolumePath: String = ""
                let prefix: String = "file://"
                
                for volume in volumes {
                        let unprefixedVolumeString: String = volume.absoluteString.replacingOccurrences(of: prefix, with: "")
                        let stringLength: Int = unprefixedVolumeString.characters.count
                        let start: String.Index = unprefixedVolumeString.index(unprefixedVolumeString.startIndex, offsetBy: 0)
                        let end: String.Index = unprefixedVolumeString.index(unprefixedVolumeString.startIndex, offsetBy: stringLength)
                        let test: String = String(path[start..<end])
                        
                        /*
                         *  Check if unprefixedVolumeString is the start of our loader path string,
                         *  and also the longest mounted volume path that is also a string match
                         */
                        
                        if test.uppercased() == unprefixedVolumeString.uppercased() && stringLength > longestMatch {
                                mountedVolumePath = unprefixedVolumeString
                                longestMatch = stringLength
                        }
                }
                
                mountPoint = mountedVolumePath
                
                /*  Find DAMedia registry path */
                
                let cfMountPoint: CFString = mountPoint as CFString
                
                guard let url: CFURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, cfMountPoint, CFURLPathStyle(rawValue: 0)!, true) else {
                        Log.logExit(EX_UNAVAILABLE, "Failed to create CFURL for mount point")
                }
                guard let disk: DADisk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url) else {
                        Log.logExit(EX_UNAVAILABLE, "Failed to create DADisk from volume URL")
                }
                guard let cfDescription: CFDictionary = DADiskCopyDescription(disk) else {
                        Log.logExit(EX_UNAVAILABLE, "Failed to get volume description CFDictionary")
                }
                guard let description: [String: Any] = cfDescription as? Dictionary else {
                        Log.logExit(EX_UNAVAILABLE, "Failed to get volume description as Dictionary")
                }
                guard let daMediaPath = description["DAMediaPath"] as? String else {
                        Log.logExit(EX_UNAVAILABLE, "Failed to get DAMediaPath as String")
                }
                
                /* Get the registry object for our partition */
                
                let partitionProperties: RegistryEntry = RegistryEntry(fromPath: daMediaPath)
                if (partitionProperties.getIntValue(forProperty: "GPT Attributes")) == nil {
                        Log.logExit(EX_UNAVAILABLE, "Only GPT is supported at this time")
                }
                
                /* Get properties from IO dictionary */
                
                let ioPreferredBlockSize: Int? = partitionProperties.getIntValue(forProperty: "Preferred Block Size")
                let ioPartitionID: Int? = partitionProperties.getIntValue(forProperty: "Partition ID")
                let ioBase: Int? = partitionProperties.getIntValue(forProperty: "Base")
                let ioSize: Int? = partitionProperties.getIntValue(forProperty: "Size")
                let ioUUID: String? = partitionProperties.getStringValue(forProperty: "UUID")
                if (ioPreferredBlockSize == nil || ioPartitionID == nil || ioBase == nil || ioSize == nil || ioUUID == nil) {
                        Log.logExit(EX_UNAVAILABLE, "Failed to get registry values")
                }
                
                /* Set self properties */
                
                let blockSize: Int = ioPreferredBlockSize!
                partitionNumber = UInt32(ioPartitionID!)
                partitionStart = UInt64(ioBase! / blockSize)
                partitionSize = UInt64(ioSize! / blockSize)
                partitionUuid = ioUUID!
        }
}
