/*
 * File: set.swift
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

func set() {
        
        Log.info("Setting up command line")
        let bootnumOption = StringOption(shortFlag: "b", longFlag: "bootnum", required: 1,  helpMessage: "Boot#### number to modify (hex)")
        let labelOption = StringOption(shortFlag: "L", longFlag: "label", helpMessage: "display LABEL in firmware boot manager")
        let unicodeOption = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
        let bootNextOption = StringOption(shortFlag: "n", longFlag: "bootnext", required: 2, helpMessage: "set BootNext to #### (hex)")
        let timeoutOption = IntOption(shortFlag: "t", longFlag: "timeout", required: 3, helpMessage: "set the boot menu timeout in SECONDS")
        commandLine.invocationHelpMessage = "set -b #### [-L LABEL] [-u STRING] | -t SECONDS | -n ####"
        commandLine.setOptions(bootnumOption, labelOption, unicodeOption, bootNextOption, timeoutOption)
        
        func setMain() {
                
                var option: EfiLoadOption?
                let bootNextString: String = bootNextOption.value ?? ""
                var bootNextValue: Int = -1
                let timeoutValue: Int = timeoutOption.value ?? -1
                let labelValue: String = labelOption.value ?? ""
                let unicodeValue: String = unicodeOption.value ?? ""
                var updateOption = false
                
                /*
                 *  Check arguments are valid
                 *
                 *  Boot next
                 */
                
                if !bootNextString.isEmpty {
                        if let validBootNumber: Int = nvram.bootNumberFromBoot(string: bootNextString) {
                                if let _: Data = nvram.getBootOption(validBootNumber) {
                                        bootNextValue = validBootNumber
                                } else {
                                        commandLine.printUsage(withMessageForError: CommandLine.ParserStatus.invalidValueForOption(bootNextOption, [bootNextString]))
                                        Log.logExit(EX_USAGE)
                                }
                        } else {
                                commandLine.printUsage(withMessageForError: CommandLine.ParserStatus.invalidValueForOption(bootNextOption, [bootNextString]))
                                Log.logExit(EX_USAGE)
                        }
                }
                
                /* Timeout */
                if timeoutOption.wasSet && !(1 ... 65534 ~= timeoutValue) {
                        commandLine.printUsage(withMessageForError: CommandLine.ParserStatus.invalidValueForOption(timeoutOption, [String(timeoutValue)]))
                        Log.logExit(EX_USAGE)
                }
                
                /*  Boot number */
                if bootnumOption.wasSet && (labelValue.isEmpty && unicodeValue.isEmpty) {
                        print("Option \(bootnumOption.shortDescription) specified without \(labelOption.shortDescription) or \(unicodeOption.shortDescription)", to: &standardError)
                        commandLine.printUsage()
                        Log.logExit(EX_USAGE)
                }
                if bootnumOption.wasSet {
                        guard let bootNumber = nvram.bootNumberFromBoot(string: bootnumOption.value!) else {
                                commandLine.printUsage(withMessageForError: CommandLine.ParserStatus.invalidValueForOption(bootnumOption, [bootnumOption.value ?? ""]))
                                Log.logExit(EX_USAGE)
                        }
                        guard let data = nvram.getBootOption(bootNumber) else {
                                commandLine.printUsage(withMessageForError: CommandLine.ParserStatus.invalidValueForOption(bootnumOption, [bootnumOption.value ?? ""]))
                                Log.logExit(EX_USAGE)
                        }
                        option = EfiLoadOption(fromBootNumber: bootNumber, data: data, details: true)
                        guard option != nil else {
                                Log.logExit(EX_SOFTWARE)
                        }
                }
                
                /* Label */
                if (!labelValue.isEmpty && option == nil) {
                        print("Option \(labelOption.shortDescription) requires \(bootnumOption.shortDescription)", to: &standardError)
                        commandLine.printUsage()
                        Log.logExit(EX_USAGE)
                }
                
                /* Optional data */
                if (!unicodeValue.isEmpty && option == nil) {
                        print("Option \(unicodeOption.shortDescription) requires \(bootnumOption.shortDescription)", to: &standardError)
                        commandLine.printUsage()
                        Log.logExit(EX_USAGE)
                }
                
                
                
                /*
                 *  Check root
                 */
                
                if commandLine.userName != "root" {
                        Log.logExit(EX_NOPERM, "Only root can set NVRAM variables.")
                }
                
                
                
                /*
                 *  Operations
                 *
                 *  Set boot next
                 */

                if bootNextValue != -1 {
                        if !nvram.setBootNext(number: bootNextValue) {
                                print("Error setting BootNext, check logs", to: &standardError)
                        }
                }
                
                /* Set timeout */
                
                if timeoutValue != -1 {
                        if !nvram.setTimeout(seconds: timeoutValue) {
                                print("Error setting Timeout, check logs", to: &standardError)
                        }
                }
                
                /* Set description */
                
                if !labelValue.isEmpty {
                        option?.descriptionString = labelValue
                        updateOption = true
                        
                }
                
                /* Set optional data to string */
                
                if !unicodeValue.isEmpty {
                        option?.optionalDataString = unicodeValue
                        updateOption = true
                        
                }
                
                /* Update option */
                
                if updateOption && option != nil {
                        if !nvram.setOption(option: option!) {
                                print("Error updating option, check logs", to: &standardError)
                        }
                }
                
                
        }
        
        /*
         *  Parse command line
         */
        
        let optionParser = OptionParser(options: commandLine.options, rawArguments: commandLine.rawArguments, strict: true)
        switch optionParser.status {
        case .success:
                setMain()
                
        default:
                commandLine.printUsage(withMessageForError: optionParser.status)
                Log.logExit(EX_USAGE)
        }
}



