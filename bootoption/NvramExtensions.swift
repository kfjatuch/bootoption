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
     
        var bootOrderArray: [BootNumber] {
                if let savedBootOrder = self.savedBootOrder {
                        if savedBootOrder.isEmpty {
                                Debug.log("savedBootOrderArray was []", type: .default)
                        }
                        return savedBootOrder
                }
                var bootOrder: [BootNumber] = Array()
                if var bootOrderData = bootOrderData {
                        if !bootOrderData.isEmpty {
                                let size: Int = bootOrderData.count
                                for _ in 1 ... (size / MemoryLayout<BootNumber>.size) {
                                        let bootNumber: BootNumber = bootOrderData.remove16()
                                        bootOrder.append(bootNumber)
                                }
                        }
                }
                savedBootOrder = bootOrder
                if bootOrder.isEmpty {
                        Debug.log("bootOrderArray was computed to be []", type: .default)
                }
                return bootOrder
        }
        
        var bootCurrent: BootNumber?  {
                if var data = options.getDataValue(forProperty: prependingGlobalGUID("BootCurrent")) {
                        return data.remove16()
                } else {
                        return nil
                }
        }
        
        var bootNext: BootNumber? {
                if var data = options.getDataValue(forProperty: prependingGlobalGUID("BootNext")) {
                        return data.remove16()
                } else {
                        return nil
                }
        }
        
        var timeout: UInt16? {
                if var data = options.getDataValue(forProperty: prependingGlobalGUID("Timeout")) {
                        return data.remove16()
                } else {
                        return nil
                }
        }
        
        var bootOrderData: Data? {
                return options.getDataValue(forProperty: prependingGlobalGUID("BootOrder"))
        }
        
        /* Functions for setting boot-related NVRAM variables */
        
        func setBootOrder(data: Data) -> Bool {

                error = options.setDataValue(forProperty: prependingGlobalGUID("BootOrder"), value: data)
                guard error == KERN_SUCCESS else {
                        Debug.log("Error setting BootOrder (%@)", type: .error, argsList: error)
                        return false
                }
                error = syncNow(withNamedVariable: prependingGlobalGUID("BootOrder"))
                guard error == KERN_SUCCESS else {
                        Debug.log("Error syncing BootOrder (%@)", type: .error, argsList: error)
                        return false
                }
                Debug.log("Asked the kernel to set a new BootOrder", type: .info)
                return true
        }
        
        func setTimeout(seconds: Int) -> Bool {
                let timeoutValue = UInt16(seconds)
                return setTimeout(timeoutValue)
        }

        func setTimeout(_ timeoutValue: UInt16) -> Bool {
                error = options.setDataValue(forProperty: prependingGlobalGUID("Timeout"), value: timeoutValue.data)
                guard error == KERN_SUCCESS else {
                        Debug.log("Error setting Timeout (%@)", type: .error, argsList: error)
                        return false
                }
                error = syncNow(withNamedVariable: prependingGlobalGUID("Timeout"))
                guard error == KERN_SUCCESS else {
                        Debug.log("Error syncing Timeout (%@)", type: .error, argsList: error)
                        return false
                }
                Debug.log("Asked the kernel to set a new Timeout", type: .info)
                return true
        }
        
        func setBootNext(bootNumber: BootNumber?) -> Bool {
                if let nextBootNumber = bootNumber {
                        guard bootOptionData(nextBootNumber) != nil else {
                                Debug.log("Couldn't get %@ data, cancelling set boot next", type: .error, argsList: nextBootNumber.variableName)
                                return false
                        }
                        let bootNextValue = nextBootNumber
                        error = options.setDataValue(forProperty: prependingGlobalGUID("BootNext"), value: bootNextValue.data)
                        guard error == KERN_SUCCESS else {
                                Debug.log("Error setting BootNext (%@)", type: .error, argsList: error)
                                return false
                        }
                        error = syncNow(withNamedVariable: prependingGlobalGUID("BootNext"))
                        guard error == KERN_SUCCESS else {
                                Debug.log("Error syncing BootNext (%@)", type: .error, argsList: error)
                                return false
                        }
                        Debug.log("Asked the kernel to set BootNext", type: .info)
                        return true
                }
                return false
        }

        @discardableResult func setBootOrder(adding bootNumber: BootNumber, atIndex index: Int = 0) -> Bool {
                guard bootOptionData(bootNumber) != nil else {
                        Debug.log("Couldn't get %@ data, cancelling add to boot order", type: .error, argsList: bootNumber.variableName)
                        return false
                }
                if let newBootOrder: [BootNumber] = newBootOrderArray(adding: bootNumber, atIndex: index) {
                        if setBootOrder(data: newBootOrderData(fromArray: newBootOrder)) {
                                return true
                        }
                }
                return false
        }
        
        @discardableResult func setBootOrder(array: [BootNumber]) -> Bool {
                if setBootOrder(data: newBootOrderData(fromArray: array)) {
                        return true
                }
                return false                
        }
        
        func setNewEfiLoadOption(data: Data, addingToBootOrder: Bool) -> BootNumber? {
                guard let newBootNumber: BootNumber = discoverEmptyBootNumber() else {
                        return nil
                }
                error = options.setDataValue(forProperty: newBootNumber.variableNameWithGuid, value: data)
                guard error == KERN_SUCCESS else {
                        Debug.log("Error setting %@ (%@)", type: .error, argsList: newBootNumber.variableName, error)
                        return nil
                }
                error = syncNow(withNamedVariable: newBootNumber.variableNameWithGuid)
                guard error == KERN_SUCCESS else {
                        Debug.log("Error syncing %@ (%@)", type: .error, argsList: newBootNumber.variableName, error)
                        return nil
                }
                setBootOrder(adding: newBootNumber, atIndex: 0)
                Debug.log("Asked the kernel to set %@", type: .info, argsList: newBootNumber.variableName)
                return newBootNumber
        }
        
        func setEfiLoadOption(option: EfiLoadOption) -> Bool {
                if let bootNumber: BootNumber = option.bootNumber {
                        error = options.setDataValue(forProperty: bootNumber.variableNameWithGuid, value: option.data)
                        guard error == KERN_SUCCESS else {
                                Debug.log("Error setting %@ (%@)", type: .error, argsList: bootNumber.variableName, error)
                                return false
                        }
                        error = syncNow(withNamedVariable: bootNumber.variableNameWithGuid)
                        guard error == KERN_SUCCESS else {
                                Debug.log("Error syncing %@ (%@)", type: .error, argsList: bootNumber.variableName, error)
                                return false
                        }
                        Debug.log("Asked the kernel to set %@", type: .info, argsList: bootNumber.variableName)
                        return true
                }
                Debug.log("bootNumber is nil", type: .error)
                return false
        }
        
        @discardableResult func setRebootToFirmwareUI() -> Bool {
                var osIndicationsValue: UInt64
                if var data: Data = options.getDataValue(forProperty: prependingGlobalGUID("OsIndications")) {
                        osIndicationsValue = data.remove64()
                        osIndicationsValue = osIndicationsValue | 0x1
                } else {
                        osIndicationsValue = 0x1
                }
                error = options.setDataValue(forProperty: prependingGlobalGUID("OsIndications"), value: osIndicationsValue.data)
                guard error == KERN_SUCCESS else {
                        Debug.log("Error setting OsIndications (%@)", type: .error, argsList: error)
                        return false
                }
                error = syncNow(withNamedVariable: prependingGlobalGUID("OsIndications"))
                guard error == KERN_SUCCESS else {
                        Debug.log("Error syncing OsIndications (%@)", type: .error, argsList: error)
                        return false
                }
                return true
        }       
        
        /* Functions for deleting boot-related NVRAM variables */
        
        func deleteBootOption(_ bootNumber: BootNumber) {
                deleteVariable(key: bootNumber.variableNameWithGuid)
                Debug.log("Asked the kernel to delete %@", type: .info, argsList: bootNumber.variableName)
        }
        
        func deleteTimeout() {
                deleteVariable(key: prependingGlobalGUID("Timeout"))
                Debug.log("Asked the kernel to delete Timeout", type: .info)
        }
        
        func deleteBootNext() {
                deleteVariable(key: prependingGlobalGUID("BootNext"))
                Debug.log("Asked the kernel to delete BootNext", type: .info)
        }
        
        func deleteBootOrder() {
                deleteVariable(key: prependingGlobalGUID("BootOrder"))
                Debug.log("Asked the kernel to delete BootOrder", type: .info)
        }
        
        /* Return load option data given a boot number */
        
        func bootOptionData(_ number: BootNumber) -> Data? {
                return options.getDataValue(forProperty: number.variableNameWithGuid)
        }
        
        var emuVariableUefiPresent: Bool {
                return options.getDataValue(forProperty: "EmuVariableUefiPresent") != nil
        }
        
}
