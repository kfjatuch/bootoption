/*
 * File: NvramExtensions.swift
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

extension Nvram {
        
        /*
         *  GET functions
         */
        
        func getBootOrderArray() -> [UInt16]? {
                if savedBootOrder != nil {
                        return savedBootOrder
                }
                var bootOrder: [UInt16] = Array()
                if var bootOrderBuffer: Data = getBootOrder() {
                        let bootOrderBufferSize: Int = bootOrderBuffer.count
                        for _ in 1 ... (bootOrderBufferSize / 2) {
                                let optionNumber: UInt16 = bootOrderBuffer.remove16()
                                bootOrder.append(optionNumber)
                        }
                }
                if !bootOrder.isEmpty {
                        savedBootOrder = bootOrder
                        return savedBootOrder
                } else {
                        return nil
                }
        }
        
        func getBootOption(_ number: Int) -> Data? {
                let name: String = bootStringFromBoot(number: number)
                return options.getDataValue(forProperty: nameWithGuid(name))
        }
        
        func getBootCurrent() -> Data? {
                return options.getDataValue(forProperty: nameWithGuid("BootCurrent"))
        }
        
        func getBootNext() -> Data? {
                return options.getDataValue(forProperty: nameWithGuid("BootNext"))
        }
        
        func getTimeout() -> Data? {
                return options.getDataValue(forProperty: nameWithGuid("Timeout"))
        }
        
        func getBootOrder() -> Data? {
                return options.getDataValue(forProperty: nameWithGuid("BootOrder"))
        }
        
        
        
        
        
        /*
         *  SET and CREATE functions
         */
        
        func setBootOrder(data: Data) -> Bool {
                let set = options.setDataValue(forProperty: nameWithGuid("BootOrder"), value: data)
                let sync = nvramSyncNow(withNamedVariable: nameWithGuid("BootOrder"))
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
                let set = options.setDataValue(forProperty: nameWithGuid("Timeout"), value: data)
                let sync = nvramSyncNow(withNamedVariable: nameWithGuid("Timeout"))
                if set + sync != 0 {
                        return false
                }
                Log.info("Asked the kernel to set a new Timeout")
                return true
        }
        
        func setBootNext(number: Int?) -> Bool {
                let bootNumber: Int = number ?? -1
                guard getBootOption(bootNumber) != nil else {
                        Log.log("Couldn't get %{public}@ data, cancelling add to boot order", bootStringFromBoot(number: bootNumber))
                        return false
                }
                var bootNext = UInt16(bootNumber)
                var data = Data.init()
                data.append(UnsafeBufferPointer(start: &bootNext, count: 1))
                let set = options.setDataValue(forProperty: nameWithGuid("BootNext"), value: data)
                let sync = nvramSyncNow(withNamedVariable: nameWithGuid("BootNext"))
                if set + sync != 0 {
                        return false
                }
                Log.info("Asked the kernel to set BootNext")
                return true
        }

        @discardableResult func addToBootOrder(_ number: Int, atIndex index: Int = 0) -> Bool {
                let name = bootStringFromBoot(number: number)
                guard getBootOption(number) != nil else {
                        Log.log("Couldn't get %{public}@ data, cancelling add to boot order", name)
                        return false
                }
                guard var bootOrder: [UInt16] = getBootOrderArray() else {
                        Log.log("Error getting BootOrder, cancelling add to boot order")
                        return false
                }
                if bootOrder.indices.contains(index) {
                        Log.info("Inserted to boot order at index %{public}@", index)
                        bootOrder.insert(UInt16(number), at: index)
                } else {
                        Log.log("Index out of range, appending to boot order instead")
                        bootOrder.append(UInt16(number))
                }
                let data = bootOrderData(fromArray: bootOrder)
                if !setBootOrder(data: data) {
                        return false
                }
                return true
        }
        
        func createNewAndAddToBootOrder(withData data: Data) -> Int? {
                guard let bootNumber: Int = discoverEmptyBootNumber() else {
                        return nil
                }
                let name: String = bootStringFromBoot(number: bootNumber)
                let set = options.setDataValue(forProperty: nameWithGuid(name), value: data)
                let sync = nvramSyncNow(withNamedVariable: nameWithGuid(name))
                if set + sync != 0 {
                        Log.log("Create new boot option returned nil")
                        return nil
                }
                addToBootOrder(bootNumber, atIndex: 0)
                Log.info("Asked the kernel to set %{public}@", name)
                return bootNumber
        }
        
        func setOption(option: EfiLoadOption) -> Bool {
                if let bootNumber: Int = option.bootNumber {
                        let name: String = bootStringFromBoot(number: bootNumber)
                        let set = options.setDataValue(forProperty: nameWithGuid(name), value: option.data)
                        let sync = nvramSyncNow(withNamedVariable: nameWithGuid(name))
                        if set + sync != 0 {
                                Log.log("Error setting and syncing %{public}@", name)
                                return false
                        }
                        Log.info("Asked the kernel to set %{public}@", name)
                        return true
                }
                Log.log("Error setting and syncing boot option")
                return false
        }
        
        
        
        
        
        /*
         *  DELETE and REMOVE functions
         */
        
        func deleteBootOption(_ number: Int) {
                let name: String = bootStringFromBoot(number: number)
                deleteVariable(key: nameWithGuid(name))
                Log.info("Asked the kernel to delete %{public}@", name)
                // to do: needs to be read back to confirm success
        }
        
        func deleteTimeout() {
                deleteVariable(key: nameWithGuid("Timeout"))
                Log.info("Asked the kernel to delete Timeout")
        }
        
        func deleteBootNext() {
                deleteVariable(key: nameWithGuid("BootNext"))
                Log.info("Asked the kernel to delete BootNext")
        }
        
        func removeFromBootOrder(number bootNumber: Int) -> [UInt16]? {
                var bootOrder = getBootOrderArray()
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
                Log.log("Remove from boot order returned nil")
                return nil
        }
        
        
        
        
        
        /*
         *  Helper: Return an unused boot option number to write to
         */
        
        func discoverEmptyBootNumber(leavingSpace: Bool = false) -> Int? {
                var counter: Int = 0
                for number: Int in 0x0 ..< 0xFF {
                        if let _: Data = getBootOption(number) {
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
                Log.log("Empty option discovery failed")
                return nil
        }
        
        /*
         *  Helper: Read integer value from (user provided) Boot#### string
         */
        
        func bootNumberFromBoot(string: String) -> Int? {
                let logErrorMessage: StaticString = "Parsing user provided Boot#### failed"
                var mutableString = string.uppercased()
                mutableString = mutableString.replacingOccurrences(of: "0X", with: "")
                mutableString = mutableString.replacingOccurrences(of: "BOOT", with: "")
                if mutableString.containsNonHexCharacters() || mutableString.characters.count > 4 {
                        Log.log(logErrorMessage)
                        return nil
                }
                let scanner = Scanner.init(string: mutableString)
                var scanned: UInt32 = 0
                if !scanner.scanHexInt32(&scanned) {
                        Log.log(logErrorMessage)
                        return nil
                }
                let number = Int(scanned)
                if nvram.getBootOption(number) == nil  {
                        Log.log(logErrorMessage)
                        return nil
                }
                Log.debug("boot number from boot string returned: %{public}X", number)
                return Int(number)
        }
        
        /*
         *  Helper: Parse integer to Boot####, doesn't check if variable exists
         */
        
        func bootStringFromBoot(number: Int) -> String {
                let string = "Boot\(String(format:"%04X", number))"
                Log.debug("boot string from boot number returned: %{public}@", string)
                return string
        }
        
        /*
         *  Helper: Array to BootOrder data
         */
        
        func bootOrderData(fromArray bootOrder: [UInt16]) -> Data {
                var data = Data.init()
                for var bootNumber in bootOrder {
                        data.append(UnsafeBufferPointer(start: &bootNumber, count: 1))
                }
                return data
        }
        
        /*
         *  Helper: Position in boot order
         */
        
        func positionInBootOrder(number: Int) -> Int? {
                let bootOrder = getBootOrderArray()
                let order: Int? = bootOrder?.index(of: UInt16(number))
                return order
        }
        
}


