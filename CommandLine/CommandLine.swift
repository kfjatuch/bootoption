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
var standardError = FileHandle.standardError

class CommandLine {
        
        /*
         *  Variables
         */
        
        var rawArguments: [String]
        
        /* Verbs and options variables */
        
        var options: [Option] = Array()
        var verbs: [Verb] = Array()
        let helpLongOption = "--help"
        let helpVerb = "help"
        let versionLongOption = "--version"
        let versionVerb = "version"
        let stopParsing = "--"
        let attached: Character = "="
        var activeVerb: String = ""
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
        var unparsedArguments: [String] = [String]() // This property will contain any values that weren't captured by an option
        
        /* Messages variables */
        
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
        
        /* Format and layout variables */
        
        var optionMaxWidth: Int = 0
        var verbMaxWidth: Int = 0
        var columnPadding: String = "  "
        var formatOutput: ((String, OutputType) -> String)? // If not nil this function will be called when printing usage messages

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
                CommandLog.info("Command line initialized")
        }
        
        /*
         *  Adding options to the command line
         *
         *  Add single Option
         */
        
        func addOption(_ option: Option) {
                let flags = usedFlags
                for case let flag? in [option.shortFlag, option.longFlag] {
                        assert(!flags.contains(flag), "Flag '\(flag)' already in use")
                }
                self.options.append(option)
                CommandLog.info("Added option '%{public}@' to command line", args: String(option.logDescription))
                self.optionMaxWidth = 0
        }
        
	/* Add array of [Option] to the command line */

        func addOptions(_ options: [Option]) {
                for option in options {
                        addOption(option)
                }
        }
        
        /* Add 1 or more Option to the command line */
        
        func addOptions(_ options: Option...) {
                for option in options {
                        addOption(option)
                }
        }
        
        /*
         *  Adding verbs to the command line
         */
        
        func addVerbs(_ verbs: Verb...) {
                for verb in verbs {
                        assert(!self.verbs.contains(where: { $0.name == verb.name } ), "Verb '\(verb.name)' already in use")
                        self.verbs.append(verb)
                        CommandLog.info("Added verb '%{public}@' to command line", args: String(verb.name))
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
        
        /* Sets one or more command line Option... */
        
        func setOptions(_ options: Option...) {
                self.options = [Option]()
                addOptions(options)
        }
        
}
