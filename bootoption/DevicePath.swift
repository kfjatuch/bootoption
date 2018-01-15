/*
 * File: DevicePath.swift
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

struct HardDriveMediaDevicePath {
        
        var data: Data {
                get {
                        var data = Data.init()
                        var partitionStartValue: UInt64 = self.partitionStart
                        var partitionSizeValue: UInt64 = self.partitionSize
                        var partitionNumberValue: UInt32 = self.partitionNumber
                        data.append(type)
                        data.append(subType)
                        data.append(length)
                        data.append(UnsafeBufferPointer(start: &partitionNumberValue, count: 1))
                        data.append(UnsafeBufferPointer(start: &partitionStartValue, count: 1))
                        data.append(UnsafeBufferPointer(start: &partitionSizeValue, count: 1))
                        data.append(partitionSignature)
                        data.append(partitionFormat)
                        data.append(signatureType)
                        return data
                }
        }
        
        var mountPoint = String()
        let type = Data.init(bytes: [4])
        let subType = Data.init(bytes: [1])
        let length = Data.init(bytes: [42, 0])
        var partitionNumber: UInt32 = 0
        var partitionStart: UInt64 = 0
        var partitionSize: UInt64 = 0
        var partitionSignature = Data.init()
        var partitionFormat: UInt8 = 2 // GPT
        var signatureType: UInt8 = 2 // GPT GUID
        
        init() {
                // using default values
        }
        
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

                let partitionProperties: RegistryEntry = RegistryEntry.init(fromPath: daMediaPath)
                
                /* To do - Check disk is GPT */
                
                let ioPreferredBlockSize: Int? = partitionProperties.getIntValue(forProperty: "Preferred Block Size")
                let ioPartitionID: Int? = partitionProperties.getIntValue(forProperty: "Partition ID")
                let ioBase: Int? = partitionProperties.getIntValue(forProperty: "Base")
                let ioSize: Int? = partitionProperties.getIntValue(forProperty: "Size")
                let ioUUID: String? = partitionProperties.getStringValue(forProperty: "UUID")
                
                if (ioPreferredBlockSize == nil || ioPartitionID == nil || ioBase == nil || ioSize == nil || ioUUID == nil) {
                        Log.logExit(EX_UNAVAILABLE, "Failed to get registry values")
                }
                
                let blockSize: Int = ioPreferredBlockSize!
                partitionNumber = UInt32(ioPartitionID!)
                partitionStart = UInt64(ioBase! / blockSize)
                partitionSize = UInt64(ioSize! / blockSize)

                /*  EFI Signature from volume GUID string */
                
                let uuid: String = ioUUID!
                var part: [String] = uuid.components(separatedBy: "-")
                partitionSignature.append(part[0].hexToData(swap: true)!)
                partitionSignature.append(part[1].hexToData(swap: true)!)
                partitionSignature.append(part[2].hexToData(swap: true)!)
                partitionSignature.append(part[3].hexToData()!)
                partitionSignature.append(part[4].hexToData()!)
        }
}




struct FilePathMediaDevicePath {
        
        var data: Data {
                get {
                        var data = Data.init()
                        data.append(type)
                        data.append(subType)
                        data.append(length)
                        data.append(path)
                        return data
                }
        }
        let type = Data.init(bytes: [4])
        let subType = Data.init(bytes: [4])
        var path = Data.init()
        var length = Data.init()
        
        init(createUsingFilePath localPath: String, mountPoint: String) {
                
                /* Path */
                
                let c: Int = mountPoint.characters.count
                let i: String.Index = localPath.index(localPath.startIndex, offsetBy: c)
                var efiPath: String = "/" + localPath[i...]
                efiPath = efiPath.uppercased().replacingOccurrences(of: "/", with: "\\")
                if efiPath.containsOutlawedCharacters() {
                        Log.logExit(EX_DATAERR, "Forbidden character(s) found in path")
                }
                path = efiPath.efiStringData()
                
                /* Length */
                
                var lengthValue = UInt16(path.count + 4)
                length.append(UnsafeBufferPointer(start: &lengthValue, count: 1))
        }   
}




struct EndDevicePath {
        let data = Data.init(bytes: [127, 255, 4, 0])
}

