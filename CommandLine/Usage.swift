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
        
        /* An output stream to stderr; used by CommandLine.printUsage(). */
        
        struct StderrOutputStream: TextOutputStream {
                static let stream = StderrOutputStream()
                func write(_ s: String) {
                        fputs(s, stderr)
                }
        }
        
        /*
         *  The maximum width of all options' `flagDescription` properties; provided for use by
         *  output formatters.
         *  - seealso: `defaultFormat`, `formatOutput`
         */
        
        var flagDescriptionWidth: Int {
                if self.storedFlagDescriptionWidth == 0 {
                        self.storedFlagDescriptionWidth = command.options.map { $0.flagDescription.characters.count }.sorted().last ?? 0
                }
                return self.storedFlagDescriptionWidth
        }
        
        var verbWidth: Int {
                if self.storedVerbWidth == 0 {
                        self.storedVerbWidth = command.verbs.map { $0.name.characters.count }.sorted().last ?? 0
                }
                return self.storedVerbWidth
        }
        
        /*
         *  The type of output being supplied to an output formatter.
         *  - seealso: `formatOutput`
         */
        
        enum OutputType {
                /* About text: 'Usage: command-example [options]' and the like */
                case about
                
                /* An error message: 'Missing required option --extract' */
                case error
                
                /* A verb e.g. VERB  help text */
                case verb
                
                /* An Option's flagDescription: e.g. -h, --help: */
                case optionFlag
                
                /* An Option's help message */
                case optionHelp
        }
        
        /*
         * Provides the default formatting of `printUsage()` output.
         */
        
        func defaultFormat(forString string: String, type: OutputType) -> String {
                switch type {
                case .about:
                        return "\(string)\n"
                case .error:
                        return "\(string)\n"
                case .optionFlag:
                        return "  \(string.padded(toWidth: flagDescriptionWidth + 3))"
                case .verb:
                        return "  \(string.padded(toWidth: verbWidth + 3))"
                case .optionHelp:
                        return "\(string)\n"
                }
        }
        
        /*
         *  Prints a usage message.
         *  - parameter to: An OutputStreamType to write the error message to.
         */
        
        func printUsage(usingOutputStream to: inout StderrOutputStream) {
                let format: (String, CommandLine.OutputType) -> String
                format = formatOutput ?? defaultFormat
                let name = NSString(string: Swift.CommandLine.arguments[0]).lastPathComponent
                print(format("Usage: \(name) \(self.invocationHelpText)", .about), terminator: "", to: &to)
                if self.activeVerb.isEmpty {
                        for verb in command.verbs {
                                print(format(verb.name.uppercased(), .verb), terminator: "", to: &to)
                                print(format(verb.helpMessage, .optionHelp), terminator: "", to: &to)
                        }
                } else {
                        for opt in command.options {
                                print(format(opt.flagDescription, .optionFlag), terminator: "", to: &to)
                                print(format(opt.helpMessage, .optionHelp), terminator: "", to: &to)
                        }
                }
        }
        
        /*
         *  Prints a usage message.
         *  - parameter error: An error thrown from `parse()`. A description of the error
         *   (e.g. "Missing required option --extract") will be printed before the usage message.
         *  - parameter to: An OutputStreamType to write the error message to.
         */
        
        func printUsage(error: Error, usingOutputStream out: inout StderrOutputStream) {
                let format: (String, CommandLine.OutputType) -> String
                format = formatOutput ?? defaultFormat
                print(format("\(error)", .error), terminator: "", to: &out)
                printUsage(usingOutputStream: &out)
        }
        
        /*
         *  Prints a usage message.
         *  - parameter error: An error thrown from `parse()`. A description of the error
         *  (e.g. "Missing required option --extract") will be printed before the usage message.
         */
        func printUsage(error: Error) {
                var out = StderrOutputStream.stream
                printUsage(error: error, usingOutputStream: &out)
        }
        
        /*
         *  Prints a usage message.
         */
        func printUsage() {
                var out = StderrOutputStream.stream
                printUsage(usingOutputStream: &out)
        }
}
