/*
 * File: info.swift
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

func info() {
        
        var required: BootNumber?
        for argument in commandLine.rawArguments {
                if let number = bootNumberFromString(argument) {
                        required = number
                        break
                }
        }
        
        guard let bootNumber = required else {
                print("usage: bootoption info <Boot####>", to: &standardError)
                Debug.terminate(1)
        }
        
        if let data: Data = Nvram.shared.bootOptionData(bootNumber) {
                let option = EfiLoadOption(fromBootNumber: bootNumber, data: data, details: true)
                let name = bootNumber.variableName
                
                var properties: [(String, String)] = Array()
                
                properties.append(("Name", name))
                if let string = option.descriptionString {
                        properties.append(("Description", string))
                }
                
                var attributesString = ""
                if !option.active {
                        attributesString += "Disabled"
                }
                if option.hidden {
                        if !attributesString.isEmpty {
                                attributesString += ", "
                        }
                        attributesString += "Hidden"
                }
                if !attributesString.isEmpty {
                        properties.append(("Attributes", attributesString))
                }
                
                properties.append(("Device path", option.devicePathDescription))
                if let string = option.hardDriveDevicePath?.partitionUuid?.uuidString {
                        properties.append(("Partition UUID", string))
                }
                
                if let string = option.filePathDevicePath?.path {
                        properties.append(("Loader path", string))
                }
                
                if let string = option.optionalData.stringValue, !string.isEmpty {
                        properties.append(("Arguments", string))
                } else if let string = option.optionalData.description {
                        /* Insert spaces to align subsequent lines with first line content */
                        let paddedString = string.replacingOccurrences(of: "\n", with: "\n      ")
                        properties.append(("Data", paddedString))
                }
                
                for property in properties {
                        print("\(property.0): \(property.1)")
                }
                
                Debug.terminate(EX_OK)
        }
}
