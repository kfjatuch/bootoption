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
        let descriptionOption = StringOption(shortFlag: "L", longFlag: "label", required: 1, helpMessage: "display LABEL in firmware boot manager")
        let dataStringOption = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
        commandLine.invocationHelpMessage = "create -l PATH -L LABEL [-u STRING]"
        commandLine.setOptions(loaderOption, descriptionOption, dataStringOption)
        
        let optionParser = OptionParser(options: commandLine.options, rawArguments: commandLine.rawArguments, strict: true)
        switch optionParser.status {
        case .success:
                
                if commandLine.userName != "root" {
                        Log.logExit(EX_NOPERM, "Only root can set NVRAM variables.")
                }
                
                var status = EX_OK
                var noop = true
                
                /* Set a new load option */
                
                if loaderOption.wasSet && descriptionOption.wasSet {
                        noop = false
                        let option = EfiLoadOption(createFromLoaderPath: loaderOption.value!, description: descriptionOption.value!, optionalData: dataStringOption.value)
                        if nvram.createNewAndAddToBootOrder(withData: option.data) == nil {
                                print("Error setting boot option", to: &standardError)
                                status = EX_DATAERR
                        }
                }
                
                /* After all functions, exit some way */
                
                if noop {
                        commandLine.printUsage()
                        Log.logExit(EX_USAGE)
                }
                
                Log.logExit(status)
                
        default:
                commandLine.printUsage(withMessageForError: optionParser.status)
                Log.logExit(EX_USAGE)
        }
}
