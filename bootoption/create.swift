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

func create() {
        
        Log.info("Setting up command line")
        let loaderOption = StringOption(shortFlag: "l", longFlag: "loader", required: 1,  helpMessage: "the PATH to an EFI loader executable")
        let descriptionOption = StringOption(shortFlag: "d", longFlag: "description", required: 1, helpMessage: "display LABEL in firmware boot manager")
        let dataStringOption = StringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "an optional STRING passed to the loader command line")
        commandLine.invocationHelpMessage = "create -l PATH -d LABEL [-a STRING]"
        commandLine.setOptions(loaderOption, descriptionOption, dataStringOption)
        
        func createMain() {
                
                let loaderPath = loaderOption.value ?? ""
                let description = descriptionOption.value ?? ""
                
                /* Check root */
                
                if commandLine.userName != "root" {
                        Log.logExit(EX_NOPERM, "Only root can set NVRAM variables.")
                }
                
                var status = EX_OK
                
                /* Set a new load option */
                
                if !loaderPath.isEmpty && !description.isEmpty {
                        let option = EfiLoadOption(createFromLoaderPath: loaderPath, descriptionString: description, optionalDataString: dataStringOption.value)
                        if nvram.createNewAndAddToBootOrder(withData: option.data) == nil {
                                print("Error setting boot option", to: &standardError)
                                status = EX_DATAERR
                        }
                } else {
                        status = EX_NOINPUT
                }
                
                Log.logExit(status)
        }
        
        /*
         *  Parse command line
         */
        
        let optionParser = OptionParser(options: commandLine.options, rawArguments: commandLine.rawArguments, strict: true)
        
        switch optionParser.status {
        case .success:
                createMain()     
        default:
                commandLine.printUsage(withMessageForError: optionParser.status)
                Log.logExit(EX_USAGE)
        }
}
