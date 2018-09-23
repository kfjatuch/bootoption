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

/*
 *  Function for verb: set
 */

func set() {
        
        Log.info("Setting up command line")
        let bootnumOption = StringOption(shortFlag: "n", longFlag: "name", helpMessage: "the variable to manipulate, Boot####")
        let loaderDescriptionOption = StringOption(shortFlag: "d", longFlag: "description", helpMessage: "display LABEL in firmware boot manager")
        let loaderCommandLineOption = OptionalStringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "an optional STRING passed to the loader command line")
        let loaderActiveOption = BinaryOption(longFlag: "active", helpMessage: "set active attribute, 0 or 1")
        let loaderHiddenOption = BinaryOption(longFlag: "hidden", helpMessage: "set hidden attribute, 0 or 1")
        let bootNextOption = StringOption(shortFlag: "x", longFlag: "bootnext", helpMessage: "set BootNext, #### (hex)")
        let timeoutOption = IntOption(shortFlag: "t", longFlag: "timeout", helpMessage: "set boot menu Timeout in SECONDS")
        commandLine.invocationHelpMessage = "set -n #### [-d LABEL] [-a STRING] | -t SECONDS | -x ####"
        commandLine.setOptions(bootnumOption, loaderDescriptionOption, loaderCommandLineOption, loaderActiveOption, loaderHiddenOption, bootNextOption, timeoutOption)
        
        func setMain() {
                
                var option: EfiLoadOption?
                let bootNextString: String = bootNextOption.value ?? ""
                var bootNextValue: Int = -1
                let timeoutValue: Int = timeoutOption.value ?? -1
                let description: String = loaderDescriptionOption.value ?? ""
                var updateOption = false
                
                /*
                 *  Check arguments are valid
                 *
                 *  Boot next
                 */
                
                if !bootNextString.isEmpty {
                        if let validBootNumber: Int = nvram.bootNumberFromString(bootNextString) {
                                if let _: Data = nvram.getBootOption(validBootNumber) {
                                        bootNextValue = validBootNumber
                                } else {
                                        commandLine.printUsage(withMessageForError: ParserStatus.invalidValueForOption(bootNextOption, [bootNextString]))
                                        Log.logExit(EX_USAGE)
                                }
                        } else {
                                commandLine.printUsage(withMessageForError: ParserStatus.invalidValueForOption(bootNextOption, [bootNextString]))
                                Log.logExit(EX_USAGE)
                        }
                }
                
                /* Timeout */
                
                if timeoutOption.wasSet && !(1 ... 65534 ~= timeoutValue) {
                        commandLine.printUsage(withMessageForError: ParserStatus.invalidValueForOption(timeoutOption, [String(timeoutValue)]))
                        Log.logExit(EX_USAGE)
                }
                
                /*  Boot number */
                
                if bootnumOption.wasSet && (description.isEmpty && !loaderCommandLineOption.wasSet && !loaderActiveOption.wasSet && !loaderHiddenOption.wasSet) {
                        print("Option \(bootnumOption.shortDescription) specified without \(loaderDescriptionOption.shortDescription), \(loaderCommandLineOption.shortDescription) or attribute options", to: &standardError)
                        commandLine.printUsage()
                        Log.logExit(EX_USAGE)
                }
                
                if bootnumOption.wasSet {
                        guard let bootNumber = nvram.bootNumberFromString(bootnumOption.value!) else {
                                commandLine.printUsage(withMessageForError: ParserStatus.invalidValueForOption(bootnumOption, [bootnumOption.value ?? ""]))
                                Log.logExit(EX_USAGE)
                        }
                        guard let data = nvram.getBootOption(bootNumber) else {
                                commandLine.printUsage(withMessageForError: ParserStatus.invalidValueForOption(bootnumOption, [bootnumOption.value ?? ""]))
                                Log.logExit(EX_USAGE)
                        }
                        option = EfiLoadOption(fromBootNumber: bootNumber, data: data, details: true)
                        guard option != nil else {
                                Log.logExit(EX_SOFTWARE)
                        }
                }
                
                /* Attribute options */
                
                if (loaderActiveOption.wasSet || loaderHiddenOption.wasSet) && option == nil {
                        print("Missing required option: \(bootnumOption.shortDescription)", to: &standardError)
                        commandLine.printUsage()
                        Log.logExit(EX_USAGE)
                }
                
                /* Description */
                
                if (!description.isEmpty && option == nil) {
                        print("Missing required option: \(bootnumOption.shortDescription)", to: &standardError)
                        commandLine.printUsage()
                        Log.logExit(EX_USAGE)
                }
                
                /* Optional data string */
                
                if (loaderCommandLineOption.wasSet && option == nil) {
                        print("Missing required option: \(bootnumOption.shortDescription)", to: &standardError)
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
                
                if !description.isEmpty {
                        option?.descriptionString = description
                        updateOption = true  
                }
                
                /* Set optional data string */
                
                if let dataStringValue: String = loaderCommandLineOption.value {
                        if !dataStringValue.isEmpty {
                                option?.optionalDataStringView = dataStringValue
                                updateOption = true
                        } else {
                                option?.removeOptionalData()
                                updateOption = true
                        }
                } else {
                        if loaderCommandLineOption.wasSet {
                                option?.removeOptionalData()
                                updateOption = true
                        }
                }
                
                /* Set attributes */
                
                if loaderHiddenOption.value != nil {
                        option?.hidden = loaderHiddenOption.value!
                        updateOption = true
                }
                
                if loaderActiveOption.value != nil {
                        option?.active = loaderActiveOption.value!
                        updateOption = true
                }
                
                /* Update option */
                
                if updateOption && option != nil {
                        if !nvram.setOption(option: option!) {
                                print("Error updating option, check logs", to: &standardError)
                        }
                }
                
                Log.logExit(EX_OK)
                
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



