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
        
        let type = Data.init(bytes: [4])
        let subType = Data.init(bytes: [4])
        var length = Data.init()
        var devicePath = Data.init()
        var data: Data {
                get {
                        var buffer = Data.init()
                        buffer.append(type)
                        buffer.append(subType)
                        buffer.append(length)
                        buffer.append(devicePath)
                        return buffer
                }
        }
        
        /* Properties */
        
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
                        if let string: String = newValue {
                                if string.containsOutlawedCharacters() {
                                        Log.logExit(EX_DATAERR, "Forbidden character(s) found in path")
                                }
                                if let data = string.efiStringData() {
                                        devicePath = data
                                }
                        }
                }
        }
        
        /* Init */
        
        init() {
                // Default values
        }
        
        /* Init from local filesystem path to loader + mount point */
        
        init(createUsingFilePath localPath: String, mountPoint: String) {
                
                /* Path */
                
                let c: Int = mountPoint.characters.count
                let i: String.Index = localPath.index(localPath.startIndex, offsetBy: c)
                let efiPath: String = "/" + localPath[i...]
                path = efiPath.uppercased().replacingOccurrences(of: "/", with: "\\")
                
                /* Device path length */
                
                var lengthValue = UInt16(devicePath.count + 4)
                length.append(UnsafeBufferPointer(start: &lengthValue, count: 1))
        }
}
