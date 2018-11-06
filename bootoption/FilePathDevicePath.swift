/*
 * File: FilePathDevicePath.swift
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

struct FilePathDevicePath {
        
        /* Data */
        
        private let type = Data(bytes: [0x04])
        private let subType = Data(bytes: [0x04])
        private var length = Data()
        private var devicePath = Data()
        
        /* Properties */
        
        var data: Data {
                /* Buffer FP device path */
                var buffer = Data()
                buffer.append(type)
                buffer.append(subType)
                buffer.append(length)
                buffer.append(devicePath)
                return buffer
        }
        
        var path: String? {                
                get {
                        var data = devicePath
                        if !data.isEmpty {
                                return data.removeEfiString()
                        } else {
                                return nil
                        }
                }
                
                set {
                        if var string: String = newValue {
                                string = string.replacingOccurrences(of: "\\\\", with: "\\")
                                if string.containsOutlawedCharacters() {
                                        Debug.fault("forbidden character(s) found in path")
                                }
                                if let data = string.efiStringData() {
                                        devicePath = data
                                }
                        }
                }
        }
        
        /* Methods */
        
        mutating func setDevicePath(data: Data) {
                devicePath = data
        }
        
        /* Init */
        
        init() {
                // Default values
        }
        
        /* Init from local filesystem path to loader + mount point */
        
        init(createUsingFilePath localPath: String, mountPoint: String) {
                
                /* Path */

                let start: String.Index = localPath.index(localPath.startIndex, offsetBy: mountPoint.count)
                let loaderPath: String = "/" + localPath[start...]
                path = loaderPath.uppercased().replacingOccurrences(of: "/", with: "\\")
                
                /* Device path length */
                
                let lengthValue = UInt16(devicePath.count + 4)
                length.append(lengthValue.data)
        }
}
