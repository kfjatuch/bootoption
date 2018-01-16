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
                properties.append(("Description", option.descriptionString))
                properties.append(("Type", option.devicePathDescription))
                if !option.pathString.isEmpty {
                        properties.append(("Loader path", option.pathString))
                }
                if option.hardDriveDevicePath.partitionNumber > 0 {
                        properties.append(("Partition GUID", String(option.hardDriveDevicePath.guid)))
                }
                if !option.optionalDataString.isEmpty {
                        properties.append(("Optional data", String(option.optionalDataString)))
                }
                
                for property in properties {
                        print("\(property.0): \(property.1)")
                }
                
                
                Log.logExit(EX_OK)
        }
        
        
}
