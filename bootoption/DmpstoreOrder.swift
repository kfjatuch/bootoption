//
//  BootOrder.swift
//  bootoption
//
//  Created by Mark on 04/01/2018.
//  Copyright © 2018 vulgo. All rights reserved.
//

import Foundation

struct DmpstoreOrder {
        
        var nvram = RegistryEntry.init(fromPath: "IODeviceTree:/options")
        var data = Data.init()
        let nameSize = Data.init(bytes: [0x14, 0x0, 0x0, 0x0])
        var dataSize = Data.init()
        var name = Data.init(bytes: [0x42, 0x00, 0x6F, 0x00, 0x6F, 0x00, 0x74, 0x00, 0x4F, 0x00, 0x72, 0x00, 0x64, 0x00, 0x65, 0x00, 0x72, 0x00, 0x00, 0x00])
        let guid = Data.init(bytes: [0x61, 0xdf, 0xe4, 0x8b, 0xca, 0x93, 0xd2, 0x11, 0xaa, 0xd, 0x0, 0xe0, 0x98, 0x3, 0x2b, 0x8c])
        let attributes = Data.init(bytes: [0x7, 0x0, 0x0, 0x0])
        var variableData = Data.init()
        var crc32 = Data.init()
        
        init(adding: Int?) {
                
                if adding == nil {
                        fatalError("Option to add is nil")
                }
                
                func readGlobalVariable(variable: String) -> Data? {
                        let EFIGlobalGUID:String = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C"
                        let nameWithGUID:String = EFIGlobalGUID + ":" + variable
                        return nvram.dataFrom(key: nameWithGUID)
                }
                
                func getBootOrder() -> Data? {
                        let bootOrder = readGlobalVariable(variable: "BootOrder")
                        return bootOrder
                }
                
                guard let bootOrder: Data = getBootOrder() else {
                        fatalError("Couldn't get boot order from nvram")
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
                
                let crc = CRC32()
                crc.run(data: buffer)
                var crcValue: UInt32 = crc.crc
                /* store crc32 data */
                self.crc32.append(UnsafeBufferPointer(start: &crcValue, count: 1))
                
                /* store dmpstore data */
                self.data.append(buffer)
                self.data.append(self.crc32)
                
        }
        
}
