/*
 * File: Nvram.swift
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

class Nvram {
        
        let ioNvramForceSyncNowPropertyKey = "IONVRAM-FORCESYNCNOW-PROPERTY"
        let efiGlobalGuid:String = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C"
        let options = RegistryEntry(fromPath: "IODeviceTree:/options")
        
        func bootOptionName(for n: Int) -> String {
                let string = "Boot\(String(format:"%04X", n))"
                return string
        }
        
        func getEmptyBootOption(leavingSpace: Bool = false) -> Int? {
                var counter: Int = 0
                for n: Int in 0x0 ..< 0xFF {
                        if let _: Data = self.getBootOption(n) {
                                continue
                        } else {
                                if !leavingSpace {
                                        return n
                                } else {
                                        /*
                                         *  leave space for firmware to add a few removable
                                         *  entries or other devices at subsequent boot -
                                         *  only used when writing a 'BootOrder' to disk
                                         *  and probably not needed at all
                                         */
                                        counter += 1
                                        /*  arbitrarily choose the 3rd empty variable */
                                        if counter < 3 {
                                                continue
                                        } else {
                                                return n
                                        }
                                }
                        }
                }
                return nil
        }
        
        func deleteVariable(key: String) {
                let _ = self.options.setStringValue(forProperty: kIONVRAMDeletePropertyKey, value: key)
        }
        
        func nvramSyncNow(withNamedVariable key: String, useForceSync: Bool = true) -> kern_return_t {
                if (useForceSync) {
                        let result = self.options.setStringValue(forProperty: ioNvramForceSyncNowPropertyKey, value: key)
                        return result
                } else {
                        let result = self.options.setStringValue(forProperty: kIONVRAMSyncNowPropertyKey, value: key)
                        return result
                }
        }
        
        func getBootOption(_ n: Int) -> Data? {
                let name: String = bootOptionName(for: n)
                let nameWithGuid = "\(efiGlobalGuid):\(name)"
                return self.options.getDataValue(forProperty: nameWithGuid)
        }
        
        func getBootCurrent() -> Data? {
                let nameWithGuid = "\(efiGlobalGuid):BootCurrent"
                return self.options.getDataValue(forProperty: nameWithGuid)
        }
        
        func getBootNext() -> Data? {
                let nameWithGuid = "\(efiGlobalGuid):BootNext"
                return self.options.getDataValue(forProperty: nameWithGuid)
        }
        
        func getTimeout() -> Data? {
                let nameWithGuid = "\(efiGlobalGuid):Timeout"
                return self.options.getDataValue(forProperty: nameWithGuid)
        }
        
        func getBootOrder() -> Data? {
                let nameWithGuid: String = "\(efiGlobalGuid):BootOrder"
                return self.options.getDataValue(forProperty: nameWithGuid)
        }
        
        func getBootOrderArray() -> [UInt16]? {
                var bootOrder: [UInt16] = Array()
                if var bootOrderBuffer: Data = self.getBootOrder() {
                        let bootOrderBufferSize: Int = bootOrderBuffer.count
                        for _ in 1 ... (bootOrderBufferSize / 2) {
                                let optionNumber: UInt16 = remove16BitInt(from: &bootOrderBuffer)
                                bootOrder.append(optionNumber)
                        }
                }
                if !bootOrder.isEmpty {
                        return bootOrder
                } else {
                        return nil
                }
        }
        
        private func addToStartOfBootOrder(_ n: Int) -> Bool {
                guard self.getBootOption(n) != nil else {
                        Log.def("Couldn't get BootXXXX data (addToStartOfBootOrder)")
                        return false
                }
                guard let bootOrder: Data = getBootOrder() else {
                        Log.def("Error getting BootOrder (addToStartOfBootOrder")
                        return false
                }
                var newOption = UInt16(n)
                var data = Data.init()
                data.append(UnsafeBufferPointer(start: &newOption, count: 1))
                data.append(bootOrder)
                let nameWithGuid: String = "\(efiGlobalGuid):BootOrder"
                var result = self.options.setDataValue(forProperty: nameWithGuid, value: data)
                if result != KERN_SUCCESS {
                        Log.def("Error adding to start of BootOrder")
                        return false
                }
                /* sync now */
                result = self.nvramSyncNow(withNamedVariable: nameWithGuid)
                if result != KERN_SUCCESS {
                        Log.def("Error syncing BootOrder (addToStartOfBootOrder)")
                }
                return true  
        }
        
        func setBootOrder(data: Data) -> Bool {
                let nameWithGuid: String = "\(efiGlobalGuid):BootOrder"
                var result = self.options.setDataValue(forProperty: nameWithGuid, value: data)
                if result != KERN_SUCCESS {
                        Log.def("Error setting BootOrder (setBootOrder)")
                        return false
                }
                /* sync now */
                result = self.nvramSyncNow(withNamedVariable: nameWithGuid)
                if result != KERN_SUCCESS {
                        Log.def("Error syncing BootOrder (setBootOrder)")
                        return false
                }
                return true
        }
        
        func setTimeout(int: Int) -> Bool {
                var timeoutValue = UInt16(int)
                var data = Data.init()
                data.append(UnsafeBufferPointer(start: &timeoutValue, count: 1))
                let nameWithGuid: String = "\(efiGlobalGuid):Timeout"
                var result = self.options.setDataValue(forProperty: nameWithGuid, value: data)
                if result != KERN_SUCCESS {
                        Log.def("Error setting Timeout (setBootOrder)")
                        return false
                }
                /* sync now */
                result = self.nvramSyncNow(withNamedVariable: nameWithGuid)
                if result != KERN_SUCCESS {
                        Log.def("Error syncing Timeout (setTimeout)")
                        return false
                }
                return true
        }
        
        func createNewBootOption(withData data: Data, addToBootOrder: Bool = false) -> Int? {
                guard let n: Int = self.getEmptyBootOption() else {
                        Log.def("Couldn't find an empty boot variable (createNewBootOption")
                        return nil
                }
                let name: String = bootOptionName(for: n)
                let nameWithGuid = "\(efiGlobalGuid):\(name)"
                let addResult = self.options.setDataValue(forProperty: nameWithGuid, value: data)
                if addResult != KERN_SUCCESS {
                        Log.def("Error creating new boot option")
                        return nil
                }
                /* sync now */
                let syncResult = self.nvramSyncNow(withNamedVariable: nameWithGuid)
                if syncResult != KERN_SUCCESS {
                        Log.def("Error syncing new boot option")
                        return nil
                }
                if addResult == KERN_SUCCESS {
                        if !self.addToStartOfBootOrder(n) {
                                Log.def("addToStartOfBootOrder returned false (createNewBootOption)")
                                return nil
                        }
                }
                return n
        }
        
        func deleteBootOption(_ n: Int) {
                let name: String = bootOptionName(for: n)
                let nameWithGuid = "\(efiGlobalGuid):\(name)"
                self.deleteVariable(key: nameWithGuid)
        }
        

}
