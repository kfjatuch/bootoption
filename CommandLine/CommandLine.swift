/*
 * CommandLine.swift
 * Copyright © 2014 Ben Gollmer.
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

class CommandLine {
        
        /* GNU-getopt-like constants */
        static let shortPrefix = "-"
        static let longPrefix = "--"
        static let stopParsing = "--"
        static let attached: Character = "="
        
        enum ParserStatus {
                case success
                case noInput
                case tooManyOptions
                case invalidInput(String)
                case invalidArgument(String)
                case invalidValueForOption(Option, [String])
                case missingRequiredOptions([Option])
                var description: String {
                        switch self {
                        case .success:
                                Log.info("Parse success")
                                return "OK"
                        case .noInput:
                                Log.info("Parse error: Nothing to parse")
                                return ""
                        case .tooManyOptions:
                                Log.error("Parse error: Too many options")
                                return "Some options preclude the use of others."
                        case let .invalidInput(string):
                                Log.info("Parse error: Invalid input %{public}@", string)
                                return "Invalid input: \(string)"
                        case let .invalidArgument(string):
                                Log.error("Parse error: Invalid argument %{public}@", string)
                                return "Invalid argument: \(string)"
                        case let .invalidValueForOption(option, values):
                                let string: String = values.joined(separator: " ")
                                Log.error("Parse error: Invalid value %{public}@", string)
                                return "Invalid value(s) for option \(option.shortDescription): \(string)"
                        case let .missingRequiredOptions(options):
                                var s: String = "s"
                                if options.count == 1 {
                                        s = ""
                                }
                                let mapped: Array = options.map { return $0.shortDescription }
                                let string: String = mapped.joined(separator: ", ")
                                Log.error("Parse error: Missing required options %{public}@", string)
                                return "Missing required option\(s): \(string)"
                        }
                }
                
        }
        
        var baseName = String()
        var userName: String?
        var format: ((String, CommandLine.style) -> String)?
        var rawArguments: [String]
        var options: [Option] = Array()
        var verbs: [Verb] = Array()
        var usedFlags: Set<String> {
                var flags = Set<String>(minimumCapacity: self.options.count * 2)
                for option in self.options {
                        for case let flag? in [option.shortFlag, option.longFlag] {
                                flags.insert(flag)
                        }
                }
                return flags
        }
        
        func verb() -> String? {
                if rawArguments.count != 0 {
                        let arg = rawArguments.removeFirst()
                        return arg
                } else {
                        return nil
                }
        }


        /*
         *  init
         */
        
        init(invocationHelpMessage: String = "[options]", version: String = "1.0", programName: String = "", copyright: String = "", license: String = "", format formatUser: ((String, CommandLine.style) -> String)? = nil) {
                var args = Swift.CommandLine.arguments
                args.removeFirst()
                self.baseName = NSString(string: Swift.CommandLine.arguments[0]).lastPathComponent as String
                self.rawArguments = args
                self.invocationHelpMessage = invocationHelpMessage
                self.version = version
                self.programName = programName
                self.copyright = copyright
                self.license = license
                if formatUser == nil {
                        self.format = formatDefault
                } else {
                        self.format = formatUser
                }
                self.userName = NSUserName()
                Log.info("Command line initialized")
        }
        
        /*
         *  Adding options to the command line
         */
        
        func addVerb(_ verb: Verb) {
                assert(!self.verbs.contains(where: { $0.name == verb.name } ), "Verb '\(verb.name)' already in use")
                self.verbs.append(verb)
                Log.info("Added verb '%{public}@' to command line", String(verb.name))
        }
        
        func addOption(_ option: Option) {
                for case let flag? in [option.shortFlag, option.longFlag] {
                        assert(!self.usedFlags.contains(flag), "Flag '\(flag)' already in use")
                }
                self.options.append(option)
                Log.info("Added option '%{public}@' to command line", String(option.logDescription))
                self.optionMax = 0
        }
        
        /*
         *  Setting and overwriting existing command line options
         */

        func setOptions(_ options: [Option]) {
                self.options = [Option]()
                addOptions(options)
        }
        
        func setOptions(_ options: Option...) {
                self.options = [Option]()
                addOptions(options)
        }
        

        
        

        
        /*
         *  Formatting, usage, messages
         *
         *
         *  Print to standardError
         */
        var standardError = FileHandle.standardError
        func printDefault(_ string: String) {
                print(string, terminator: "", to: &standardError)
        }
        
        /* Variables */

        var listPadding: String = "  "
        var formatUser: ((String, style) -> String)? // If not nil this function will be called when printing usage messages
        var invocationHelpMessage: String
        var version: String
        var programName: String
        var copyright: String
        var license: String
        var versionMessage: String {
                get {
                        var string = "\(self.programName) \(self.version)\n"
                        string.append("\(self.copyright)\n")
                        string.append(self.license)
                        return string
                }
        }
        
        var optionMax: Int = 0
        var optionWidth: Int {
                if self.optionMax == 0 {
                        let mapped = self.options.map { $0.optionDescription.characters.count }
                        let padding = self.listPadding.count
                        self.optionMax = (mapped.sorted().last ?? 0) + padding
                }
                return self.optionMax
        }
        
        var verbMax: Int = 0
        var verbWidth: Int {
                if self.verbMax == 0 {
                        let mapped = self.verbs.map { $0.name.characters.count }
                        let padding = self.listPadding.count
                        self.verbMax = (mapped.sorted().last ?? 0) + padding
                }
                return self.verbMax
        }
        
        enum style {
                case invocationMessage
                case errorMessage
                case verbListItem
                case optionListItem
                case helpMessage
        }
       
        func formatDefault(forString string: String, style: style) -> String {
                switch style {
                case .invocationMessage:
                        return "\(string)\n"
                case .errorMessage:
                        return string != "" ? "\(string)\n" : ""
                case .optionListItem:
                        let option = string.padding(toLength: self.optionWidth, withPad: " ", startingAt: 0)
                        return "\(self.listPadding)\(option)"
                case .verbListItem:
                        let verb = string.padding(toLength: self.verbWidth, withPad: " ", startingAt: 0).uppercased()
                        return "\(self.listPadding)\(verb)"
                case .helpMessage:
                        return "\(string)\n"
                }
        }
        
        /*  Prints a usage message */
        
        func printUsage(verbs: Bool = false) {
                printDefault(self.format!("Usage: \(self.baseName) \(self.invocationHelpMessage)", style.invocationMessage))
                if verbs {
                        for verb in self.verbs {
                                printDefault(self.format!(verb.name, style.verbListItem))
                                printDefault(self.format!(verb.helpMessage, style.helpMessage))
                        }
                } else {
                        for option in self.options {
                                printDefault(self.format!(option.optionDescription, style.optionListItem))
                                printDefault(self.format!(option.helpMessage, style.helpMessage))
                        }
                }
        }
   
}
