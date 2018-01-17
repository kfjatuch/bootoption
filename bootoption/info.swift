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

func infoUsage() -> Never {
        print("Usage: bootoption info <Boot####>" , to: &standardError)
        Log.logExit(EX_USAGE)
}

func info() {
        
        /*
         Log.info("Setting up command line")
         let bootnumOption = StringOption(shortFlag: "b", longFlag: "bootnum", required: 1,  helpMessage: "hex")
         commandLine.invocationHelpMessage = "info -b ####"
         commandLine.setOptions(bootnumOption)
         
         let optionParser = OptionParser(options: commandLine.options, rawArguments: commandLine.rawArguments, strict: true)
         switch optionParser.status {
         case .success:
         default:
         commandLine.printUsage(withMessageForError: optionParser.status)
         Log.logExit(EX_USAGE)
         }
         */
        
        guard let string = commandLine.rawArguments.first else {
                infoUsage()
        }
        guard let bootnum = nvram.bootNumberFromBoot(string: string) else {
                infoUsage()
        }
        if let data: Data = nvram.getBootOption(bootnum) {
                let option = EfiLoadOption(fromBootNumber: bootnum, data: data, details: true)
                let name = nvram.bootStringFromBoot(number: bootnum)
                
                var properties: [(String, String)] = Array()
                properties.append(("Name", name))
                if let string: String = option.descriptionString {
                        properties.append(("Description", string))
                }
                properties.append(("Type", option.devicePathDescription))
                if let string: String = option.loaderPathString {
                        properties.append(("Loader path", string))
                }
                if let string: String = option.hardDrive?.partitionUuid {
                        properties.append(("Partition UUID", string))
                }
                if let string: String = option.optionalDataAsString, !string.isEmpty {
                        properties.append(("Arguments", string))
                } else if let string: String = option.optionalDataAsBytes {
                        let paddedString = string.replacingOccurrences(of: "\n", with: "\n      ")
                        properties.append(("Data", paddedString))
                }
                
                for property in properties {
                        print("\(property.0): \(property.1)")
                }
                
                
                Log.logExit(EX_OK)
        }
        
        
}
