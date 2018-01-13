/*
 * File: BootMenu.swift
 *
 * bootoption © vulgo 2018 - A program to create / save an EFI boot
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

class BootMenu {
        
        struct Option {
                var name: String
                var order: Int
                var enabled: Bool
                var hidden: Bool
                var description: String
                
                init(name: String, data: Data, order: Int?) {
                        func removeOptionDescription(from buffer: inout Data) -> String {
                                var description: String = ""
                                for _ in buffer {
                                        let byte: UInt16 = remove16BitInt(from: &buffer)
                                        if byte == 0 {
                                                break
                                        }
                                        description.append(Character(UnicodeScalar(byte)!))
                                }
                                return description
                        }
                        self.name = name
                        self.order = order ?? -1
                        var buffer: Data = data
                        let attributes: UInt32 = remove32BitInt(from: &buffer)
                        remove16BitInt(from: &buffer)
                        self.enabled = (attributes & 0x1 == 0x1 ? true : false) // bit 0
                        self.hidden = (attributes & 0x8 == 0x8 ? true : false)
                        self.description = removeOptionDescription(from: &buffer)
                }
        }
        
        var bootOrder: [UInt16]?
        var bootCurrent: UInt16?
        var bootNext: UInt16?
        var timeout: UInt16?
        var options: [Option] = Array()

        init() {
                CLog.info("Initialising boot menu")
                /* BootOrder */
                if let bootOrderArray: [UInt16] = nvram.getBootOrderArray() {
                        bootOrder = bootOrderArray
                }
                /* BootCurrent */
                if var bootCurrentBuffer: Data = nvram.getBootCurrent() {
                        bootCurrent = remove16BitInt(from: &bootCurrentBuffer)
                }
                /* BootNext */
                if var bootNextBuffer: Data = nvram.getBootNext() {
                        bootNext = remove16BitInt(from: &bootNextBuffer)
                }
                /* Timeout */
                if var timeoutBuffer: Data = nvram.getTimeout() {
                        timeout = remove16BitInt(from: &timeoutBuffer)
                }
                /* Get data for options we can find */
                for n in 0x0 ..< 0xFF {
                        if let data: Data = nvram.getBootOption(n) {
                                let order: Int? = self.bootOrder?.index(of: UInt16(n))
                                options.append(Option.init(name: nvram.bootStringFromBoot(number: n), data: data, order: order))
                        }
                        
                }
                /* Sort options by BootOrder */
                options.sort(by: { $0.order < $1.order } )
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
                                paddedOrder = String(option.order + 1).leftPadding(toLength: 3, withPad: " ")
                        }
                        string.append(paddedOrder)
                        string.append(":")
                        string.append(separator)
                        string.append(option.name)
                        string.append(separator)
                        string.append(option.description.padding(toLength: 28, withPad: " ", startingAt: 0))
                        if !option.enabled {
                                string.append(" *D")
                        }
                        if option.hidden {
                                string.append(" *H")
                        }
                        string.append("\n")
                }
                string.removeLast()
                CLog.info("Boot menu initialised")
                return string
        }
}
