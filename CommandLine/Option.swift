/*
 * Option.swift
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

/*
 * The base class for a command-line option.
 */

class Option {
        private let shortPrefix: String = "-"
        private let longPrefix: String = "--"
        let shortFlag: String?
        let longFlag: String?
        let required: Int
        let helpMessage: String?
        let invalidatesOthers: Set<Character>?
        
        /* True if the option was set when parsing command-line arguments */
        var wasSet: Bool {
                return false
        }
        
        var claimedValues: Int {
                return 0
        }
        
        var shortDescription: String {
                if shortFlag != nil {
                        return String("\(shortPrefix)\(shortFlag!)")
                } else if longFlag != nil {
                        return String("\(longPrefix)\(longFlag!)")
                } else {
                        return String("")
                }
        }
        
        var logDescription: String {
                if longFlag != nil {
                        return longFlag!
                } else if shortFlag != nil {
                        return shortFlag!
                } else {
                        return String("")
                }
        }
        
        var optionDescription: String {
                var string: String = ""
                if shortFlag != nil && longFlag != nil {
                        string.append("\(shortPrefix)\(shortFlag!)")
                        string.append("  ")
                        string.append("\(longPrefix)\(longFlag!)")
                } else if longFlag != nil {
                        string.append("    ")
                        string.append("\(longPrefix)\(longFlag!)")
                } else if shortFlag != nil {
                        string.append("\(shortPrefix)\(shortFlag!)")
                }
                return string
        }
        
        internal init(_ shortFlag: String?, _ longFlag: String?, _ required: Int, _ helpMessage: String?, _ invalidates: [Character]? = nil) {
                if shortFlag != nil {
                        assert(shortFlag!.count == 1, "Short flag must be a single character")
                        assert(Int(shortFlag!) == nil && shortFlag!.toDouble() == nil, "Short flag cannot be a numeric value")
                }
                if longFlag != nil {
                        assert(Int(longFlag!) == nil && longFlag!.toDouble() == nil, "Long flag cannot be a numeric value")
                }
                self.shortFlag = shortFlag
                self.longFlag = longFlag
                self.helpMessage = helpMessage
                self.required = required
                if let invalidates = invalidates {
                        self.invalidatesOthers = Set(invalidates)
                } else {
                        self.invalidatesOthers = nil
                }
        }
        
        /* Initializes a new Option that has both long and short flags. */
        convenience init(shortFlag: String, longFlag: String, required: Int = 0, helpMessage: String?, invalidates: Character ...) {
                self.init(shortFlag, longFlag, required, helpMessage, invalidates)
        }
        
        /* Initializes a new Option that has only a short flag. */
        convenience init(shortFlag: String, required: Int = 0, helpMessage: String?, invalidates: Character ...) {
                self.init(shortFlag, nil, required, helpMessage, invalidates)
        }
        
        /* Initializes a new Option that has only a long flag. */
        convenience init(longFlag: String, required: Int = 0, helpMessage: String?, invalidates: Character ...) {
                self.init(nil, longFlag, required, helpMessage, invalidates)
        }
        
        func stringMatches(_ test: Any) -> Bool {
                switch test {
                case let c as Character:
                        return String(c) == shortFlag || String(c) == longFlag
                case let str as String:
                        return str == shortFlag || str == longFlag
                default:
                        return false
                }                
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
                return value
        }
        
        override func setValue(_ values: [String]) -> Bool {
                value = true
                return true
        }
}

/*
 *  Option with an optional Bool value that is set with 1 | 0
 */

class BinaryOption: Option {
        var value: Bool? = nil
        
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
                
                if let val = Int(values[0]) {
                        switch val {
                        case 0:
                                value = false
                                return true
                        case 1:
                                value = true
                                return true
                        default:
                                return false
                        }
                }
                return false
        }
}

/*  An option that accepts a positive or negative integer value. */

class IntOption: Option {
        var value: Int?
        
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
                
                if let val = Int(values[0]) {
                        value = val
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
                return value > 0
        }
        
        func reset() {
                value = 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                value += 1
                return true
        }
}

/* An option that accepts a positive or negative floating-point value. */

class DoubleOption: Option {
        var value: Double?
        
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
                
                if let val = values[0].toDouble() {
                        value = val
                        return true
                }
                
                return false
        }
}

/* An option that accepts a string value. */

class StringOption: Option {
        var value: String? = nil
        
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
                
                value = values[0]
                return true
        }
}

/* An option that accepts a file system path */

class FilePathOption: Option {
        var value: String? = nil
        
        var fileExists: Bool {
                if let path = value {
                        return path == CommandLine.fileOperand ? true : FileManager.default.fileExists(atPath: path)
                } else {
                        return false
                }
        }
        
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
                
                value = values[0]
                return true
        }
}

/* An option that accepts a file system path for reading from */

class InputFilePathOption: FilePathOption {
        var fileHandle: FileHandle? {
                if value == nil {
                        return nil
                }
                switch value! {
                case CommandLine.fileOperand:
                        return FileHandle.init(fileDescriptor: FileHandle.standardInput.fileDescriptor, closeOnDealloc: true)
                default:
                        if let path = value {
                                let fileHandle = FileHandle.init(forReadingAtPath: path)
                                return fileHandle
                        } else {
                                return nil
                        }
                }
        }
        
        var data: Data? {
                var buffer: Data?
                if let fileHandle = fileHandle {
                        buffer = fileHandle.readDataToEndOfFile()
                        fileHandle.closeFile()
                }
                return buffer
        }
}

/* An option that accepts a file system path for writing to */

class OutputFilePathOption: FilePathOption {
        var fileHandle: FileHandle? {
                if value == nil {
                        return nil
                }
                switch value! {
                case CommandLine.fileOperand:
                        return FileHandle.init(fileDescriptor: FileHandle.standardOutput.fileDescriptor, closeOnDealloc: true)
                default:
                        if let path = value {
                                if !fileExists {
                                        guard FileManager.default.createFile(atPath: path, contents: nil, attributes: nil) else {
                                                Debug.fault("can't create file for writing at: \(path)")
                                        }
                                }
                                let fileHandle = FileHandle.init(forWritingAtPath: path)
                                return fileHandle
                        } else {
                                return nil
                        }
                }
        }
}


/* An option that accepts a string value or no value  */

class OptionalStringOption: Option {
        var value: String? = nil
        
        var setWithoutValue: Bool = false
        
        override var wasSet: Bool {
                if setWithoutValue || value != nil {
                        return true
                } else {
                        return false
                }
        }
        
        override var claimedValues: Int {
                return value != nil ? 1 : 0
        }
        
        override func setValue(_ values: [String]) -> Bool {
                
                if values.count == 0 {
                        setWithoutValue = true
                } else {
                        value = values[0]
                }
                return true
        }
}

/* An option that accepts one or more string values. */

class MultiStringOption: Option {
        var value: [String]?
        
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
                
                value = values
                return true
        }
}

/* An option that represents an enum value. */

class EnumOption<T:RawRepresentable>: Option where T.RawValue == String {
        var value: T?
        
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
                
                if let v = T(rawValue: values[0]) {
                        value = v
                        
                        return true
                }
                
                return false
        }
}
