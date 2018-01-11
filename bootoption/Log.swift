/*
 * File: Log.swift
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
import os.log

struct Log {
        
        static func info(_ message: StaticString, _ arg: CVarArg = "") {
                if #available(OSX 10.12, *) {
                        os_log(message, log: .default, type: .info, arg)
                } else {
                        //
                }
        }
        
        static func def(_ message: StaticString, _ arg: CVarArg = "") {
                if #available(OSX 10.12, *) {
                        os_log(message, log: .default, type: .default, arg)
                } else {
                        //
                }
        }
        
        static func error(_ message: StaticString, _ arg: CVarArg = "") {
                if #available(OSX 10.12, *) {
                        os_log(message, log: .default, type: .error, arg)
                } else {
                        //
                }
        }
}
