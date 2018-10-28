/*
 * File: order.swift
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
 *  Function for command: order
 */

func order() {
        
        /* Parse command line */
        
        var arguments = commandLine.rawArguments
        
        if arguments.count == 0 {
                
                orderUsage()
                Debug.terminate(EX_OK)
                
        } else if arguments[0] == "--print" {
                
                let bootOrder = Nvram.shared.bootOrderArray
                var string = ""
                if bootOrder.count > 0 {
                        for bootNum in bootOrder {
                                string += bootNum.variableName
                                string += " "
                        }
                        print(string)
                        Debug.terminate(EX_OK)
                } else {
                        print("BootOrder data not found")
                        Debug.terminate(EX_OK)
                }
        }
        
        switch arguments[0] {
                
        case "--set":
                
                checkPermissions()
                let setUsageString = "usage: bootoption order --set Boot#### Boot#### Boot#### ..."
                Debug.log("--set", type: .info)
                arguments.removeFirst()
                var newBootOrder: [BootNumber] = []
                
                for arg in arguments {
                        
                        guard let bootNum = bootNumberFromString(arg), let _ = Nvram.shared.bootOptionData(bootNum) else {
                                print("order: invalid argument '\(arg)' for option '--set'", to: &standardError)
                                print(setUsageString)
                                Debug.terminate(EX_USAGE)
                        }
                        
                        if !newBootOrder.contains(bootNum) {
                                newBootOrder.append(bootNum)
                        } else {
                                print("order: '\(bootNum.variableName)' was specified more than once")
                                print(setUsageString)
                                Debug.terminate(EX_USAGE)
                        }
                }
                
                Nvram.shared.setBootOrder(array: newBootOrder)
                Debug.terminate(EX_OK)
                
        case "--delete":
                
                checkPermissions()
                Nvram.shared.deleteBootOrder()
                Debug.terminate(EX_OK)
                
        default:
                
                var optionIndex: Int?
                var destination: Int?
        
                switch arguments.count {
                case 2:
                        optionIndex = zeroBasedIndex(arguments[0])
                        destination = zeroBasedIndex(arguments[1])
                case 3:
                        let preposition = arguments[1].lowercased()
                        if preposition == "to" || preposition == "-to" || preposition == "--to" {
                                optionIndex = zeroBasedIndex(arguments[0])
                                destination = zeroBasedIndex(arguments[2])
                        }
                default:
                        orderUsage()
                        Debug.terminate(EX_USAGE)
                }
                
                if let optionIndex = optionIndex, let destination = destination {
                        
                        checkPermissions()
                        var bootOrder = Nvram.shared.bootOrderArray
                        
                        guard bootOrder.count > 0 else {
                                Debug.fault("BootOrder data not found")
                        }
                        
                        /* Check position parameters are valid */
                        
                        let indices = bootOrder.indices
                        guard indices.contains(optionIndex) && indices.contains(destination) else {
                                Debug.fault("Index out of range")
                        }
                        
                        /* Change order */
                        
                        bootOrder.order(itemAtIndex: optionIndex, to: destination)
                        
                        /* Data from re-ordered array */
                        
                        let data = newBootOrderData(fromArray: bootOrder)
                        
                        /* Set new boot order */
                        
                        if !Nvram.shared.setBootOrder(data: data) {
                                Debug.fault("Error setting new boot order")
                        }
                        
                        Debug.terminate(EX_OK)
                }
                        
                orderUsage()
                Debug.terminate(EX_USAGE)

        }
}

func orderUsage() {
        print("usage: bootoption order --print" , to: &standardError)
        print("", to: &standardError)
        print("       bootoption order <current position> to <new position>", to: &standardError)
        print("", to: &standardError)
        print("explicitly set the BootOption variable:", to: &standardError)
        print("       bootoption order --set Boot#### Boot#### Boot#### ...", to: &standardError)
        print("", to: &standardError)
        print("delete the BootOption variable:", to: &standardError)
        print("       bootoption order --delete", to: &standardError)
        Debug.terminate(EX_USAGE)
}

func zeroBasedIndex(_ nthString: String) -> Int? {
        guard let position = Int(nthString) else {
                return nil
        }
        guard position > 0 else {
                return nil
        }
        return position - 1
}

func checkPermissions() {
        if NSUserName() != "root" {
                Debug.log("Only root can set NVRAM variables", type: .error)
                Debug.fault("Permission denied")
        }
}
