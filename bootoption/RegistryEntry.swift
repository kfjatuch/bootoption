/*
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
import IOKit

class RegistryEntry {
        
        var registryEntry:io_registry_entry_t = io_registry_entry_t.init()
        
        init(from: String) {
                registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, from)
                guard registryEntry != 0 else {
                        print("RegistryEntry: Error getting registry entry from path")
                        exit(1)
                }
        }
        
        private func valueFrom(key: String, type: CFTypeID) -> Any? {
                let registryKey:CFString = key as CFString
                let registryValue:Unmanaged<CFTypeRef>? = (IORegistryEntryCreateCFProperty(registryEntry, registryKey , kCFAllocatorDefault, 0))
                
                guard (registryValue != nil) else {
                        return nil
                }
                
                let value = registryValue!.takeRetainedValue()
                let valueType = CFGetTypeID(value)
                
                guard valueType == type else {
                        print("Error: valueFrom(): Expected '\(CFCopyTypeIDDescription(type))' type for '\(key)' Instead: '\(CFCopyTypeIDDescription(valueType))'")
                        return nil
                }
                
                return value
        }
        
        func dataFrom(key: String) -> Data? {
                
                guard let data:Data = valueFrom(key: key, type: CFDataGetTypeID() ) as? Data else {
                        return nil
                }
                
                return data
        }
        
        func intFrom(key: String) -> Int? {
                
                guard let int:Int = valueFrom(key: key, type: CFNumberGetTypeID()) as? Int else {
                        return nil
                }
                
                return int
        }
        
        func stringFrom(key: String) -> String? {
                
                guard let string:String = valueFrom(key: key, type: CFStringGetTypeID()) as? String else {
                        return nil
                }
                
                return string
        }
        
}

