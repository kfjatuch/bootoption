/*
 * BootMenuOptions.swift
 * Copyright © 2014 Ben Gollmer
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

class BootNumberOption: Option {
        var value: BootNumber? = nil
        
        override var wasSet: Bool {
                return value != nil
        }
        
        override var claimedValues: Int {
                return value != nil ? 1 : 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                
                if values.count == 0 {
                        return false
                }
                
                if let bootNumber = bootNumberFromString(values[0]) {
                        value = bootNumber
                        return true
                } else {
                        return false
                }
        }
}

class TimeoutOption: Option {
        var value: UInt16?
        
        override var wasSet: Bool {
                return value != nil
        }
        
        override var claimedValues: Int {
                return value != nil ? 1 : 0
        }
        
        override func setValue(_ values: [String]) -> Bool {                
                if values.count == 0 {
                        return false
                }
                
                if let val = UInt16(values[0]), val > 0, val < 65534 {
                        value = val
                        return true
                }
                
                return false
        }
}

class BootOrderArrayOption: Option {        
        var value: [BootNumber]?
        
        override var wasSet: Bool {
                return value != nil
        }
        
        override var claimedValues: Int {
                
                if let v = value {
                        return v.count
                }
                
                return 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                
                if values.count == 0 {
                        return false
                }
                
                var buffer: [BootNumber] = []
                
                for string in values {
                        guard let bootNumber = bootNumberFromString(string) else {
                                return false
                        }
                        guard !buffer.contains(bootNumber) else {
                                return false
                        }
                        buffer.append(bootNumber)

                }
                
                value = buffer
                return true
        }
}
