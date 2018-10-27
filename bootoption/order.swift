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

func orderUsage() {
        print("Usage: bootoption order <current position> to <new position>" , to: &standardError)
        Debug.terminate(EX_USAGE)
}

func orderMain(optionIndex: Int, destination: Int) {
        
        /* Check permissions */
        
        if NSUserName() != "root" {
                Debug.log("Only root can set NVRAM variables", type: .error)
                Debug.fault("Permission denied")
        }
        
        if var bootOrder = Nvram.shared.bootOrderArray {
                
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
        } else {
                
                /* Failed to get boot order array */
                
                Debug.fault("Couldn't read boot order")
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

/*
 *  Function for command: order
 */

func order() {
        
        /* Parse command line */
        
        var arguments = commandLine.rawArguments
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
        }
        
        if optionIndex == nil || destination == nil {
                orderUsage()
        } else {
                orderMain(optionIndex: optionIndex!, destination: destination!)
        }
}
