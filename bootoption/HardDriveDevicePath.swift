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
import IOKit.storage

struct HardDriveDevicePath {
        
        private let type = Data(bytes: [0x04])
        private let subType = Data(bytes: [0x01])
        private let length = Data(bytes: [0x2A, 0x00])
        private var partitionNumber: UInt32 = 0x00000000
        private var partitionStart: UInt64 = 0x0000000000000000
        private var partitionSize: UInt64 = 0x0000000000000000
        private var partitionSignature = Data(bytes: [0x00], count: 16)
        private var partitionFormat: UInt8 = 0x02 // GPT
        private var signatureType: UInt8 = 0x02 // GPT UUID
        
        var data: Data {
                /* Buffer HD device path */
                var buffer = Data()
                buffer.append(type)
                buffer.append(subType)
                buffer.append(length)
                buffer.append(partitionNumber.data)
                buffer.append(partitionStart.data)
                buffer.append(partitionSize.data)
                buffer.append(partitionSignature)
                buffer.append(partitionFormat)
                buffer.append(signatureType)
                return buffer
        }
        
        var partitionUuid: EfiUuid?
        var mountPoint = ""
        
        /* Init from device path data */
        
        init(devicePathData: Data) {
                Debug.log("Initializing Hard Drive DP from device path data...", type: .info)
                Debug.log("Data: %@", type: .info, argsList: devicePathData)
                
                var buffer: Data = devicePathData
                partitionNumber = buffer.remove32()
                Debug.log("Partition Number: %@", type: .info, argsList: partitionNumber)
                partitionStart = buffer.remove64()
                Debug.log("Partition Start: %@", type: .info, argsList: partitionStart)
                partitionSize = buffer.remove64()
                Debug.log("Partition Size: %@", type: .info, argsList: partitionSize)
                partitionSignature = buffer.removeData(bytes: 16)
                Debug.log("Partition Signature: %@", type: .info, argsList: partitionSignature)
                partitionFormat = buffer.remove8()
                Debug.log("Partition Format: %@", type: .info, argsList: partitionFormat)
                signatureType = buffer.remove8()
                Debug.log("Signature Type: %@", type: .info, argsList: signatureType)
                if !buffer.isEmpty {
                        Debug.fault("Buffer not empty after parsing hard drive device path")
                }
                if signatureType == 2 && partitionFormat == 2 {
                        partitionUuid = EfiUuid(fromData: partitionSignature)
                        Debug.log("UUID: %@", type: .info, argsList: String(partitionUuid?.uuidString ?? "nil"))
                }
                
                Debug.log("Hard Drive DP initialized from device path data", type: .info)
        }
        
        /* Init from local filesystem path to loader executable */
        
        init(fromFilePath path: String) {
                Debug.log("Initializing Hard Drive DP from loader filesystem path...", type: .info)
                Debug.log("Path: %@", type: .info, argsList: path)
                
                let fileManager: FileManager = FileManager()
                
                guard fileManager.fileExists(atPath: path) else {
                        Debug.fault("File not found at the specified path")
                }
                
                guard var mountedVolumeUrls: [URL] = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil) else {
                        Debug.fault("Failed to get URLs of all mounted volumes")
                }
                
                /* Compare mounted volume paths with our path */
                
                mountedVolumeUrls = mountedVolumeUrls.filter { $0.isFileURL }
                
                Debug.log("mountedVolumeUrls: %@", type: .info, argsList: mountedVolumeUrls)
                
                var volumePathsMatchingLoaderPath: [String] = []
                
                for volume in mountedVolumeUrls {
                        if path.contains(volume.path) {
                                volumePathsMatchingLoaderPath.append(volume.path)
                        }
                }
                
                Debug.log("volumePathsMatchingLoaderPath: %@", type: .info, argsList: volumePathsMatchingLoaderPath)
                
                if let longestMatch = volumePathsMatchingLoaderPath.max(by: {$1.count > $0.count}) {
                        mountPoint = longestMatch
                }
                
                guard mountPoint != "", mountPoint != "/" else {
                        Debug.fault("Failed to get a volume mount point from the path")
                }
                
                Debug.log("Chosen volume path: %@", type: .info, argsList: mountPoint)
                
                /* Get an IOMedia object for our partition */
                
                let ioMedia = RegistryEntry(ioMediaFromMountPoint: mountPoint as CFString)
                
                if (ioMedia.getIntValue(forProperty: kIOMediaGPTPartitionAttributesKey)) == nil {
                        Debug.fault("Only GPT disks are supported")
                }
                
                /* Set DP properties according to IOMedia object */
                
                guard let blockSize: Int = ioMedia.getIntValue(forProperty: kIOMediaPreferredBlockSizeKey) else {
                        Debug.fault("Failed to get IO Media Preferred Block Size")
                }
                
                Debug.log("Preferred Block Size: %@", type: .info, argsList: blockSize)
                
                if let partId: Int = ioMedia.getIntValue(forProperty: kIOMediaPartitionIDKey) {
                        Debug.log("Partition ID: %@", type: .info, argsList: partId)
                        partitionNumber = UInt32(partId)
                } else {
                        Debug.fault("Failed to get IOMedia Partition ID")
                }
                
                if let base: Int = ioMedia.getIntValue(forProperty: kIOMediaBaseKey) {
                        Debug.log("Base: %@", type: .info, argsList: partitionStart)
                        partitionStart = UInt64(base / blockSize)
                } else {
                        Debug.fault("Failed to get IOMedia Base")
                }
                
                if let size: Int = ioMedia.getIntValue(forProperty: kIOMediaSizeKey) {
                        Debug.log("Size: %@", type: .info, argsList: size)
                        partitionSize = UInt64(size / blockSize)
                } else {
                        Debug.fault("Failed to get IOMedia Size")
                }
                
                guard let ioUUIDString: String = ioMedia.getStringValue(forProperty: kIOMediaUUIDKey) else {
                        Debug.fault("Failed to get IOMedia UUID")
                }
                
                Debug.log("UUID: %@", type: .info, argsList: ioUUIDString)
                
                if let uuid = UUID(uuidString: ioUUIDString) {
                        partitionUuid = EfiUuid(uuid: uuid)
                        partitionSignature = partitionUuid!.data
                }
                
                Debug.log("Hard Drive DP initialized from loader filesystem path", type: .info)
        }
}
