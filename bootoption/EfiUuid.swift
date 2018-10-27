/*
 * File: EfiUuid.swift
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

struct EfiUuid {
        
        var data: Data
        
        var uuidString: String {
                var string = String()
                var buffer = data
                string += String(format:"%08X", buffer.remove32()) + "-"
                string += String(format:"%04X", buffer.remove16()) + "-"
                string += String(format:"%04X", buffer.remove16()) + "-"
                string += String(format:"%04X", buffer.remove16().byteSwapped) + "-"
                string += String(format:"%04X", buffer.remove16().byteSwapped)
                string += String(format:"%08X", buffer.remove32().byteSwapped)
                return string
        }
        
        init(fromData data: Data) {
               self.data = data.subdata(in: Range(0...15))
        }
        
        init(uuid: UUID) {
                data = Data()
                let uuidBytes = uuid.uuid
                data.append(uuidBytes.3)
                data.append(uuidBytes.2)
                data.append(uuidBytes.1)
                data.append(uuidBytes.0)
                data.append(uuidBytes.5)
                data.append(uuidBytes.4)
                data.append(uuidBytes.7)
                data.append(uuidBytes.6)
                data.append(uuidBytes.8)
                data.append(uuidBytes.9)
                data.append(uuidBytes.10)
                data.append(uuidBytes.11)
                data.append(uuidBytes.12)
                data.append(uuidBytes.13)
                data.append(uuidBytes.14)
                data.append(uuidBytes.15)
        }
}
