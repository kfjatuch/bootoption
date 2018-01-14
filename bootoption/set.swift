/*
 * File: set.swift
 *
 * bootoption © vulgo 2017-2018 - A program to create / save an EFI boot
 * option - so that it might be added to the firmware menu later
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
        let loaderOption = StringOption(shortFlag: "l", longFlag: "loader", helpMessage: "the PATH to an EFI loader executable")
        let labelOption = StringOption(shortFlag: "L", longFlag: "label", helpMessage: "display LABEL in firmware boot manager")
        let unicodeOption = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
        let bootNextOption = StringOption(shortFlag: "n", longFlag: "bootnext", helpMessage: "set BootNext to #### (hex)")
        let timeoutOption = IntOption(shortFlag: "t", longFlag: "timeout", helpMessage: "set the boot menu timeout in SECONDS")
        commandLine.invocationHelpMessage = "set [-l PATH -L LABEL [-u STRING]] [-t SECONDS] [-n ####]"
        commandLine.setOptions(loaderOption, labelOption, unicodeOption, bootNextOption, timeoutOption)
        
        let optionParser = OptionParser(options: commandLine.options, rawArguments: commandLine.rawArguments, strict: true)
        switch optionParser.status {
        case .success:
                
                if commandLine.userName != "root" {
                        print("Only root can set NVRAM variables.", to: &standardError)
                        Log.logExit(EX_USAGE)
                }
                
                var status: Int32 = 0
                var noop = true
                
                /* Set a new load option */
                
                if loaderOption.wasSet && labelOption.wasSet {
                        noop = false
                        let data = efiLoadOption(loader: loaderOption.value!, label: labelOption.value!, unicode: unicodeOption.value)
                        if nvram.createNewAndAddToBootOrder(withData: data) == nil {
                                print("Error setting boot option")
                                status = 1
                        }
                }
                
                /* Set BootNext */
                
                if bootNextOption.wasSet {
                        noop = false
                        if !nvram.setBootNext(bootString: bootNextOption.value) {
                                print("Error setting BootNext")
                                status = 1
                        }
                }
                
                /* Set the timeout */
                
                if timeoutOption.wasSet {
                        noop = false
                        var timeoutResult = false
                        if let timeout: Int = timeoutOption.value {
                                if 1 ... 65534 ~= timeout {
                                        timeoutResult = nvram.setTimeout(seconds: timeout)
                                }
                        }
                        if !timeoutResult {
                                print("Error setting Timeout")
                                status = 1
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
