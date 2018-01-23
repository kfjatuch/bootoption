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
        
        var bootOrder: [UInt16]?
        var bootCurrent: UInt16?
        var bootNext: UInt16?
        var timeout: UInt16?
        var options: [EfiLoadOption] = Array()

        init() {
                Log.info("Initialising boot menu")
                /* BootOrder */
                if let bootOrderArray: [UInt16] = nvram.getBootOrderArray() {
                        bootOrder = bootOrderArray
                }
                /* BootCurrent */
                if var bootCurrentBuffer: Data = nvram.getBootCurrent() {
                        bootCurrent = bootCurrentBuffer.remove16()
                }
                /* BootNext */
                if var bootNextBuffer: Data = nvram.getBootNext() {
                        bootNext = bootNextBuffer.remove16()
                }
                /* Timeout */
                if var timeoutBuffer: Data = nvram.getTimeout() {
                        timeout = timeoutBuffer.remove16()
                }
                /* Get data for options we can find */
                for bootNumber in 0x0 ..< 0xFF {
                        if let data: Data = nvram.getBootOption(bootNumber) {
                                options.append(EfiLoadOption(fromBootNumber: bootNumber, data: data))
                        }
                        
                }
                /* Sort options by BootOrder */
                options.sort(by: { $0.order! < $1.order! } )
                
                Log.info("Boot menu initialised")
        }
        
        var outputString: String {
                var output = String()
                let notSet = "Not set"
                
                /* BootCurrent, BootNext, Timeout */
                
                var bootCurrentString: String {
                        return bootCurrent != nil ? nvram.bootStringFromBoot(number: Int(bootCurrent!)) : notSet
                }
                var bootNextString: String {
                        return bootNext != nil ? nvram.bootStringFromBoot(number: Int(bootNext!)) : notSet
                }
                var timeoutString: String {
                        if let timeoutValue: UInt16 = timeout {
                                return String(timeoutValue)
                        } else {
                                return notSet
                        }
                }
                output.append("BootCurrent: \(bootCurrentString)\n")
                output.append("BootNext: \(bootNextString)\n")
                output.append("Timeout: \(timeoutString)\n")
                
                /* List of options */
                
                for option in options {
                        /* Menu */
                        let separator = " "
                        var paddedOrder = " --"
                        if option.order != -1 {
                                paddedOrder = String(option.order! + 1).leftPadding(toLength: 3, withPad: " ")
                        }
                        output.append(paddedOrder)
                        output.append(":")
                        output.append(separator)
                        output.append(nvram.bootStringFromBoot(number: option.bootNumber!))
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
