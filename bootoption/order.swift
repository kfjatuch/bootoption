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
        
        var bootOrder = Nvram.shared.bootOrderArray
        
        /* Parse command line */
        
        var arguments = commandLine.rawArguments
        
        if arguments.count == 0 {
                Debug.log("No input", type: .info)
                orderUsage()
                Debug.terminate(EX_OK)
        }
        
        if DEBUG && arguments[0] == "--print" {
                Debug.log("--print", type: .info)
                var string = ""
                if bootOrder.count > 0 {
                        for bootNum in bootOrder {
                                string += bootNum.variableName
                                string += " "
                        }
                        print(string)
                        Debug.terminate(EX_OK)
                } else {
                        Debug.fault("BootOrder data not found")
                }
        }
                
        Debug.log("Will attempt to parse to:from: indices", type: .info)
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
                Debug.log("Invalid input (1)", type: .error)
                orderUsage()
                Debug.terminate(EX_USAGE)
        }
        
        if let optionIndex = optionIndex, let destination = destination {
                
                if NSUserName() != "root" {
                        Debug.log("Only root can set NVRAM variables", type: .error)
                        Debug.fault("permission denied")
                }
                
                guard bootOrder.count > 0 else {
                        Debug.fault("BootOrder data not found")
                }
                
                /* Check position parameters are valid */
                
                let indices = bootOrder.indices
                guard indices.contains(optionIndex) && indices.contains(destination) else {
                        Debug.fault("index out of range")
                }
                
                /* Change order */
                
                bootOrder.order(itemAtIndex: optionIndex, to: destination)
                
                /* Data from re-ordered array */
                
                let data = newBootOrderData(fromArray: bootOrder)
                
                /* Set new boot order */
                
                if !Nvram.shared.setBootOrder(data: data) {
                        Debug.fault("error setting new boot order")
                }
                
                Debug.terminate(EX_OK)
                
        } else {
                
                Debug.log("Invalid input (2)", type: .error)
                orderUsage()
                Debug.terminate(EX_USAGE)
                
        }
}

func orderUsage() {
        print("usage: bootoption order <current position> to <new position>", to: &standardError)
        if DEBUG {
                print("", to: &standardError)
                print("       bootoption order --print" , to: &standardError)
        }
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
