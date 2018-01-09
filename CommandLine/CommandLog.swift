/*
 * CommandLog.swift
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import os.log

struct CommandLog {
        
        static func info(_ message: StaticString, args: CVarArg = "") {
                if #available(OSX 10.12, *) {
                        os_log(message, log: .default, type: .info, args)
                } else {
                        //
                }
        }
        
        static func def(_ message: StaticString, args: CVarArg = "") {
                if #available(OSX 10.12, *) {
                        os_log(message, log: .default, type: .default, args)
                } else {
                        //
                }
        }
        
        static func error(_ message: StaticString, args: CVarArg = "") {
                if #available(OSX 10.12, *) {
                        os_log(message, log: .default, type: .error, args)
                } else {
                        //
                }
        }
        
        static func kern_return_t(result: kern_return_t) {
                if #available(OSX 10.12, *) {
                        os_log("kern_return: %X", log: .default, type: .error, result as CVarArg)
                } else {
                        //
                }
        }
}
