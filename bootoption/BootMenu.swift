/*
 * File: BootMenu.swift
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

class BootMenu {
        
        var options: [EfiLoadOption] = Array()
        
        var bootCurrentString: String {
                if let bootCurrentNumber: BootNumber = Nvram.shared.bootCurrent {
                        return bootCurrentNumber.variableName
                } else {
                        return "Not set"
                }
        }
        
        var bootNextString: String {
                if let bootNextNumber: BootNumber = Nvram.shared.bootNext {
                        return bootNextNumber.variableName
                } else {
                        return "Not set"
                }
        }
        
        var timeoutString: String {
                if let timeoutSeconds: UInt16 = Nvram.shared.timeout {
                        let stringValue = String(timeoutSeconds)
                        return stringValue
                } else {
                        return "Not set"
                }
        }
        
        init() {
                Debug.log("Initialising boot menu", type: .info)
                /* Get data for options we can find */
                for bootNumber: BootNumber in 0x0 ..< 0xFF {
                        if let data: Data = Nvram.shared.bootOptionData(bootNumber) {
                                Debug.log("%@ %@", type: .info, argsList: bootNumber.variableName, data)
                                options.append(EfiLoadOption(fromBootNumber: bootNumber, data: data))
                        }
                        
                }
                /* Sort options by BootOrder */
                options.sort(by: { $0.positionInBootOrder! < $1.positionInBootOrder! } )
                
                Debug.log("Boot menu initialised", type: .info)
        }
        
        var outputString: String {
                var output = String()
                output.append("BootCurrent: \(bootCurrentString)\n")
                output.append("BootNext: \(bootNextString)\n")
                output.append("Timeout: \(timeoutString)\n")
                
                /* List of options */
                
                for option in options {
                        /* Menu */
                        let separator = " "
                        var paddedOrder = " --"
                        if option.positionInBootOrder != -1 {
                                paddedOrder = String(option.positionInBootOrder! + 1).leftPadding(toLength: 3, withPad: " ")
                        }
                        output.append(paddedOrder)
                        output.append(":")
                        output.append(separator)
                        output.append(option.bootNumber!.variableName)
                        output.append(separator)
                        output.append(option.descriptionString!.padding(toLength: 28, withPad: " ", startingAt: 0))
                        if !option.active {
                                output.append(" *D")
                        }
                        if option.hidden {
                                output.append(" *H")
                        }
                        output.append("\n")
                }
                
                output.removeLast()
                return output
        }
}
