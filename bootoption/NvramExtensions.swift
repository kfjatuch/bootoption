/*
 * File: NvramExtensions.swift
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

extension Nvram {
        
        /*
         *  GET functions
         */
        
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
        
        func getBootOption(_ number: Int) -> Data? {
                let name: String = bootOptionName(for: number)
                return self.options.getDataValue(forProperty: nameWithGuid(name))
        }
        
        func getBootCurrent() -> Data? {
                return self.options.getDataValue(forProperty: nameWithGuid("BootCurrent"))
        }
        
        func getBootNext() -> Data? {
                return self.options.getDataValue(forProperty: nameWithGuid("BootNext"))
        }
        
        func getTimeout() -> Data? {
                return self.options.getDataValue(forProperty: nameWithGuid("Timeout"))
        }
        
        func getBootOrder() -> Data? {
                return self.options.getDataValue(forProperty: nameWithGuid("BootOrder"))
        }
        
        
        
        
        
        /*
         *  SET and CREATE functions
         */
        
        func setBootOrder(data: Data) -> Bool {
                let set = self.options.setDataValue(forProperty: nameWithGuid("BootOrder"), value: data)
                let sync = self.nvramSyncNow(withNamedVariable: nameWithGuid("BootOrder"))
                if set + sync != 0 {
                        return false
                }
                return true
        }
        
        func setTimeout(int: Int) -> Bool {
                var timeoutValue = UInt16(int)
                var data = Data.init()
                data.append(UnsafeBufferPointer(start: &timeoutValue, count: 1))
                let set = self.options.setDataValue(forProperty: nameWithGuid("Timeout"), value: data)
                let sync = self.nvramSyncNow(withNamedVariable: nameWithGuid("Timeout"))
                if set + sync != 0 {
                        return false
                }
                return true
        }
        
        func addToStartOfBootOrder(_ number: Int) -> Bool {
                let name = bootOptionName(for: number)
                guard self.getBootOption(number) != nil else {
                        Log.def("Couldn't get %{public}@ data, cancelling add to start", args: name)
                        return false
                }
                guard let bootOrder: Data = getBootOrder() else {
                        Log.def("Error getting BootOrder, cancelling add to start")
                        return false
                }
                var newOption = UInt16(number)
                var data = Data.init()
                data.append(UnsafeBufferPointer(start: &newOption, count: 1))
                data.append(bootOrder)
                let set = self.options.setDataValue(forProperty: nameWithGuid("BootOrder"), value: data)
                let sync = self.nvramSyncNow(withNamedVariable: nameWithGuid("BootOrder"))
                if set + sync != 0 {
                        return false
                }
                return true
        }
        
        func createNewBootOption(withData data: Data, addToBootOrder: Bool = false) -> Int? {
                guard let number: Int = self.discoverEmptyBootOption() else {
                        return nil
                }
                let name: String = bootOptionName(for: number)
                let set = self.options.setDataValue(forProperty: nameWithGuid(name), value: data)
                let sync = self.nvramSyncNow(withNamedVariable: nameWithGuid(name))
                if set + sync != 0 {
                        return nil
                }
                return number
        }
        
        
        
        
        
        /*
         *  DELETE functions
         */
        
        func deleteBootOption(_ number: Int) {
                let name: String = bootOptionName(for: number)
                self.deleteVariable(key: nameWithGuid(name))
                Log.info("Asked kernel to delete %{public}@", args: name)
                // to do: needs to be read back to confirm success
        }
        
        
        
        
        
        /*
         *  Helper: Return an unused boot option number to write to
         */
        
        func discoverEmptyBootOption(leavingSpace: Bool = false) -> Int? {
                var counter: Int = 0
                for number: Int in 0x0 ..< 0xFF {
                        if let _: Data = self.getBootOption(number) {
                                continue
                        } else {
                                if !leavingSpace {
                                        Log.info("Empty boot option discovered: %{public}X", args: number)
                                        return number
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
                                                Log.info("Empty option leaving space: %{public}X", args: number)
                                                return number
                                        }
                                }
                        }
                }
                Log.def("Empty option discovery failed")
                return nil
        }
        
}
