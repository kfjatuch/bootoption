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
        let optionalDataStringOption = StringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "optional STRING passed to the loader command line", precludes: "@")
        let ucs2EncodingOption = BoolOption(shortFlag: "u", helpMessage: "pass command line arguments as UCS-2 (default is ASCII)", precludes: "@")
        let optionalDataFilePathOption = StringOption(shortFlag: "@", longFlag: "optional-data", helpMessage: "append optional data from FILE", precludes: "au")
        commandLine.invocationHelpMessage = "create -l PATH -d LABEL [-a STRING [-u] | -@ FILE]"
        commandLine.setOptions(loaderPathOption, loaderDescriptionOption, optionalDataStringOption, ucs2EncodingOption, optionalDataFilePathOption)
        
        commandLine.parseOptions(strict: true)
        
        guard commandLine.parserStatus == .success else {
                
                commandLine.printErrorAndUsage()
                
                if commandLine.parserStatus == .noInput {
                        Debug.terminate(EX_OK)
                } else {
                        Debug.terminate(EX_USAGE)
                }
                
        }
        
        var optionalData: Any?
        
        /* Check root */
        
        if NSUserName() != "root" {
                Debug.log("Only root can set NVRAM variables", type: .error)
                Debug.fault("Permission denied")
        }
        
        var status = EX_OK
        
        /* Optional data */
        
        optionalData = OptionalData.selectSourceFrom(filePath: optionalDataFilePathOption.value, arguments: optionalDataStringOption.value)
        
        /* Set a new load option */
        
        if let loaderPath = loaderPathOption.value, let description = loaderDescriptionOption.value {
                let option = EfiLoadOption(createFromLoaderPath: loaderPath, descriptionString: description, optionalData: optionalData, ucs2OptionalData: ucs2EncodingOption.value)
                if Nvram.shared.setNewEfiLoadOption(data: option.data, addingToBootOrder: true) == nil {
                        print("Error setting boot option", to: &standardError)
                        status = EX_DATAERR
                }
        } else {
                status = EX_NOINPUT
        }
        
        Debug.terminate(status)
}
