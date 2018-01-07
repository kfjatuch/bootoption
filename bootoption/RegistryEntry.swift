/*
 * File: RegistryEntry.swift
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
import IOKit

class RegistryEntry {
        
        var registryEntry = io_registry_entry_t.init()
        
        enum typeId {
                static let number = CFNumberGetTypeID()
                static let string = CFStringGetTypeID()
                static let data = CFDataGetTypeID()
                static let bool = CFBooleanGetTypeID()
        }
        
        init(fromPath path: String) {
                registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, path)
                guard registryEntry != 0 else {
                        fatalError("RegistryEntry: Error getting registry entry from path")
                }
        }
  
        /*
         *  Get properties
         */
        
        private func getValue(forProperty key: String, type: CFTypeID) -> Any? {
                if let value: CFTypeRef = IORegistryEntryCreateCFProperty(registryEntry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() {
                        let valueType = CFGetTypeID(value)
                        guard valueType == type else {
                                let expected = CFCopyTypeIDDescription(type) as String
                                let instead = CFCopyTypeIDDescription(valueType) as String
                                print("RegistryEntry value(key:type:): Expected '\(expected)' type for '\(key)' Instead: '\(instead)'")
                                return nil
                        }
                        return value
                }
                return nil
        }

        func getIntValue(forProperty key: String) -> Int? {
                guard let int = getValue(forProperty: key, type: typeId.number) as? Int else {
                        return nil
                }
                return int
        }
        
        func getStringValue(forProperty key: String) -> String? {
                guard let string = getValue(forProperty: key, type: typeId.string) as? String else {
                        return nil
                }
                return string
        }
        
        func getDataValue(forProperty key: String) -> Data? {
                guard let data = getValue(forProperty: key, type: typeId.data) as? Data else {
                        return nil
                }
                return data
        }
        
        func getBoolValue(forProperty key: String) -> Bool? {
                guard let bool = getValue(forProperty: key, type: typeId.bool) as? Bool else {
                        return nil
                }
                return bool
        }
        
        /*
         *  Set properties
         */
        
        private func setValue(forProperty key: String, value: Any, type: CFTypeID) -> Bool {
                var result: kern_return_t
                switch type {
                case typeId.number:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFNumber)
                case typeId.string:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFString)
                case typeId.data:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFData)
                case typeId.bool:
                        result = IORegistryEntrySetCFProperty(registryEntry, key as CFString, value as! CFBoolean)
                default:
                        result = -1
                        print("No provision for provided type")
                }
                if result == KERN_SUCCESS {
                        return true
                }
                return false
        }
        
        func setIntValue(forProperty key: String, value: Int) -> Bool {
                let type = typeId.number
                if setValue(forProperty: key, value: value as CFNumber, type: type) {
                        return true
                }
                return false
        }
        
        func setStringValue(forProperty key: String, value: String) -> Bool {
                let type = typeId.string
                if setValue(forProperty: key, value: value as CFString, type: type) {
                        return true
                }
                return false
        }
        
        func setDataValue(forProperty key: String, value: Data) -> Bool {
                let type = typeId.data
                if setValue(forProperty: key, value: value as CFData, type: type) {
                        return true
                }
                return false
        }
        
        func setBoolValue(forKey key: String, value: Bool) -> Bool {
                let type = typeId.bool
                if setValue(forProperty: key, value: value as CFBoolean, type: type) {
                        return true
                }
                return false
                
        }
        
}
