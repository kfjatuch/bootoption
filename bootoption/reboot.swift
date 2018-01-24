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
 *  Function for verb: reboot
 */

func reboot() {
        
        /* Check root */
        
        if commandLine.userName != "root" {
                Log.logExit(EX_NOPERM, "Only root can reboot to firmware settings.")
        }
        
        /* Set OsIndications */
        
        var status = EX_OK
        if !nvram.setRebootToFirmwareUI() {
                status = EX_UNAVAILABLE
        }
        
        /* Send restart event */
        
        let myAppleScript = "tell application \"System Events\" to restart"
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScript) {
                scriptObject.executeAndReturnError(&error)
        }
        if error != nil {
                print(error as Any)
                status = EX_UNAVAILABLE
        }
        Log.logExit(status)
}

