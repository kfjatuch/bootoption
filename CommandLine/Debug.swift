/*
 * Debug.swift
 * Copyright © 2017-2018 vulgo
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

struct Debug {
        static var infoCode = ""
        static var errorCode = ""
        static var resetCode = ""
        
        static func fault(_ errorMessage: String, file: String = #file, function: String = #function) -> Never {
                if DEBUG {
                        Debug.log(errorMessage, type: .fault, file: file, function: function)
                        print(errorMessage, to: &standardError)
                } else {
                        print(errorMessage, to: &standardError)
                }
                exit(1)
        }
        
        static func terminate(_ status: Int32) -> Never {
                exit(status)
        }
        
        static func log(_ message: String, type: OSLogType, file: String = #file, function: String = #function, argsList: Any ...) {
                
                if !DEBUG {
                        return
                }
                
                var cVarArgArray: [CVarArg] = []
                for arg in argsList {
                        switch arg {
                        case let data as Data:
                                cVarArgArray.append(data.debugString as CVarArg)
                        default:
                                cVarArgArray.append(String(describing: arg) as CVarArg)
                        }
                }
                
                var msg: String = ""
                
                switch type {
                case .debug:
                        msg += "\(infoCode)[Debug]"
                case .info:
                        msg += "\(infoCode)[Info]"
                case .error:
                        msg += "\(errorCode)[ERROR]"
                case .fault:
                        msg += "\(errorCode)[FAULT]"
                default:
                        msg += "\(infoCode)[Default]"
                }
                
                msg += " \(NSString(string: file).lastPathComponent) • \(function) • \(String(format: message, arguments: cVarArgArray))\(resetCode)"
                print(msg, to: &standardError)
        }
}
