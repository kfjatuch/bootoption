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
        let bootnumOption = BootNumberOption(shortFlag: "n", longFlag: "name", helpMessage: "variable to manipulate, Boot####")
        let loaderDescriptionOption = StringOption(shortFlag: "d", longFlag: "description", helpMessage: "display LABEL in firmware boot manager")
        let optionalDataStringOption = OptionalStringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "optional STRING passed to the loader command line", invalidates: "@")
        let ucs2EncodingOption = BoolOption(shortFlag: "u", helpMessage: "pass command line arguments as UCS-2 (default is ASCII)", invalidates: "@")
        let optionalDataFilePathOption = InputFilePathOption(shortFlag: "@", longFlag: "optional-data", helpMessage: "append optional data from FILE", invalidates: "a", "u")
        let attributeActiveOption = BinaryOption(longFlag: "active", helpMessage: "set active attribute, 0 or 1")
        let attributeHiddenOption = BinaryOption(longFlag: "hidden", helpMessage: "set hidden attribute, 0 or 1")
        let bootNextOption = BootNumberOption(shortFlag: "x", longFlag: "bootnext", helpMessage: "set BootNext to Boot#### (hex)")
        let timeoutOption = TimeoutOption(shortFlag: "t", longFlag: "timeout", helpMessage: "set boot menu Timeout in SECONDS")
        let bootOrderOption = BootOrderArrayOption(shortFlag: "o", longFlag: "bootorder", helpMessage: "explicitly set the boot order")
        commandLine.invocationHelpMessage = "set -n #### [-d LABEL] [-a STRING [-u] | -@ FILE]\n\t-x #### | -t SECS | -o Boot#### [Boot####] [Boot####] [...]"
        commandLine.setOptions(bootnumOption, loaderDescriptionOption, optionalDataStringOption, ucs2EncodingOption, optionalDataFilePathOption, attributeActiveOption, attributeHiddenOption, bootNextOption, timeoutOption, bootOrderOption)
        
        commandLine.parseOptions(strict: true)
        
        var option: EfiLoadOption?
        let description: String = loaderDescriptionOption.value ?? ""
        var optionalData: Any?
        var updateOption = false
        var didSomething = false
        
        /*
         *  Check arguments are valid
         *
         *  Boot number
         */
       
        if bootnumOption.wasSet && (description.isEmpty && !optionalDataStringOption.wasSet && !optionalDataFilePathOption.wasSet && !attributeActiveOption.wasSet && !attributeHiddenOption.wasSet) {
                commandLine.parserStatus = .missingRequiredOptions
                print("set: option \(bootnumOption.shortDescription) specified without \(loaderDescriptionOption.shortDescription), \(optionalDataStringOption.shortDescription) or attribute options", to: &standardError)
                commandLine.printUsage()
                Debug.terminate(EX_USAGE)
        }
        
        if let bootNumber = bootnumOption.value {
                guard let data = Nvram.shared.bootOptionData(bootNumber) else {
                        commandLine.printErrorAndUsage(settingStatus: .invalidArgumentForOption, options: bootnumOption, arguments: bootnumOption.value!)
                        Debug.terminate(EX_USAGE)
                }
                
                option = EfiLoadOption(fromBootNumber: bootNumber, data: data, details: true)
                
                guard option != nil else {
                        Debug.fault("EFI load option should no longer be nil")
                }
        }
        
        /* Attribute / description / optional data options */
        
        if (attributeActiveOption.wasSet || attributeHiddenOption.wasSet || !description.isEmpty || optionalDataStringOption.wasSet || optionalDataFilePathOption.wasSet) && option == nil {
                commandLine.printErrorAndUsage(settingStatus: .missingRequiredOptions, options: bootnumOption)
                Debug.terminate(EX_USAGE)
        }
        
        /* Optional data */
        
        if let filePath = optionalDataFilePathOption.value, !optionalDataFilePathOption.fileExists {
                Debug.fault("optional data file not found: \(filePath)")
        }
        
        optionalData = OptionalData.selectSourceFrom(data: optionalDataFilePathOption.data, arguments: optionalDataStringOption.value)        
        
        /*
         *  Check root
         */
        
        if NSUserName() != "root" {
                Debug.log("Only root can set NVRAM variables", type: .error)
                Debug.fault("permission denied")
        }
        
        
        
        /*
         *  Operations
         *
         *  Set boot next
         */

        if let bootNextValue: BootNumber = bootNextOption.value {
                if !Nvram.shared.setBootNext(bootNumber: bootNextValue) {
                        print("Unknown NVRAM error setting BootNext", to: &standardError)
                }
                didSomething = true
        }
        
        /* Set timeout */
        
        if let timeoutValue: UInt16 = timeoutOption.value {
                if !Nvram.shared.setTimeout(timeoutValue) {
                        print("Unknown NVRAM error setting Timeout", to: &standardError)
                }
                didSomething = true
        }
        
        /* Set boot order */
        
        if let newBootOrder: [BootNumber] = bootOrderOption.value {
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
