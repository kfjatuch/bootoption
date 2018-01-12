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
                let name: String = bootStringFromBoot(number: number)
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
                Log.info("Asked the kernel to set a new BootOrder")
                return true
        }
        
        func setTimeout(seconds: Int) -> Bool {
                var timeoutValue = UInt16(seconds)
                var data = Data.init()
                data.append(UnsafeBufferPointer(start: &timeoutValue, count: 1))
                let set = self.options.setDataValue(forProperty: nameWithGuid("Timeout"), value: data)
                let sync = self.nvramSyncNow(withNamedVariable: nameWithGuid("Timeout"))
                if set + sync != 0 {
                        return false
                }
                Log.info("Asked the kernel to set a new Timeout")
                return true
        }
        
        func setBootNext(bootString: String?) -> Bool {
                guard let string = bootString else {
                        Log.def("bootString is nil, not setting BootNext")
                        return false
                }
                guard let bootNumber = bootNumberFromBoot(string: string) else {
                        Log.def("Couldn't find %{public}@, not setting BootNext", string)
                        return false
                }
                var bootNext = UInt16(bootNumber)
                var data = Data.init()
                data.append(UnsafeBufferPointer(start: &bootNext, count: 1))
                let set = self.options.setDataValue(forProperty: nameWithGuid("BootNext"), value: data)
                let sync = self.nvramSyncNow(withNamedVariable: nameWithGuid("BootNext"))
                if set + sync != 0 {
                        return false
                }
                Log.info("Asked the kernel to set BootNext")
                return true
        }

        @discardableResult func addToBootOrder(_ number: Int, atIndex index: Int = 0) -> Bool {
                let name = bootStringFromBoot(number: number)
                guard self.getBootOption(number) != nil else {
                        Log.def("Couldn't get %{public}@ data, cancelling add to boot order", name)
                        return false
                }
                guard var bootOrder: [UInt16] = getBootOrderArray() else {
                        Log.def("Error getting BootOrder, cancelling add to boot order")
                        return false
                }
                if bootOrder.indices.contains(index) {
                        Log.info("Inserted to boot order at index %{public}@", index)
                        bootOrder.insert(UInt16(number), at: index)
                } else {
                        Log.def("Index out of range, appending to boot order instead")
                        bootOrder.append(UInt16(number))
                }
                let data = bootOrderData(from: bootOrder)
                if !self.setBootOrder(data: data) {
                        return false
                }
                return true
        }
        
        func createNewAndAddToBootOrder(withData data: Data) -> Int? {
                guard let bootNumber: Int = self.discoverEmptyBootNumber() else {
                        return nil
                }
                let name: String = bootStringFromBoot(number: bootNumber)
                let set = self.options.setDataValue(forProperty: nameWithGuid(name), value: data)
                let sync = self.nvramSyncNow(withNamedVariable: nameWithGuid(name))
                if set + sync != 0 {
                        Log.def("Create new boot option returned nil")
                        return nil
                }
                addToBootOrder(bootNumber, atIndex: 0)
                Log.info("Asked the kernel to set %{public}@", name)
                return bootNumber
        }
        
        
        
        
        
        /*
         *  DELETE and REMOVE functions
         */
        
        func deleteBootOption(_ number: Int) {
                let name: String = bootStringFromBoot(number: number)
                self.deleteVariable(key: nameWithGuid(name))
                Log.info("Asked the kernel to delete %{public}@", name)
                // to do: needs to be read back to confirm success
        }
        
        func deleteTimeout() {
                self.deleteVariable(key: nameWithGuid("Timeout"))
                Log.info("Asked the kernel to delete Timeout")
        }
        
        func deleteBootNext() {
                self.deleteVariable(key: nameWithGuid("BootNext"))
                Log.info("Asked the kernel to delete BootNext")
        }
        
        func removeFromBootOrder(number bootNumber: Int) -> [UInt16]? {
                var bootOrder = self.getBootOrderArray()
                if let index: Int = bootOrder?.index(of: UInt16(bootNumber)) {
                        bootOrder?.remove(at: index)
                        /* make the new bootorder */
                        var newBootOrder = Data.init()
                        if !bootOrder!.isEmpty {
                                for option in bootOrder! {
                                        var buffer = option
                                        newBootOrder.append(UnsafeBufferPointer(start: &buffer, count: 1))
                                }
                        }
                        /* set the new bootorder */
                        if nvram.setBootOrder(data: newBootOrder) {
                                Log.info("Remove from boot order returned an updated boot order array")
                                return bootOrder
                        }
                }
                Log.def("Remove from boot order returned nil")
                return nil
        }
        
        
        
        
        
        /*
         *  Helper: Return an unused boot option number to write to
         */
        
        func discoverEmptyBootNumber(leavingSpace: Bool = false) -> Int? {
                var counter: Int = 0
                for number: Int in 0x0 ..< 0xFF {
                        if let _: Data = self.getBootOption(number) {
                                continue
                        } else {
                                if !leavingSpace {
                                        Log.info("Empty boot option discovered: %{public}X", number)
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
                                                Log.info("Empty option leaving space: %{public}X", number)
                                                return number
                                        }
                                }
                        }
                }
                Log.def("Empty option discovery failed")
                return nil
        }
        
        /*
         *  Helper: Read integer value from (user provided) Boot#### string
         */
        
        func bootNumberFromBoot(string: String) -> Int? {
                let logErrorMessage: StaticString = "Parsing user provided Boot#### failed"
                var hexString = String()
                if string.characters.count == 8 && string.uppercased().hasPrefix("BOOT") {
                        hexString = string.subString(from: 4, to: 8)
                } else if string.characters.count < 5 {
                        hexString = string
                } else {
                        Log.def(logErrorMessage)
                        return nil
                }
                let scanner = Scanner.init(string: hexString)
                var scanned: UInt32 = 0
                if !scanner.scanHexInt32(&scanned) {
                        Log.def(logErrorMessage)
                        return nil
                }
                let number = Int(scanned)
                if nvram.getBootOption(number) == nil  {
                        Log.def(logErrorMessage)
                        return nil
                }
                Log.info("boot number from boot string returned: %{public}X", number)
                return Int(number)
        }
        
        /*
         *  Helper: Parse integer to Boot####, doesn't check if variable exists
         */
        
        func bootStringFromBoot(number: Int) -> String {
                let string = "Boot\(String(format:"%04X", number))"
                Log.info("boot string from boot number returned: %{public}@", string)
                return string
        }
        
        /*
         *  Helper: Array to BootOrder data
         */
        
        func bootOrderData(from bootOrder: [UInt16]) -> Data {
                var data = Data.init()
                for var bootNumber in bootOrder {
                        data.append(UnsafeBufferPointer(start: &bootNumber, count: 1))
                }
                return data
        }
        
}


