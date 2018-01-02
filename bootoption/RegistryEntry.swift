/*
 * File: RegistryEntry.swift
 *
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
        
        var registryEntry = io_registry_entry_t.init()
        
        init(fromPath path: String) {
                registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, path)
                guard registryEntry != 0 else {
                        fatalError("RegistryEntry: Error getting registry entry from path")
                }
        }
        
        private func value(fromKey key: String, type: CFTypeID) -> Any? {
                let registryKey = key as CFString
                let registryValue:Unmanaged<CFTypeRef>? = (IORegistryEntryCreateCFProperty(registryEntry, registryKey , kCFAllocatorDefault, 0))
                guard (registryValue != nil) else {
                        return nil
                }
                let value = registryValue!.takeRetainedValue()
                let valueType = CFGetTypeID(value)
                guard valueType == type else {
                        print("RegistryEntry value(key:type:): Expected '\(CFCopyTypeIDDescription(type))' type for '\(key)' Instead: '\(CFCopyTypeIDDescription(valueType))'")
                        return nil
                }
                return value
        }
        
        func int(fromKey key: String) -> Int? {
                guard let int = value(fromKey: key, type: CFNumberGetTypeID()) as? Int else {
                        return nil
                }
                return int
        }
        
        func string(fromKey key: String) -> String? {
                guard let string = value(fromKey: key, type: CFStringGetTypeID()) as? String else {
                        return nil
                }
                return string
        }
        
}
