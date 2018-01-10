/*
 * CommandLine.swift
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

import Foundation

extension CommandLine {
        
        /*
         *  When listing options/verbs use these computed widths for layout
         */
        
        var optionColumn: Int {
                if self.optionMaxWidth == 0 {
                        self.optionMaxWidth = self.options.map { $0.optionDescription.characters.count }.sorted().last ?? 0
                }
                return self.optionMaxWidth + self.columnPadding.count
        }
        
        var verbColumn: Int {
                if self.verbMaxWidth == 0 {
                        self.verbMaxWidth = self.verbs.map { $0.name.characters.count }.sorted().last ?? 0
                }
                return self.verbMaxWidth + self.columnPadding.count
        }
        
        /*
         *  The type of output being supplied to an output formatter. - seealso: `formatOutput`
         */
        
        enum OutputType {
                /* About text: 'Usage: command-example [options]' and the like */
                case invocation
                
                /* An error message: 'Missing required option --extract' */
                case error
                
                /* A Verb.name e.g. VERB  help text */
                case verb
                
                /* An Option's optionDescription: e.g. -h, --help: */
                case option
                
                /* An Option or Verb's help message */
                case helpMessage
        }
        
        /*
         * Provides the default formatting of `printUsage()` output.
         */
        
        func defaultFormat(forString string: String, type: OutputType) -> String {
                switch type {
                case .invocation:
                        return "\(string)\n"
                case .error:
                        return "\(string)\n"
                case .option:
                        let option = string.padding(toLength: self.optionColumn, withPad: " ", startingAt: 0)
                        return "\(self.columnPadding)\(option)"
                case .verb:
                        let verb = string.padding(toLength: self.verbColumn, withPad: " ", startingAt: 0)
                        return "\(self.columnPadding)\(verb)"
                case .helpMessage:
                        return "\(string)\n"
                }
        }
        
        /*
         *  Prints a usage message
         */
        
        func printUsage(usingOutputStream outputStream: inout FileHandle) {
                let format: (String, CommandLine.OutputType) -> String
                format = formatOutput ?? defaultFormat
                let baseName = NSString(string: Swift.CommandLine.arguments[0]).lastPathComponent
                print(format("Usage: \(baseName) \(self.invocationHelpMessage)", .invocation), terminator: "", to: &outputStream)
                if self.activeVerb.isEmpty {
                        for verb in self.verbs {
                                print(format(verb.name.uppercased(), .verb), terminator: "", to: &outputStream)
                                print(format(verb.helpMessage, .helpMessage), terminator: "", to: &outputStream)
                        }
                } else {
                        for option in self.options {
                                print(format(option.optionDescription, .option), terminator: "", to: &outputStream)
                                print(format(option.helpMessage, .helpMessage), terminator: "", to: &outputStream)
                        }
                }
        }
        
        /*
         *  Prints an error then a usage message to standardError
         */
        
        func printUsageToStandardError(withError: Error) {
                let format: (String, CommandLine.OutputType) -> String
                format = formatOutput ?? defaultFormat
                print(format("\(withError)", .error), terminator: "", to: &standardError)
                printUsage(usingOutputStream: &standardError)
        }
        
        /*
         *  Prints a usage message to standardError
         */
        
        func printUsageToStandardError() {
                printUsage(usingOutputStream: &standardError)
        }
}
