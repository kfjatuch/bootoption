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

let shortPrefix = "-"
let longPrefix = "--"
let stopParsing = "--"
let attached: Character = "="

class CommandLine {
        
        struct command {
                static var options: [Option] = Array()
                static var verbs: [Verb] = Array()
                static let helpFlag = "--help"
                static let helpVerb = "help"
                static let versionFlag = "--version"
                static let versionVerb = "version"
        }
        
        var invocationHelpText: String
        var rawArguments: [String]
        var activeVerb: String = ""
        var storedFlagDescriptionWidth: Int = 0
        var storedVerbWidth: Int = 0
        var precludedOptions: String = ""
        var usedFlags: Set<String> {
                var flags = Set<String>(minimumCapacity: command.options.count * 2)
                for option in command.options {
                        for case let flag? in [option.shortFlag, option.longFlag] {
                                flags.insert(flag)
                        }
                }
                return flags
        }
        
        func getVersionVerb() -> String {
                return command.versionVerb
        }
        
        func getHelpVerb() -> String {
                return command.helpVerb
        }
        
        /* If supplied, this function will be called when printing usage messages. */
        var formatOutput: ((String, OutputType) -> String)?
        
        /*
         * After calling parse(), this property will contain any values that weren't
         * captured by an Option.
         */
        var unparsedArguments: [String] = [String]()



        /*
         * init()
         */
        
        init(arguments: [String] = Swift.CommandLine.arguments, invocationHelpText: String?) {
                self.rawArguments = arguments
                if invocationHelpText != nil {
                        self.invocationHelpText = invocationHelpText!
                } else {
                        self.invocationHelpText = "[options]"
                }
                
                /* Initialize locale settings from the environment */
                setlocale(LC_ALL, "")
        }

        /*
         *  Adds an Option to the command line.
         *  - parameter option: The option to add.
         */
        
        func addOption(_ option: Option) {
                let flags = usedFlags
                for case let flag? in [option.shortFlag, option.longFlag] {
                        assert(!flags.contains(flag), "Flag '\(flag)' already in use")
                }
                command.options.append(option)
                self.storedFlagDescriptionWidth = 0
        }
        
        /*
         *  Adds one or more Options to the command line.
         *  - parameter options: An array containing the options to add.
         */
        
        func addOptions(_ options: [Option]) {
                for option in options {
                        addOption(option)
                }
        }
        
        /*
         *  Adds one or more Options to the command line.
         *  - parameter options: The options to add.
         */
        
        func addOptions(_ options: Option...) {
                for option in options {
                        addOption(option)
                }
        }
        
        /*
         *  Adds one or more verb strings to the command line.
         *  - parameter verbs: The verbs to add.
         */
        
        func addVerbs(_ verbs: Verb...) {
                for verb in verbs {
                        assert(!command.verbs.contains(where: { $0.name == verb.name } ), "Verb '\(verb.name)' already in use")
                        command.verbs.append(verb)
                }
        }
        
        /*
         *  Sets the command line Options. Any existing options will be overwritten.
         *  - parameter options: An array containing the options to set.
         */
        
        func setOptions(_ options: [Option]) {
                command.options = [Option]()
                addOptions(options)
        }
        
        /*
         *  Sets the command line Options. Any existing options will be overwritten.
         *  - parameter options: The options to set.
         */
        
        func setOptions(_ options: Option...) {
                command.options = [Option]()
                addOptions(options)
        }
        
}
