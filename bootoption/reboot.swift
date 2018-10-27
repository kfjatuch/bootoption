/*
 * File: reboot.swift
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

/*
 *  Function for command: reboot
 */

func reboot() {
        
        /* Check root */
        
        if NSUserName() != "root" {
                Debug.log("Only root can reboot to firmware settings.", type: .error)
                Debug.fault("Permission denied")
        }
        
        /* Set OsIndications */
        
        var status = EX_OK
        if !Nvram.shared.setRebootToFirmwareUI() {
                status = EX_UNAVAILABLE
        }
        
        /* Send restart event */
        
        let myAppleScript = "tell application \"System Events\" to restart"
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScript) {
                scriptObject.executeAndReturnError(&error)
        }
        if error != nil {
                Debug.fault(String(describing: error))
        }
        Debug.terminate(status)
}

