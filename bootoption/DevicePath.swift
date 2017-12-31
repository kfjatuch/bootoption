/*
 * File: DevicePath.swift
 *
 * bootoption © vulgo 2017 - A program to create / save an EFI boot
 * option - so that it might be added to the firmware menu later
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
                        data.append(type)
                        data.append(subType)
                        data.append(length)
                        data.append(partitionNumber)
                        data.append(partitionStart)
                        data.append(partitionSize)
                        data.append(partitionSignature)
                        data.append(partitionFormat)
                        data.append(signatureType)
                        return data
                }
        }
        
        let mountPoint: String
        let type: Data = Data.init(bytes: [4])
        let subType: Data = Data.init(bytes: [1])
        let length: Data = Data.init(bytes: [42, 0])
        var partitionNumber = Data.init()
        var partitionStart = Data.init()
        var partitionSize = Data.init()
        var partitionSignature = Data.init()
        let partitionFormat = Data.init(bytes: [2])
        let signatureType = Data.init(bytes: [2])
        
        init(forFile path: String) {
                let fileManager: FileManager = FileManager()
                
                guard fileManager.fileExists(atPath: path) else {
                        fatalError("File not found")
                }
                
                guard let session:DASession = DASessionCreate(kCFAllocatorDefault) else {
                        fatalError("Failed to create DASession")
                }
                
                guard var volumes:[URL] = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil) else {
                        fatalError("Failed to get mounted volume URLs")
                }
                volumes = volumes.filter { $0.isFileURL }

                /*  Find a mounted volume path from our loader path */

                var longestMatch: Int = 0
                var mountedVolumePath: String?
                let prefix: String = "file://"

                for volume in volumes {
                        let unprefixedVolumeString: String = volume.absoluteString.replacingOccurrences(of: prefix, with: "")
                        let stringLength: Int = unprefixedVolumeString.characters.count
                        let start = unprefixedVolumeString.index(unprefixedVolumeString.startIndex, offsetBy: 0), end = unprefixedVolumeString.index(unprefixedVolumeString.startIndex, offsetBy: stringLength)
                        let test: String = String(path[start..<end])
                        
                        /*
                         *  Check if unprefixedVolumeString is the start of our loader path string,
                         *  and also the longest mounted volume path that is also a string match
                         */
                        
                        if test == unprefixedVolumeString && stringLength > longestMatch {
                                mountedVolumePath = unprefixedVolumeString
                                longestMatch = stringLength
                        }
                }
                
                mountPoint = mountedVolumePath!

                /*  Find DAMedia registry path */

                let cfMountPoint: CFString = mountPoint as CFString
                
                guard let url: CFURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, cfMountPoint, CFURLPathStyle(rawValue: 0)!, true) else {
                        fatalError("Failed to create CFURL for mount point")
                }
                guard let disk: DADisk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, url) else {
                        fatalError("Failed to create DADisk from volume URL")
                }
                guard let cfDescription: CFDictionary = DADiskCopyDescription(disk) else {
                        fatalError("Failed to get volume description CFDictionary")
                }
                guard let description: [String: Any] = cfDescription as? Dictionary else {
                        fatalError("Failed to get volume description as Dictionary")
                }
                guard let registryPath = description["DAMediaPath"] as? String else {
                        fatalError("Failed to get DAMediaPath as String")
                }

                /* Get the registry object for our partition */

                let partitionProperties = RegistryEntry.init(fromPath: registryPath)
                
                /* To do - Check disk is GPT */
                
                let ioPreferredBlockSize: Int? = partitionProperties.int(fromKey: "Preferred Block Size")
                let ioPartitionID: Int? = partitionProperties.int(fromKey: "Partition ID")
                let ioBase: Int? = partitionProperties.int(fromKey: "Base")
                let ioSize: Int? = partitionProperties.int(fromKey: "Size")
                let ioUUID: String? = partitionProperties.string(fromKey: "UUID")
                
                if (ioPreferredBlockSize == nil || ioPartitionID == nil || ioBase == nil || ioSize == nil || ioUUID == nil) {
                        fatalError("Failed to get registry values")
                }
                
                let blockSize = ioPreferredBlockSize!
                let uuid = ioUUID!
                var idValue = UInt32(ioPartitionID!)
                partitionNumber.append(UnsafeBufferPointer(start: &idValue, count: 1))
                var startValue = UInt64(ioBase! / blockSize)
                partitionStart.append(UnsafeBufferPointer(start: &startValue, count: 1))
                var sizeValue = UInt64(ioSize! / blockSize)
                partitionSize.append(UnsafeBufferPointer(start: &sizeValue, count: 1))

                /*  EFI Signature from volume GUID string */
                
                func subStr(string: String, from: Int, to: Int) -> String {
                        let start = string.index(string.startIndex, offsetBy: from)
                        let end = string.index(string.startIndex, offsetBy: to)
                        return String(string[start..<end])
                }
                
                func hexStringToData(string: String, swap: Bool = false) -> Data? {
                        var strings: [String] = []
                        let width: Int = 2
                        let max: Int = string.characters.count
                        if swap {
                                var start: Int = max - width, end: Int = max
                                while start >= 0 {
                                        strings.append(subStr(string: string, from: start, to: end))
                                        start -= width; end = start + width
                                }
                        } else {
                                var start: Int = 0, end: Int = start + width
                                while end <= max {
                                        strings.append(subStr(string: string, from: start, to: end))
                                        start += width; end = start + width
                                }
                        }
                        let bytes: [UInt8] = strings.map{UInt8(strtoul((String($0)), nil, 16))}
                        return bytes.withUnsafeBufferPointer{Data(buffer: $0)}
                }
                
                var part: [String] = uuid.components(separatedBy: "-")
                partitionSignature.append(hexStringToData(string: part[0], swap: true)!)
                partitionSignature.append(hexStringToData(string: part[1], swap: true)!)
                partitionSignature.append(hexStringToData(string: part[2], swap: true)!)
                partitionSignature.append(hexStringToData(string: part[3])!)
                partitionSignature.append(hexStringToData(string: part[4])!)
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
        
        let type: Data = Data.init(bytes: [4])
        let subType: Data = Data.init(bytes: [4])
        var path = Data.init()
        var length = Data.init()
        
        init(path localPath: String, mountPoint: String) {
                
                /* Path */
                
                let c = mountPoint.characters.count
                let i = localPath.index(localPath.startIndex, offsetBy: c)
                var efiPath = "/" + localPath[i...]
                efiPath = efiPath.uppercased().replacingOccurrences(of: "/", with: "\\")
                if efiPath.containsOutlawedCharacters() {
                        fatalError("Forbidden character(s) found in path")
                }
                var pathData = efiPath.data(using: String.Encoding.utf16)!
                pathData.removeFirst()
                pathData.removeFirst()
                pathData.append(contentsOf: [0, 0])
                path = pathData
                
                /* Length */
                
                var lengthValue = UInt16(pathData.count + 4)
                length.append(UnsafeBufferPointer(start: &lengthValue, count: 1))
        }   
}

struct EndDevicePath {
        let data = Data.init(bytes: [127, 255, 4, 0])
}

