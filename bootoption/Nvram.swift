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
        
        var savedBootOrder: [UInt16]?

        let efiGlobalGuid:String = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C"
        let options: RegistryEntry
        
        init() {
                if let options = RegistryEntry(fromPath: "IODeviceTree:/options") {
                        self.options = options
                } else {
                        print("Fatal: Failed to initialize NVRAM options")
                        Log.logExit(EX_UNAVAILABLE, "Fatal: Failed to initialize NVRAM options")
                }
        }
        
        func nameWithGuid(_ name: String) -> String {
                return "\(efiGlobalGuid):\(name)"
        }
        
        /*
         *  Delete variable: ask kernel to delete a variable by setting kIONVRAMDeletePropertyKey
         */
        
        func deleteVariable(key: String) {
                let _ = options.setStringValue(forProperty: kIONVRAMDeletePropertyKey, value: key)
        }

        func nvramSyncNow(withNamedVariable key: String) -> kern_return_t {
                var result: kern_return_t
                result = options.setStringValue(forProperty: kIONVRAMSyncNowPropertyKey, value: key)
                if result != KERN_SUCCESS {
                        Log.log("Error syncing %{public}@", key)
                }
                return result
        }
        
}
