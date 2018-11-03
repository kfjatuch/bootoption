/*
 * File: create.swift
 *
 * bootoption © vulgo 2018 - A command line utility for managing a
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
 *  Function for command: create
 */

func create() {
        
        Debug.log("Setting up command line", type: .info)
        let loaderPathOption = StringOption(shortFlag: "l", longFlag: "loader", required: 1,  helpMessage: "the PATH to an EFI loader executable")
        let loaderDescriptionOption = StringOption(shortFlag: "d", longFlag: "description", required: 1, helpMessage: "display LABEL in firmware boot manager")
        let optionalDataStringOption = StringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "optional STRING passed to the loader command line", invalidates: "@")
        let ucs2EncodingOption = BoolOption(shortFlag: "u", helpMessage: "pass command line arguments as UCS-2 (default is ASCII)", invalidates: "@")
        let optionalDataFilePathOption = FilePathOption(shortFlag: "@", longFlag: "optional-data", helpMessage: "append optional data from FILE", invalidates: "a", "u")
        let testOption = BoolOption(shortFlag: "t", longFlag: "test", helpMessage: "output to stdout instead of NVRAM")
        commandLine.invocationHelpMessage = "create -l PATH -d LABEL [-a STRING [-u] | -@ FILE]"
        commandLine.setOptions(loaderPathOption, loaderDescriptionOption, optionalDataStringOption, ucs2EncodingOption, optionalDataFilePathOption, testOption)
        
        commandLine.parseOptions(strict: true)
        
        var optionalData: Any?
       
        /* Optional data */
        
        optionalData = OptionalData.selectSourceFrom(data: optionalDataFilePathOption.data, arguments: optionalDataStringOption.value)
        
        /* Set a new load option */
        
        guard let loaderPath = loaderPathOption.value, let description = loaderDescriptionOption.value else {
                Debug.terminate(EX_NOINPUT)
        }
        
        let option = EfiLoadOption(createFromLoaderPath: loaderPath, descriptionString: description, optionalData: optionalData, ucs2OptionalData: ucs2EncodingOption.value)
        
        switch testOption.value {
                
        case true:
                /* This is a test, output to stdout instead of NVRAM */
                print(option.dataString)
                Debug.terminate(EX_OK)
                
        case false:
                /* Check root */
                if NSUserName() != "root" {
                        Debug.log("Only root can set NVRAM variables", type: .error)
                        Debug.fault("Permission denied")
                }
                guard Nvram.shared.setNewEfiLoadOption(data: option.data, addingToBootOrder: true) != nil else {
                        Debug.fault("Unknown NVRAM error setting load option")
                }
                Debug.terminate(EX_OK)                
        }
        
}
