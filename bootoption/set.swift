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
        let optionalDataStringOption = OptionalStringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "optional STRING passed to the loader command line", precludes: "@")
        let ucs2EncodingOption = BoolOption(shortFlag: "u", helpMessage: "pass command line arguments as UCS-2 (default is ASCII)", precludes: "@")
        let optionalDataFilePathOption = StringOption(shortFlag: "@", longFlag: "optional-data", helpMessage: "append optional data from FILE", precludes: "au")
        let attributeActiveOption = BinaryOption(longFlag: "active", helpMessage: "set active attribute, 0 or 1")
        let attributeHiddenOption = BinaryOption(longFlag: "hidden", helpMessage: "set hidden attribute, 0 or 1")
        let bootNextOption = StringOption(shortFlag: "x", longFlag: "bootnext", helpMessage: "set BootNext to Boot#### (hex)")
        let timeoutOption = IntOption(shortFlag: "t", longFlag: "timeout", helpMessage: "set boot menu Timeout in SECONDS")
        let bootOrderOption = MultiStringOption(shortFlag: "o", longFlag: "bootorder", helpMessage: "explicitly set the boot order")
        commandLine.invocationHelpMessage = "set -n #### [-d LABEL] [-a STRING [-u] | -@ FILE]\n\t-x #### | -t SECS | -o Boot#### [Boot####] [Boot####] [...]"
        commandLine.setOptions(bootnumOption, loaderDescriptionOption, optionalDataStringOption, ucs2EncodingOption, optionalDataFilePathOption, attributeActiveOption, attributeHiddenOption, bootNextOption, timeoutOption, bootOrderOption)
        
        commandLine.parseOptions(strict: true)
        
        guard commandLine.parserStatus == .success else {
                
                commandLine.printErrorAndUsage()
                
                if commandLine.parserStatus == .noInput {
                        Debug.terminate(EX_OK)
                } else {
                        Debug.terminate(EX_USAGE)
                }
                
        }
                
        var option: EfiLoadOption?
        var bootNextValue: BootNumber?
        var timeoutValue: Int?
        var newBootOrder: [BootNumber]?
        let description: String = loaderDescriptionOption.value ?? ""
        var optionalData: Any?
        var updateOption = false
        var didSomething = false
        
        /*
         *  Check arguments are valid
         *
         *  Boot next
         */
        
        if let bootNext = bootNextOption.value {
                guard let validBootNumber: BootNumber = bootNumberFromString(bootNext), let _: Data = Nvram.shared.bootOptionData(validBootNumber) else {
                        Debug.log("Invalid argument for option", type: .error)
                        commandLine.printErrorAndUsage(settingStatus: .invalidArgumentForOption, option: bootNextOption, argument: bootNextOption.value!)
                        Debug.terminate(EX_USAGE)
                }
                bootNextValue = validBootNumber
        }
        
        /* Timeout */
        
        if let timeout = timeoutOption.value {
                switch timeout {
                case 1...65533:
                        timeoutValue = timeout
                default:
                        Debug.log("Invalid argument for option", type: .error)
                        commandLine.printErrorAndUsage(settingStatus: .invalidArgumentForOption, option: timeoutOption, argument: String(timeout))
                        Debug.terminate(EX_USAGE)
                }
        }
        
        /* Boot order */
        
        if let arguments: [String] = bootOrderOption.value {
                
                var order: [BootNumber] = []
                
                for arg in arguments {
                        
                        guard let bootNum = bootNumberFromString(arg), let _ = Nvram.shared.bootOptionData(bootNum) else {
                                Debug.log("Invalid argument", type: .error)
                                print("set: invalid argument '\(arg)' for option '-o, --bootorder'", to: &standardError)
                                commandLine.printUsage()
                                Debug.terminate(EX_USAGE)
                        }
                        
                        if !order.contains(bootNum) {
                                order.append(bootNum)
                        } else {
                                Debug.log("Invalid argument", type: .error)
                                print("set: '\(bootNum.variableName)' was specified more than once (-o, --bootorder)", to: &standardError)
                                commandLine.printUsage()
                                Debug.terminate(EX_USAGE)
                        }
                }
                
                if !order.isEmpty {
                        newBootOrder = order
                }
        }
        
        /*  Boot number */
        
        if bootnumOption.wasSet && (description.isEmpty && !optionalDataStringOption.wasSet && !optionalDataFilePathOption.wasSet && !attributeActiveOption.wasSet && !attributeHiddenOption.wasSet) {
                Debug.log("Missing required option(s)", type: .error)
                print("set: option \(bootnumOption.shortDescription) specified without \(loaderDescriptionOption.shortDescription), \(optionalDataStringOption.shortDescription) or attribute options", to: &standardError)
                commandLine.printUsage()
                Debug.terminate(EX_USAGE)
        }
        
        if bootnumOption.wasSet {
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
        
        if (attributeActiveOption.wasSet || attributeHiddenOption.wasSet || !description.isEmpty || optionalDataStringOption.wasSet || optionalDataFilePathOption.wasSet) && option == nil {
                Debug.log("Missing required option(s)", type: .error)
                commandLine.printErrorAndUsage(settingStatus: .missingRequiredOptions, option: bootnumOption)
                Debug.terminate(EX_USAGE)
        }
        
        /* Optional data */
        
        optionalData = OptionalData.selectSourceFrom(filePath: optionalDataFilePathOption.value, arguments: optionalDataStringOption.value)        
        
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
        
        /* Set boot order */
        
        if let newBootOrder = newBootOrder {
                Nvram.shared.setBootOrder(array: newBootOrder)
                didSomething = true
        }
        
        /* Set description */
        
        if !description.isEmpty {
                option?.descriptionString = description
                updateOption = true
        }
        
        /* Set optional data to string, file contents or remove */
        
        var removeOptionalData = false
        
        if let string = optionalDataStringOption.value {
                if !string.isEmpty {
                        let isClover: Bool = option?.isClover ?? false
                        option?.optionalData.setOptionalData(string: string, clover: isClover, ucs: ucs2EncodingOption.value)
                        updateOption = true
                } else {
                        /* -a --arguments=empty string, remove any optional data */
                        removeOptionalData = true
                }
        } else if let data = optionalData as? Data {
                /* set optional data from file */
                Debug.log("Setting optional data: %@", type: .info, argsList: data.debugString)
                option?.optionalData.data = data
                updateOption = true
        } else if optionalDataStringOption.wasSet {
                /* -a --arguments without argument, remove any optional data */
                removeOptionalData = true
        }
        
        if removeOptionalData == true, option?.optionalData.data != nil {
                Debug.log("Removing optional data", type: .info)
                option?.removeOptionalData()
                updateOption = true
        }
        
        /* Set attributes */
        
        if attributeHiddenOption.value != nil {
                option?.hidden = attributeHiddenOption.value!
                updateOption = true
        }
        
        if attributeActiveOption.value != nil {
                option?.active = attributeActiveOption.value!
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
