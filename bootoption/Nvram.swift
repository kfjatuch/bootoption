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
                        if let _: Data = nvram.getBootOption(n) {
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
        
        func nvramSyncNow(withNamedVariable key: String, useForceSync: Bool = true) {
                if (useForceSync) {
                        if !self.options.setStringValue(forProperty: ioNvramForceSyncNowPropertyKey, value: key) {
                                print("Error setting ioNvramForceSyncNowPropertyKey value")
                        }
                } else {
                        if !self.options.setStringValue(forProperty: kIONVRAMSyncNowPropertyKey, value: key) {
                                print("Error setting kIONVRAMSyncNowPropertyKey value")
                        }
                }
        }
        
        func getBootOption(_ n: Int) -> Data? {
                let name: String = bootOptionName(for: n)
                let nameWithGuid = "\(efiGlobalGuid):\(name)"
                return self.options.getDataValue(forProperty: nameWithGuid)
        }
        
        func getBootOrder() -> Data? {
                let nameWithGuid: String = "\(efiGlobalGuid):BootOrder"
                return self.options.getDataValue(forProperty: nameWithGuid)
        }
        
        private func addToStartOfBootOrder(_ n: Int) -> Bool {
                guard self.getBootOption(n) != nil else {
                        print("Couldn't get BootXXXX data (addToStartOfBootOrder)")
                        return false
                }
                guard let bootOrder: Data = getBootOrder() else {
                        print("Error getting BootOrder (addToStartOfBootOrder")
                        return false
                }
                var newOption = UInt16(n)
                var data = Data.init()
                data.append(UnsafeBufferPointer(start: &newOption, count: 1))
                data.append(bootOrder)
                let nameWithGuid: String = "\(efiGlobalGuid):BootOrder"
                if !self.options.setDataValue(forProperty: nameWithGuid, value: data) {
                        print("Error setting BootOrder (addToStartOfBootOrder)")
                        return false
                }
                /* sync now */
                self.nvramSyncNow(withNamedVariable: nameWithGuid)
                return true  
        }
        
        func createNewBootOption(withData data: Data, addToBootOrder: Bool = false) -> Int? {
                guard let n: Int = self.getEmptyBootOption() else {
                        print("Couldn't find an empty boot variable (createNewBootOption")
                        return nil
                }
                let name: String = bootOptionName(for: n)
                let nameWithGuid = "\(efiGlobalGuid):\(name)"
                if !self.options.setDataValue(forProperty: nameWithGuid, value: data) {
                        print("Failed to create new boot option from data (createNewBootOption)")
                        return nil
                }
                /* sync now */
                self.nvramSyncNow(withNamedVariable: nameWithGuid)
                if addToBootOrder {
                        if !self.addToStartOfBootOrder(n) {
                                return nil
                        }
                }
                return n
        }
}
