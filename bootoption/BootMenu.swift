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
                                options.append(EfiLoadOption.init(fromBootNumber: bootNumber, data: data))
                        }
                        
                }
                /* Sort options by BootOrder */
                options.sort(by: { $0.order! < $1.order! } )
        }
        
        var string: String {
                var string = String()
                var current = String()
                var next = String()
                var timeout = String()
                let notSet = "Not set"
                /* Boot */
                if self.bootCurrent != nil {
                        current = nvram.bootStringFromBoot(number: Int(self.bootCurrent!))
                } else {
                        current = notSet
                }
                if self.bootNext != nil {
                        next = nvram.bootStringFromBoot(number: Int(self.bootNext!))
                } else {
                        next = notSet
                }
                if self.timeout != nil {
                        timeout = String(self.timeout!)
                } else {
                        timeout = notSet
                }
                string.append("BootCurrent: \(current)\n")
                string.append("BootNext: \(next)\n")
                string.append("Timeout: \(timeout)\n")
                for option in self.options {
                        /* Menu */
                        let separator = " "
                        var paddedOrder = " --"
                        if option.order != -1 {
                                paddedOrder = String(option.order! + 1).leftPadding(toLength: 3, withPad: " ")
                        }
                        string.append(paddedOrder)
                        string.append(":")
                        string.append(separator)
                        string.append(nvram.bootStringFromBoot(number: option.bootNumber!))
                        string.append(separator)
                        string.append(option.descriptionString.padding(toLength: 28, withPad: " ", startingAt: 0))
                        if !option.enabled! {
                                string.append(" *D")
                        }
                        if option.hidden! {
                                string.append(" *H")
                        }
                        string.append("\n")
                }
                string.removeLast()
                Log.info("Boot menu initialised")
                return string
        }
}
