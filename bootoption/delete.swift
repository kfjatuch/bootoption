/*
 * File: delete.swift
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

func delete() {
        
        Log.info("Setting up command line")
        let variableOption = StringOption(shortFlag: "b", longFlag: "bootnum", required: 1, helpMessage: "Boot#### variable to delete (hex)")
        let bootNextOption = BoolOption(shortFlag: "n", longFlag: "bootnext", required: 2, helpMessage: "delete the BootNext variable")
        let timeoutOption = BoolOption(shortFlag: "t", longFlag: "timeout", required: 3, helpMessage: "delete the Timeout variable")
        commandLine.invocationHelpMessage = "delete [-b ####] [-n] [-t]"
        commandLine.setOptions(variableOption, bootNextOption, timeoutOption)
        
        let optionParser = OptionParser(options: commandLine.options, rawArguments: commandLine.rawArguments, strict: true)
        switch optionParser.status {
        case .success:
                
                if commandLine.userName != "root" {
                        Log.logExit(EX_NOPERM, "Only root can delete NVRAM variables.")
                }
                
                var status = EX_OK
                var noop = true
                
                /* Delete a boot option */
                
                if variableOption.wasSet {
                        noop = false
                        let result: Int? = nvram.bootNumberFromBoot(string: variableOption.value ?? "")
                        
                        /* BootNumber */
                        guard let bootNumber: Int = result else {
                                print("Supplied Boot#### name is invalid", to: &standardError)
                                commandLine.printUsage()
                                Log.logExit(EX_DATAERR)
                        }
                        
                        let bootOrder: [UInt16]? = nvram.getBootOrderArray()
                        if let _: Int = bootOrder?.index(of: UInt16(bootNumber)) {
                                /* remove from boot order */
                                let newBootOrder = nvram.removeFromBootOrder(number: bootNumber)
                                if newBootOrder == nil {
                                        status = EX_DATAERR
                                        Log.error("Error removing Boot#### from BootOrder")
                                } else {
                                        /* delete the entry variable */
                                        nvram.deleteBootOption(Int(bootNumber))
                                }
                        } else {
                                /* variable is not in the boot order, just 'delete' it */
                                Log.info("Variable not found in boot order")
                                nvram.deleteBootOption(Int(bootNumber))
                        }
                }
                
                /* Delete boot next */
                
                if bootNextOption.wasSet {
                        noop = false
                        nvram.deleteBootNext()
                }
                
                /* Delete timeout */
                
                if timeoutOption.wasSet {
                        noop = false
                        nvram.deleteTimeout()
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

