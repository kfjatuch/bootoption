/*
 * File: Dmpstore.swift
 *
 * bootoption © vulgo 2017 - A program to create / save an EFI boot
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

struct DmpstoreOption {
        
        static let nameSizeConstant: Int = 18
        
        var data = Data.init()
        var chosen: Int?
        var created: Int? = nil
        let nameSize = Data.init(bytes: [UInt8(DmpstoreOption.nameSizeConstant), 0x0, 0x0, 0x0])
        var dataSize = Data.init()
        var name = Data.init()
        let guid = Data.init(bytes: [0x61, 0xdf, 0xe4, 0x8b, 0xca, 0x93, 0xd2, 0x11, 0xaa, 0xd, 0x0, 0xe0, 0x98, 0x3, 0x2b, 0x8c])
        let attributes = Data.init(bytes: [0x7, 0x0, 0x0, 0x0])
        var variableData = Data.init()
        var crc32 = Data.init()
        
        init(fromData variable: Data) {
                
                var nvram = RegistryEntry.init(fromPath: "IODeviceTree:/options")
                
                func readGlobalVariable(variable: String) -> Data? {
                        let EFIGlobalGUID:String = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C"
                        let nameWithGUID:String = EFIGlobalGUID + ":" + variable
                        return nvram.dataFrom(key: nameWithGUID)
                }
                
                func getEmptyBootOption() -> String? {
                        var counter = 0
                        for n in 0x0 ..< 0xFF {
                                let name = "Boot" + String(format:"%04X", n)
                                if let _: Data = readGlobalVariable(variable: name) {
                                        continue
                                } else {
                                        counter += 1
                                        if counter < 3 {
                                                /* choose the 3rd empty Boot variable */
                                                continue
                                        } else {
                                                self.chosen = n as Int
                                                return name
                                        }
                                }
                        }
                        return nil
                }
                
                var dataSizeValue = UInt32(variable.count)
                /* store dataSize */
                self.dataSize.append(UnsafeBufferPointer(start: &dataSizeValue, count: 1))
                
                let emptyBootOption = getEmptyBootOption()
                if emptyBootOption == nil {
                        fatalError("emptyBootOption is nil")
                }
                var nameData = emptyBootOption!.data(using: String.Encoding.utf16)!
                nameData.removeFirst()
                nameData.removeFirst()
                nameData.append(contentsOf: [0, 0])
                if nameData.count != DmpstoreOption.nameSizeConstant {
                        fatalError("nameSize isn't \(DmpstoreOption.nameSizeConstant)")
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
                
                let crc = CRC32()
                crc.run(data: buffer)
                var crcValue: UInt32 = crc.crc
                /* store crc32 data */
                self.crc32.append(UnsafeBufferPointer(start: &crcValue, count: 1))
                
                /* store dmpstore data */
                self.data.append(buffer)
                self.data.append(self.crc32)
                
                /* store created */
                self.created = self.chosen
                
        }
    
}
