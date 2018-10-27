/*
 * File: Nvram.swift
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
import IOKit

class Nvram {
        
        var error: kern_return_t = 0
        
        static let shared = Nvram()
        
        var savedBootOrder: [BootNumber]?

        let efiGlobalGuid: String = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C"
        let options: RegistryEntry
        
        init() {
                if let options = RegistryEntry(fromPath: "IODeviceTree:/options") {
                        self.options = options
                } else {
                        print("Fatal: Failed to initialize NVRAM options")
                        Debug.fault("Fatal: Failed to initialize NVRAM options")
                }
        }
        
        func prependingGlobalGUID(_ name: String) -> String {
                return "\(efiGlobalGuid):\(name)"
        }
        
        /* Delete variable: set kIONVRAMDeletePropertyKey */
        
        func deleteVariable(key: String) {
                let _ = options.setStringValue(forProperty: kIONVRAMDeletePropertyKey, value: key)
        }
        
        /* Sync hardware NVRAM: set kIONVRAMSyncNowPropertyKey */

        func syncNow(withNamedVariable name: String) -> kern_return_t {
                return options.setStringValue(forProperty: kIONVRAMSyncNowPropertyKey, value: name)
        }
        
}
