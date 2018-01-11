/*
 * File: Dmpstore.swift
 *
 * bootoption © vulgo 2017-2018 - A program to create / save an EFI boot
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

struct Dmpstore {
        
        static let crc = CRC32()
        
        struct Option {
                static let nameSizeConstant: Int = 18
                var data = Data.init()
                var created: Int? = nil
                let nameSize = Data.init(bytes: [UInt8(Dmpstore.Option.nameSizeConstant), 0x0, 0x0, 0x0])
                var dataSize = Data.init()
                var name = Data.init()
                let guid = Data.init(bytes: [0x61, 0xdf, 0xe4, 0x8b, 0xca, 0x93, 0xd2, 0x11, 0xaa, 0xd, 0x0, 0xe0, 0x98, 0x3, 0x2b, 0x8c])
                let attributes = Data.init(bytes: [0x7, 0x0, 0x0, 0x0])
                var variableData = Data.init()
                var crc32 = Data.init()
                
                init(fromData variable: Data) {
                        Log.info("Dmpstore.Option.init: Creating a boot variable for dmpstore")
                        var dataSizeValue = UInt32(variable.count)
                        /* store dataSize */
                        self.dataSize.append(UnsafeBufferPointer(start: &dataSizeValue, count: 1))
                        guard let emptyBootOption: Int = nvram.discoverEmptyBootNumber(leavingSpace: true) else {
                                Log.error("Empty boot option is nil")
                                exit(EX_IOERR)
                        }
                        let name = nvram.bootStringFromBoot(number: emptyBootOption)
                        var nameData = name.data(using: String.Encoding.utf16)!
                        nameData.removeFirst()
                        nameData.removeFirst()
                        nameData.append(contentsOf: [0, 0])
                        if nameData.count != Dmpstore.Option.nameSizeConstant {
                                Log.error("Name size data is wrong")
                                exit(EX_IOERR)
                        }
                        /* store name data */
                        self.name = nameData
                        
                        /* store variable data */
                        self.variableData.append(variable)
                        
                        var buffer = Data.init()
                        buffer.append(self.nameSize)
                        buffer.append(self.dataSize)
                        buffer.append(self.name)
                        buffer.append(self.guid)
                        buffer.append(self.attributes)
                        buffer.append(self.variableData)
                        
                        crc.run(data: buffer)
                        var crcValue: UInt32 = crc.crc
                        /* store crc32 data */
                        self.crc32.append(UnsafeBufferPointer(start: &crcValue, count: 1))
                        
                        /* store dmpstore data */
                        self.data.append(buffer)
                        self.data.append(self.crc32)
                        
                        /* store created */
                        self.created = emptyBootOption
                        Log.info("Created a new variable")
                }
        }
        
        struct Order {
                var data = Data.init()
                let nameSize = Data.init(bytes: [0x14, 0x0, 0x0, 0x0])
                var dataSize = Data.init()
                var name = Data.init(bytes: [0x42, 0x00, 0x6F, 0x00, 0x6F, 0x00, 0x74, 0x00, 0x4F, 0x00, 0x72, 0x00, 0x64, 0x00, 0x65, 0x00, 0x72, 0x00, 0x00, 0x00])
                let guid = Data.init(bytes: [0x61, 0xdf, 0xe4, 0x8b, 0xca, 0x93, 0xd2, 0x11, 0xaa, 0xd, 0x0, 0xe0, 0x98, 0x3, 0x2b, 0x8c])
                let attributes = Data.init(bytes: [0x7, 0x0, 0x0, 0x0])
                var variableData = Data.init()
                var crc32 = Data.init()
                
                init(adding: Int?) {
                        Log.info("Dmpstore.Order.init: Creating a boot order variable for dmpstore")
                        if adding == nil {
                                Log.error("Option to add is nil")
                                exit(EX_IOERR)
                        }

                        guard let bootOrder: Data = nvram.getBootOrder() else {
                                Log.error("Couldn't get boot order from nvram")
                                exit(EX_IOERR)
                        }
                        
                        // add to boot order and store variable data
                        var newOption = UInt16(adding!)
                        self.variableData.append(UnsafeBufferPointer(start: &newOption, count: 1))
                        self.variableData.append(bootOrder)
                        
                        var dataSizeValue = UInt32(self.variableData.count)
                        /* store dataSize */
                        self.dataSize.append(UnsafeBufferPointer(start: &dataSizeValue, count: 1))
                        
                        var buffer = Data.init()
                        buffer.append(self.nameSize)
                        buffer.append(self.dataSize)
                        buffer.append(self.name)
                        buffer.append(self.guid)
                        buffer.append(self.attributes)
                        buffer.append(self.variableData)

                        crc.run(data: buffer)
                        var crcValue: UInt32 = crc.crc
                        /* store crc32 data */
                        self.crc32.append(UnsafeBufferPointer(start: &crcValue, count: 1))
                        
                        /* store dmpstore data */
                        self.data.append(buffer)
                        self.data.append(self.crc32)
                        Log.info("Created an updated 'BootOrder' variable")
                }
        }
}
