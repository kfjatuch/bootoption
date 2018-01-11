/*
 * File: Nvram.swift
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

class Nvram {
        
        let ioNvramForceSyncNowPropertyKey = "IONVRAM-FORCESYNCNOW-PROPERTY"
        let efiGlobalGuid:String = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C"
        let options = RegistryEntry(fromPath: "IODeviceTree:/options")
        
        func nameWithGuid(_ name: String) -> String {
                return "\(efiGlobalGuid):\(name)"
        }
        
        /*
         *  Delete variable: ask kernel to delete a variable by setting kIONVRAMDeletePropertyKey
         */
        
        func deleteVariable(key: String) {
                let _ = self.options.setStringValue(forProperty: kIONVRAMDeletePropertyKey, value: key)
        }

        func nvramSyncNow(withNamedVariable key: String, useForceSync: Bool = true) -> kern_return_t {
                var result: kern_return_t
                if (useForceSync) {
                        result = self.options.setStringValue(forProperty: ioNvramForceSyncNowPropertyKey, value: key)
                } else {
                        result = self.options.setStringValue(forProperty: kIONVRAMSyncNowPropertyKey, value: key)
                }
                if result != KERN_SUCCESS {
                        Log.def("Error syncing %{public}@", key)
                }
                return result
        }
        
}
