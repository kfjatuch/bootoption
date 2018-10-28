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

/*
 *  Function for command: delete
 */

func delete() {
        
        Debug.log("Setting up command line", type: .info)
        let bootnumOption = StringOption(shortFlag: "n", longFlag: "name", required: 1, helpMessage: "variable to delete, Boot####")
        let bootNextOption = BoolOption(shortFlag: "x", longFlag: "bootnext", required: 2, helpMessage: "delete BootNext")
        let timeoutOption = BoolOption(shortFlag: "t", longFlag: "timeout", required: 3, helpMessage: "delete Timeout")
        commandLine.invocationHelpMessage = "delete [-n ####] [-x] [-t]"
        commandLine.setOptions(bootnumOption, bootNextOption, timeoutOption)
        
        func deleteMain() {
                
                /* Check root */
                
                if NSUserName() != "root" {
                        Debug.log("Only root can delete NVRAM variables", type: .error)
                        Debug.fault("Permission denied")
                }
                
                var status = EX_OK
                var didSomething = false
                
                /* Delete a boot option */
                
                if bootnumOption.wasSet {
                        didSomething = true
                        
                        /* Parse boot number */
                        guard let bootNumber: BootNumber = bootNumberFromString(bootnumOption.value ?? "") else {
                                commandLine.printUsage()
                                Debug.terminate(EX_USAGE)
                        }
                        
                        /* Delete from boot order if needed */
                        
                        let inBootOrder = Nvram.shared.bootOrderArray.contains(bootNumber)
                        
                        if inBootOrder {
                                Debug.log("Variable requested for deletion found in boot order", type: .info)
                                var result = false
                                /* remove from boot order */
                                if let newBootOrder = newBootOrderArray(removing: bootNumber) {
                                        result = Nvram.shared.setBootOrder(data: newBootOrderData(fromArray: newBootOrder))
                                }
                                if !result {
                                        status = EX_DATAERR
                                        Debug.log("Error removing from boot order", type: .error)
                                }
                        }
                        
                        /* Delete variable */
                        
                        Debug.log("Deleting variable", type: .info)
                        Nvram.shared.deleteBootOption(bootNumber)
                }
                
                /* Delete boot next */
                
                if bootNextOption.wasSet {
                        didSomething = true
                        Nvram.shared.deleteBootNext()
                }
                
                /* Delete timeout */
                
                if timeoutOption.wasSet {
                        didSomething = true
                        Nvram.shared.deleteTimeout()
                }
                
                /* After all functions, exit some way */
                
                if !didSomething {
                        commandLine.printUsage()
                        Debug.terminate(EX_USAGE)
                }
                
                Debug.terminate(status)
        }
        
        /*
         *  Parse command line
         */
        
        commandLine.parseOptions(strict: true)
        switch commandLine.parserStatus {
        case .success:
                deleteMain()
        default:
                commandLine.printErrorAndUsage()
                Debug.terminate(EX_USAGE)
                
        }
}

