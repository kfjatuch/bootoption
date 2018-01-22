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
        
        var data: Data {
                get {
                        var data = Data.init()
                        data.append(type)
                        data.append(subType)
                        data.append(length)
                        data.append(devicePathData)
                        return data
                }
        }
        let type = Data.init(bytes: [4])
        let subType = Data.init(bytes: [4])
        var length = Data.init()
        var devicePathData = Data.init()
        
        var pathString: String? {
                get {
                        var data = devicePathData
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
                                        devicePathData = data
                                }
                        }
                }
        }
        
        init() {
                // using default values
        }
        
        init(createUsingFilePath localPath: String, mountPoint: String) {
                
                /* Path */
                
                let c: Int = mountPoint.characters.count
                let i: String.Index = localPath.index(localPath.startIndex, offsetBy: c)
                let efiPath: String = "/" + localPath[i...]
                pathString = efiPath.uppercased().replacingOccurrences(of: "/", with: "\\")
                
                /* Device path length */
                
                var lengthValue = UInt16(devicePathData.count + 4)
                length.append(UnsafeBufferPointer(start: &lengthValue, count: 1))
        }
}
