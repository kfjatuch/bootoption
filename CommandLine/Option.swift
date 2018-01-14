/*
 * Option.swift
 * Copyright (c) 2014 Ben Gollmer.
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

/*
 * The base class for a command-line option.
 */

class Option {
        
        let shortFlag: String?
        let longFlag: String?
        let required: Int
        let helpMessage: String
        let precludes: String
        
        /* True if the option was set when parsing command-line arguments */
        var wasSet: Bool {
                return false
        }
        
        var claimedValues: Int {
                return 0
        }
        
        var shortDescription: String {
                if self.shortFlag != nil {
                        return String("\(CommandLine.shortPrefix)\(self.shortFlag!)")
                } else if longFlag != nil {
                        return String("\(CommandLine.longPrefix)\(self.longFlag!)")
                } else {
                        return String("")
                }
        }
        
        var logDescription: String {
                if self.longFlag != nil {
                        return self.longFlag!
                } else if self.shortFlag != nil {
                        return self.shortFlag!
                } else {
                        return String("")
                }
        }
        
        var optionDescription: String {
                var string: String = ""
                if self.shortFlag != nil && self.longFlag != nil {
                        string.append("\(CommandLine.shortPrefix)\(self.shortFlag!)")
                        string.append("  ")
                        string.append("\(CommandLine.longPrefix)\(self.longFlag!)")
                } else if longFlag != nil {
                        string.append("\(CommandLine.longPrefix)\(self.longFlag!)")
                } else if shortFlag != nil {
                        string.append("\(CommandLine.shortPrefix)\(self.shortFlag!)")
                }
                return string
        }
        
        internal init(_ shortFlag: String?, _ longFlag: String?, _ required: Int, _ helpMessage: String, _ precludes: String) {
                if shortFlag != nil {
                        assert(shortFlag!.characters.count == 1, "Short flag must be a single character")
                        assert(Int(shortFlag!) == nil && shortFlag!.toDouble() == nil, "Short flag cannot be a numeric value")
                }
                if longFlag != nil {
                        assert(Int(longFlag!) == nil && longFlag!.toDouble() == nil, "Long flag cannot be a numeric value")
                }
                self.shortFlag = shortFlag
                self.longFlag = longFlag
                self.helpMessage = helpMessage
                self.required = required
                self.precludes = precludes
        }
        
        /* Initializes a new Option that has both long and short flags. */
        convenience init(shortFlag: String, longFlag: String, required: Int = 0, helpMessage: String, precludes: String = "") {
                self.init(shortFlag, longFlag, required, helpMessage, precludes)
        }
        
        /* Initializes a new Option that has only a short flag. */
        convenience init(shortFlag: String, required: Int = 0, helpMessage: String, precludes: String = "") {
                self.init(shortFlag, nil, required, helpMessage, precludes)
        }
        
        /* Initializes a new Option that has only a long flag. */
        convenience init(longFlag: String, required: Int = 0, helpMessage: String, precludes: String = "") {
                self.init(nil, longFlag, required, helpMessage, precludes)
        }
        
        func flagMatch(_ flag: String) -> Bool {
                return flag == self.shortFlag || flag == self.longFlag
        }
        
        func setValue(_ values: [String]) -> Bool {
                return false
        }
}

/*
 *  A boolean option. The presence of either the short or long flag will set the value to true;
 *  absence of the flag(s) is equivalent to false.
 */

class BoolOption: Option {
        
        var value: Bool = false
        
        override var wasSet: Bool {
                return self.value
        }
        
        override func setValue(_ values: [String]) -> Bool {
                self.value = true
                return true
        }
}

/*  An option that accepts a positive or negative integer value. */

class IntOption: Option {
        
        var value: Int?
        
        override var wasSet: Bool {
                return self.value != nil
        }
        
        override var claimedValues: Int {
                return self.value != nil ? 1 : 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                
                if values.count == 0 {
                        return false
                }
                
                if let val = Int(values[0]) {
                        self.value = val
                        return true
                }
                
                return false
        }
}

/*
 *  An option that represents an integer counter. Each time the short or long flag is found
 *  on the command-line, the counter will be incremented.
 */

class CounterOption: Option {
        
        var value: Int = 0
        
        override var wasSet: Bool {
                return self.value > 0
        }
        
        func reset() {
                self.value = 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                self.value += 1
                return true
        }
}

/* An option that accepts a positive or negative floating-point value. */

class DoubleOption: Option {
        
        var value: Double?
        
        override var wasSet: Bool {
                return self.value != nil
        }
        
        override var claimedValues: Int {
                return self.value != nil ? 1 : 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                
                if values.count == 0 {
                        return false
                }
                
                if let val = values[0].toDouble() {
                        self.value = val
                        return true
                }
                
                return false
        }
}

/* An option that accepts a string value. */

class StringOption: Option {
        
        var value: String? = nil
        
        override var wasSet: Bool {
                return self.value != nil
        }
        
        override var claimedValues: Int {
                return self.value != nil ? 1 : 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                
                if values.count == 0 {
                        return false
                }
                
                self.value = values[0]
                return true
        }
}

/* An option that accepts one or more string values. */

class MultiStringOption: Option {
        
        var value: [String]?
        
        override var wasSet: Bool {
                return self.value != nil
        }
        
        override var claimedValues: Int {
                
                if let v = self.value {
                        return v.count
                }
                
                return 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                
                if values.count == 0 {
                        return false
                }
                
                self.value = values
                return true
        }
}

/* An option that represents an enum value. */

class EnumOption<T:RawRepresentable>: Option where T.RawValue == String {
        
        var value: T?
        
        override var wasSet: Bool {
                return self.value != nil
        }
        
        override var claimedValues: Int {
                return self.value != nil ? 1 : 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                
                if values.count == 0 {
                        return false
                }
                
                if let v = T(rawValue: values[0]) {
                        self.value = v
                        
                        return true
                }
                
                return false
        }
}
