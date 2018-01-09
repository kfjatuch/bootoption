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
                        print("Error: Failed to get registry entry from path")
                        Log.error("RegistryEntry: Error getting registry entry from path")
                        exit(EX_IOERR)
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
                                Log.error("CFType mismatch")
                                return nil
                        }
                        return value
                }
                return nil
        }

        func getIntValue(forProperty key: String) -> Int? {
                guard let int = self.getValue(forProperty: key, type: typeId.number) as? Int else {
                        return nil
                }
                return int
        }
        
        func getStringValue(forProperty key: String) -> String? {
                guard let string = self.getValue(forProperty: key, type: typeId.string) as? String else {
                        return nil
                }
                return string
        }
        
        func getDataValue(forProperty key: String) -> Data? {
                guard let data = self.getValue(forProperty: key, type: typeId.data) as? Data else {
                        return nil
                }
                return data
        }
        
        func getBoolValue(forProperty key: String) -> Bool? {
                guard let bool = self.getValue(forProperty: key, type: typeId.bool) as? Bool else {
                        return nil
                }
                return bool
        }
        
        /*
         *  Set properties
         */
        
        private func setValue(forProperty key: String, value: Any, type: CFTypeID) -> kern_return_t {
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
                        Log.error("No provision for provided type")
                }
                if result != KERN_SUCCESS {
                        Log.error("Error setting value for property (%{public}X)", args: Int(result))
                }
                return result
        }
        
        func setIntValue(forProperty key: String, value: Int) -> kern_return_t {
                let type = typeId.number
                let result = self.setValue(forProperty: key, value: value as CFNumber, type: type)
                return result
        }
        
        func setStringValue(forProperty key: String, value: String) -> kern_return_t {
                let type = typeId.string
                let result = self.setValue(forProperty: key, value: value as CFString, type: type)
                return result
        }
        
        func setDataValue(forProperty key: String, value: Data) -> kern_return_t {
                let type = typeId.data
                let result = self.setValue(forProperty: key, value: value as CFData, type: type)
                return result
        }
        
        func setBoolValue(forKey key: String, value: Bool) -> kern_return_t {
                let type = typeId.bool
                let result = self.setValue(forProperty: key, value: value as CFBoolean, type: type)
                return result
                
        }
        
}
