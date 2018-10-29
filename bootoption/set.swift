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
 *  Function for command: set
 */

func set() {
        
        Debug.log("Setting up command line", type: .info)
        let bootnumOption = StringOption(shortFlag: "n", longFlag: "name", helpMessage: "variable to manipulate, Boot####")
        let loaderDescriptionOption = StringOption(shortFlag: "d", longFlag: "description", helpMessage: "display LABEL in firmware boot manager")
        let loaderCommandLineOption = OptionalStringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "an optional STRING passed to the loader command line")
        let ucs2EncodingOption = BoolOption(shortFlag: "u", helpMessage: "pass command line arguments as UCS-2 (default is ASCII)")
        let loaderActiveOption = BinaryOption(longFlag: "active", helpMessage: "set active attribute, 0 or 1")
        let loaderHiddenOption = BinaryOption(longFlag: "hidden", helpMessage: "set hidden attribute, 0 or 1")
        let bootNextOption = StringOption(shortFlag: "x", longFlag: "bootnext", helpMessage: "set BootNext to Boot#### (hex)")
        let timeoutOption = IntOption(shortFlag: "t", longFlag: "timeout", helpMessage: "set boot menu Timeout in SECONDS")
        commandLine.invocationHelpMessage = "set -n #### [-d LABEL] [-a STRING] [-u] | -x #### | -t SECS"
        commandLine.setOptions(bootnumOption, loaderDescriptionOption, loaderCommandLineOption, ucs2EncodingOption, loaderActiveOption, loaderHiddenOption, bootNextOption, timeoutOption)
        
        func setMain() {
                
                var option: EfiLoadOption?
                let bootNextString: String = bootNextOption.value ?? ""
                var bootNextValue: BootNumber?
                let timeoutValue: Int? = timeoutOption.value ?? nil
                let description: String = loaderDescriptionOption.value ?? ""
                var updateOption = false
                var didSomething = false
                
                /*
                 *  Check arguments are valid
                 *
                 *  Boot next
                 */
                
                if !bootNextString.isEmpty {
                        
                        guard let validBootNumber: BootNumber = bootNumberFromString(bootNextString), let _: Data = Nvram.shared.bootOptionData(validBootNumber) else {
                                Debug.log("Invalid argument for option", type: .error)
                                commandLine.printErrorAndUsage(settingStatus: .invalidArgumentForOption, option: bootNextOption, argument: bootNextOption.value!)
                                Debug.terminate(EX_USAGE)
                        }
                        
                        bootNextValue = validBootNumber
                }
                
                /* Timeout */
                
                if let timeoutValue = timeoutValue, !(1 ... 65534 ~= timeoutValue) {
                        Debug.log("Invalid argument for option", type: .error)
                        commandLine.printErrorAndUsage(settingStatus: .invalidArgumentForOption, option: timeoutOption, argument: String(timeoutValue))
                        Debug.terminate(EX_USAGE)
                }
                
                /*  Boot number */
                
                if bootnumOption.wasSet && (description.isEmpty && !loaderCommandLineOption.wasSet && !loaderActiveOption.wasSet && !loaderHiddenOption.wasSet) {
                        Debug.log("Missing required option(s)", type: .error)
                        print("set: option \(bootnumOption.shortDescription) specified without \(loaderDescriptionOption.shortDescription), \(loaderCommandLineOption.shortDescription) or attribute options", to: &standardError)
                        commandLine.printUsage()
                        Debug.terminate(EX_USAGE)
                }
                
                if bootnumOption.wasSet {
                        Debug.log("Invalid argument for option", type: .error)
                        guard let bootNumber = bootNumberFromString(bootnumOption.value!), let data = Nvram.shared.bootOptionData(bootNumber) else {
                                commandLine.printErrorAndUsage(settingStatus: .invalidArgumentForOption, option: bootnumOption, argument: bootnumOption.value!)
                                Debug.terminate(EX_USAGE)
                        }
                        
                        option = EfiLoadOption(fromBootNumber: bootNumber, data: data, details: true)
                        
                        guard option != nil else {
                                Debug.fault("EFI load option should no longer be nil")
                        }
                }
                
                /* Attribute / description / optional data options */
                
                if (loaderActiveOption.wasSet || loaderHiddenOption.wasSet || !description.isEmpty || loaderCommandLineOption.wasSet) && option == nil {
                        Debug.log("Missing required option(s)", type: .error)
                        commandLine.printErrorAndUsage(settingStatus: .missingRequiredOptions, option: bootnumOption)
                        Debug.terminate(EX_USAGE)
                }
              
                
                
                /*
                 *  Check root
                 */
                
                if NSUserName() != "root" {
                        Debug.log("Only root can set NVRAM variables", type: .error)
                        Debug.fault("Permission denied")
                }
                
                
                
                /*
                 *  Operations
                 *
                 *  Set boot next
                 */

                if let bootNextValue = bootNextValue {
                        if !Nvram.shared.setBootNext(bootNumber: bootNextValue) {
                                print("Unknown NVRAM error setting BootNext", to: &standardError)
                        }
                        didSomething = true
                }
                
                /* Set timeout */
                
                if let timeoutValue = timeoutValue {
                        if !Nvram.shared.setTimeout(seconds: timeoutValue) {
                                print("Unknown NVRAM error setting Timeout", to: &standardError)
                        }
                        didSomething = true
                }
                
                /* Set description */
                
                if !description.isEmpty {
                        option?.descriptionString = description
                        updateOption = true
                }
                
                /* Set optional data string */
                
                if let commandLineString: String = loaderCommandLineOption.value {
                        if !commandLineString.isEmpty {
                                if ucs2EncodingOption.value {
                                        option?.optionalData.setUcs2CommandLine(commandLineString)
                                } else {
                                        let isClover: Bool = option?.isClover ?? false
                                        option?.optionalData.setAsciiCommandLine(commandLineString, clover: isClover)
                                }
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
                        if !Nvram.shared.setEfiLoadOption(option: option!) {
                                print("Unknown NVRAM error updating option", to: &standardError)
                        }
                        didSomething = true
                }
                
                if didSomething {
                        Debug.terminate(EX_OK)
                } else {
                        commandLine.printUsage()
                        Debug.terminate(EX_USAGE)
                }
                
        }
        
        /*
         *  Parse command line
         */
        
        commandLine.parseOptions(strict: true)
        switch commandLine.parserStatus {
        case .success:
                setMain()    
        default:
                commandLine.printErrorAndUsage()
                Debug.terminate(EX_USAGE)
        }
}



