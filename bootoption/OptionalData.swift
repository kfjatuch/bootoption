/*
 * File: EndDevicePath.swift
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

struct OptionalData {
        
        var data: Data?
        
        var stringValue: String? {
                get {
                        guard let data = self.data else {
                                return nil
                        }
                        if data.isConvertibleToUTF8CString {
                                if let ascii = String(data: data, encoding: .ascii) {
                                        let trimmed = ascii.replacingOccurrences(of: "\r\n|\r|\n", with: " ", options: .regularExpression)
                                        Debug.log("'%@' decoded as ascii from data: %@", type: .info, argsList: trimmed, data)
                                        return trimmed
                                }
                        }
                        var mutable = data
                        if let ucs2 = mutable.removeEfiString() {
                                let trimmed = ucs2.replacingOccurrences(of: "\r\n|\r|\n", with: " ", options: .regularExpression)
                                Debug.log("'%@' decoded as UCS-2 from data: %@", type: .info, argsList: trimmed, data)
                                return trimmed
                        }
                        Debug.log("Did not decode optional data as string: %@", type: .info, argsList: data)
                        return nil
                }
        }
        
        func chomp(data: inout Data, _ output: inout String, _ asciiColumn: inout String) {
                let byte = data.remove8()
                output += String(format: "%02x", byte)
                asciiColumn += byte.ascii
        }
        
        var description: String? {
                if var buffer: Data = data, !buffer.isEmpty {
                        var output = ""
                        var asciiColumn = ""
                        var columnNumber: Int = 0
                        repeat {
                                columnNumber += 1
                                if buffer.count > 1 {
                                        chomp(data: &buffer, &output, &asciiColumn)
                                        chomp(data: &buffer, &output, &asciiColumn)
                                        output += " "
                                } else {
                                        chomp(data: &buffer, &output, &asciiColumn)
                                        output += "   "
                                }
                                if columnNumber % 8 == 0 {
                                        output += " "
                                        output += asciiColumn
                                        output += "\n"
                                        asciiColumn = ""
                                }
                        } while !buffer.isEmpty
                        for _ in 1...(8 - columnNumber % 8) {
                                output += "     "
                        }
                        output += " "
                        output += asciiColumn
                        return output
                }
                return nil
        }
        
        mutating func setAsciiCommandLine(_ string: String, clover: Bool = false) {
                if var asciiData: Data = string.asciiStringData(nullTerminated: false) {
                        if clover {
                                Debug.log("Optional data string for Clover: appending 2 null bytes", type: .default)
                                asciiData.append(Data(bytes: [0x00, 0x00]))
                                data = asciiData
                        } else {
                                data = asciiData
                        }
                        Debug.log("Ascii encoded optional data string: %@", type: .info, argsList: asciiData)
                } else {
                        Debug.fault("ascii encoding of optional data string failed")
                }
        }
        
        mutating func setUcs2CommandLine(_ string: String) {
                if let efiStringData: Data = string.efiStringData(nullTerminated: false) {
                        data = efiStringData
                        Debug.log("UCS-2 encoded optional data string: %@", type: .info, argsList: efiStringData)
                } else {
                        Debug.fault("UCS-2 encoding of optional data string failed")
                }
        }
        
        mutating func setOptionalData(string: String, clover: Bool = false, ucs: Bool = false) {
                if ucs {
                        setUcs2CommandLine(string)
                } else {
                        setAsciiCommandLine(string, clover: clover)
                }
        }
        
        static func selectSourceFrom(data: Data?, arguments: String?) -> Any? {
                Debug.log("Optional data select source...", type: .info)
                var optionalData: Any?
                
                if let data: Data = data {
                        
                        optionalData = data
                        
                } else if let arguments = arguments {
                        
                        /* Command line arguments specified with option -a --arguments */
                        
                        optionalData = arguments
                        
                }
                
                Debug.log("Returned: %@", type: .info, argsList: optionalData as Any)
                return optionalData
        }
}
