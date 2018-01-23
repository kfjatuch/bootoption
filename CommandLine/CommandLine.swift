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

        private let info: ProgramInfo
        private var format: ((String, CommandLine.style) -> String)?
        private var baseName: String {
                 return NSString(string: Swift.CommandLine.arguments[0]).lastPathComponent as String
        }
        private var usedFlags: Set<String> {
                var flags = Set<String>(minimumCapacity: options.count * 2)
                for option in options {
                        for case let flag? in [option.shortFlag, option.longFlag] {
                                flags.insert(flag)
                        }
                }
                return flags
        }

        var rawArguments: [String]
        var options: [Option] = Array()
        var verbs: [Verb] = Array()
        var invocationHelpMessage: String
        var verb: String? {
                return rawArguments.count != 0 ? rawArguments.removeFirst() : nil
        }
        var userName: String {
                return NSUserName()
        }
        var versionMessage: String {
                get {
                        var string = info.name + " " + info.version
                        string = string + " " + info.copyright + "\n" + info.license
                        return string
                }
        }


        
        
        
        /*
         *  init
         */
        
        init(invocationHelpMessage: String = "[options]", info: ProgramInfo, format formatUser: ((String, CommandLine.style) -> String)? = nil) {
                var arguments: [String] = Swift.CommandLine.arguments
                arguments.removeFirst()
                rawArguments = arguments
                self.invocationHelpMessage = invocationHelpMessage
                self.info = info
                if formatUser == nil {
                        format = formatDefault
                } else {
                        format = formatUser
                }
                Log.info("Command line initialized")
        }
        
        
        /*
         *  Adding options to the command line
         */
        
        private func addVerb(_ verb: Verb) {
                assert(!verbs.contains(where: { $0.name == verb.name } ), "Verb '\(verb.name)' already in use")
                verbs.append(verb)
                Log.info("Added verb '%{public}@' to command line", String(verb.name))
        }
        
        private func addOption(_ option: Option) {
                for case let flag? in [option.shortFlag, option.longFlag] {
                        assert(!usedFlags.contains(flag), "Flag '\(flag)' already in use")
                }
                options.append(option)
                Log.info("Added option '%{public}@' to command line", String(option.logDescription))
                optionMax = 0
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
         */

        private var standardError = FileHandle.standardError
        private var listPadding: String = "  "
        private var formatUser: ((String, style) -> String)? // If not nil this function will be called when printing usage messages
        private var optionMax: Int = 0
        private var verbMax: Int = 0
        private var optionWidth: Int {
                if optionMax == 0 {
                        let mapped = options.map { $0.optionDescription.characters.count }
                        let padding = listPadding.count
                        optionMax = (mapped.sorted().last ?? 0) + padding
                }
                return optionMax
        }
        private var verbWidth: Int {
                if verbMax == 0 {
                        let mapped = verbs.map { $0.name.characters.count }
                        let padding = listPadding.count
                        verbMax = (mapped.sorted().last ?? 0) + padding
                }
                return verbMax
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
                        let option = string.padding(toLength: optionWidth, withPad: " ", startingAt: 0)
                        return "\(listPadding)\(option)"
                case .verbListItem:
                        let verb = string.padding(toLength: verbWidth, withPad: " ", startingAt: 0).uppercased()
                        return "\(listPadding)\(verb)"
                case .helpMessage:
                        return "\(string)\n"
                }
        }
        
        /*  Prints a usage message */
        
        func printUsage(showingVerbs: Bool = false) {
                print(format!("Usage: \(baseName) \(invocationHelpMessage)", style.invocationMessage), terminator: "", to: &standardError)
                if showingVerbs {
                        for verb in verbs {
                                print(format!(verb.name, style.verbListItem), terminator: "", to: &standardError)
                                print(format!(verb.helpMessage, style.helpMessage), terminator: "", to: &standardError)
                        }
                } else {
                        for option in options {
                                print(format!(option.optionDescription, style.optionListItem), terminator: "", to: &standardError)
                                print(format!(option.helpMessage, style.helpMessage), terminator: "", to: &standardError)
                        }
                }
        }
}




extension CommandLine {
        
        func addVerbs(_ verbs: Verb...) {
                for verb in verbs {
                        addVerb(verb)
                }
        }
        
        func addVerbs(_ verbs: [Verb]) {
                for verb in verbs {
                        addVerb(verb)
                }
        }
        
        func addOptions(_ options: [Option]) {
                for option in options {
                        addOption(option)
                }
        }
        
        func addOptions(_ options: Option...) {
                for option in options {
                        addOption(option)
                }
        }
        
        func printUsage(withMessageForError error: ParserStatus, showingVerbs: Bool = false) {
                print(self.format!("\(error.description)", style.errorMessage), terminator: "", to: &standardError)
                printUsage(showingVerbs: showingVerbs)
        }
        
}




enum ParserStatus {
        case success
        case noInput
        case tooManyOptions
        case invalidVerb(String)
        case invalidInput(String)
        case invalidArgument(String)
        case invalidValueForOption(Option, [String])
        case missingRequiredOptions([Option])
        case missingRequiredOptionGroup
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
                case let .invalidVerb(string):
                        Log.info("Parse error: Invalid verb %{public}@", string)
                        return "Invalid verb: \(string)"
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
                case .missingRequiredOptionGroup:
                        Log.error("Parse error: Missing required option group(s)")
                        return "Missing required option(s)"
                }
        }
}




struct ProgramInfo {
        let name: String
        let version: String
        let copyright: String
        let license: String
        init(name: String, version: String, copyright: String, license: String) {
                self.name = name
                self.version = version
                self.copyright = copyright
                self.license = license
        }
}




struct getOpt {
        static let shortPrefix: String = "-"
        static let longPrefix: String = "--"
        static let stopParsing: String = "--"
        static let attached: Character = "="
}
