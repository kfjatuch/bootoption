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


var standardError = FileHandle.standardError

class CommandLine {
        
        enum ParserStatus {
                case noInput
                case invalidInput
                case success
                case invalidArgument(String)
                case tooManyOptions
                case invalidValueForOption(Option, [String])
                case missingRequiredOptions([Option])
                var description: String {
                        switch self {
                        case .noInput:
                                Log.info("Parse error: No input")
                                return "No input"
                        case .invalidInput:
                                Log.info("Parse error: Invalid input")
                                return "Invalid input"
                        case .success:
                                Log.info("Parse success!")
                                return "Success"
                        case let .invalidArgument(arg):
                                Log.error("Parse error: Invalid argument")
                                return "Invalid argument: \(arg)"
                        case .tooManyOptions:
                                Log.error("Parse error: Too many options")
                                return "Some options preclude the use of others."
                        case let .invalidValueForOption(opt, vals):
                                Log.error("Parse error: Invalid value")
                                let joined: String = vals.joined(separator: " ")
                                return "Invalid value(s) for option \(opt.shortDescription): \(joined)"
                        case let .missingRequiredOptions(opts):
                                Log.error("Parse error: Missing required options")
                                let mapped: Array = opts.map { return $0.shortDescription }
                                let joined: String = mapped.joined(separator: ", ")
                                return "Missing required option(s): \(joined)"
                        }
                }
                
        }
        

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
        var precludedOptions: String = ""

        /*
         *  init
         */
        
        init(arguments: [String] = Swift.CommandLine.arguments, invocationHelpMessage: String = "[options]", version: String = "1.0", programName: String = "", copyright: String = "", license: String = "") {
                self.rawArguments = arguments
                self.invocationHelpMessage = invocationHelpMessage
                self.version = version
                self.programName = programName
                self.copyright = copyright
                self.license = license
                /* Initialize locale settings from the environment */
                setlocale(LC_ALL, "")
                Log.info("Command line initialized")
        }
        
        /*
         *  Adding options to the command line
         */
        
        func addVerbs(_ verbs: Verb...) {
                for verb in verbs {
                        assert(!self.verbs.contains(where: { $0.name == verb.name } ), "Verb '\(verb.name)' already in use")
                        self.verbs.append(verb)
                        Log.info("Added verb '%{public}@' to command line", String(verb.name))
                }
        }
        
        func addOption(_ option: Option) {
                let flags = usedFlags
                for case let flag? in [option.shortFlag, option.longFlag] {
                        assert(!flags.contains(flag), "Flag '\(flag)' already in use")
                }
                self.options.append(option)
                Log.info("Added option '%{public}@' to command line", String(option.logDescription))
                self.optionMaxWidth = 0
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

        
        /*
         *  Setting and overwriting existing command line options
         *
         *  Sets the command line options [Option]
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
        
        static let shortPrefix = "-"
        static let longPrefix = "--"
        var optionMaxWidth: Int = 0
        var verbMaxWidth: Int = 0
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
        
        enum style {
                case invocationMessage
                case errorMessage
                case verbListItem
                case optionListItem
                case helpMessage
        }
        
        var optionWidth: Int {
                if self.optionMaxWidth == 0 {
                        self.optionMaxWidth = self.options.map { $0.optionDescription.characters.count }.sorted().last ?? 0
                }
                return self.optionMaxWidth + self.listPadding.count
        }
        
        var verbWidth: Int {
                if self.verbMaxWidth == 0 {
                        self.verbMaxWidth = self.verbs.map { $0.name.characters.count }.sorted().last ?? 0
                }
                return self.verbMaxWidth + self.listPadding.count
        }
       
        func formatDefault(forString string: String, style: style) -> String {
                switch style {
                case .invocationMessage:
                        return "\(string)\n"
                case .errorMessage:
                        return "\(string)\n"
                case .optionListItem:
                        let option = string.padding(toLength: self.optionWidth, withPad: " ", startingAt: 0)
                        return "\(self.listPadding)\(option)"
                case .verbListItem:
                        let verb = string.padding(toLength: self.verbWidth, withPad: " ", startingAt: 0)
                        return "\(self.listPadding)\(verb)"
                case .helpMessage:
                        return "\(string)\n"
                }
        }
        
        /* Print to standardError */
        
        func printDefault(_ string: String) {
                print(string, terminator: "", to: &standardError)
        }
        
        /*  Prints a usage message */
        
        func printUsage(withMessageForError error: ParserStatus? = nil, verbs: Bool = false) {
                let format: (String, CommandLine.style) -> String
                format = formatUser ?? formatDefault
                if let error: ParserStatus = error {
                        printDefault(format("\(error.description)", style.errorMessage))
                }
                let baseName = NSString(string: Swift.CommandLine.arguments[0]).lastPathComponent
                printDefault(format("Usage: \(baseName) \(self.invocationHelpMessage)", style.invocationMessage))
                if verbs {
                        for verb in self.verbs {
                                printDefault(format(verb.name.uppercased(), style.verbListItem))
                                printDefault(format(verb.helpMessage, style.helpMessage))
                        }
                } else {
                        for option in self.options {
                                printDefault(format(option.optionDescription, style.optionListItem))
                                printDefault(format(option.helpMessage, style.helpMessage))
                        }
                }
        }
   
}
