/*
 * CommandLineExtensions.swift
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

extension CommandLine {
        
        private var activeCommandOrProgramName: String {
                return activeCommand ?? programInfo.name
        }
        
        static var standardInput: Data {
                let standardInputFileHandle = FileHandle.init(fileDescriptor: FileHandle.standardInput.fileDescriptor, closeOnDealloc: true)
                let data = standardInputFileHandle.readDataToEndOfFile()
                standardInputFileHandle.closeFile()
                return data
        }
        
        internal func removeFirstArgument() -> String? {
                let commandString = rawArguments.count != 0 ? rawArguments.removeFirst() : nil
                return commandString
        }
        
        func assertOptionIsValidAndAppendInvalidatesOthers(_ option: Option) {
                /* some options invalidate the use of others when they are used */
                if let shortFlag = option.shortFlag?.first, invalidatedOptions.contains(shortFlag) {
                        printErrorAndUsage(settingStatus: .tooManyOptions, options: option)
                        Debug.terminate(8)
                } else {
                        if let new = option.invalidatesOthers {
                                for character in new where !invalidatedOptions.contains(character) {
                                        invalidatedOptions.insert(character)
                                }
                        }
                }
        }
        
        func appendArgs(to array: inout [String], option: Option, index: Int) {
                if let _ = option as? FilePathOption {
                        array.append(contentsOf: getArguments(followingIndex: index, fileOperandIsValid: true))
                } else {
                        array.append(contentsOf: getArguments(followingIndex: index))
                }
        }
        
        func setStringValue(array: inout [String], newValue: String = "", index: Int, count: Int, attachedArgument: String?) {
                var claimedIndex = index + count
                
                if attachedArgument != nil {
                        claimedIndex -= 1
                }
                
                for i in index...claimedIndex {
                        array[i] = newValue
                }                
        }
        
        public func printErrorAndUsage(settingStatus status: ParserStatus? = nil, options: Any? = nil, arguments: Any? = nil, showingCommands: Bool = false) {
                if let status = status {
                        commandLine.parserStatus = status
                }
                
                if let string = arguments as? String {
                        CommandLine.parseErrorsVars.addArgument(string)
                } else if let stringArray = arguments as? [String] {
                        CommandLine.parseErrorsVars.addArguments(stringArray)
                }
                
                if let string = options as? String {
                        CommandLine.parseErrorsVars.addOption(string)
                } else if let option = options as? Option {
                        CommandLine.parseErrorsVars.addOption(option)
                } else if let stringArray = options as? [String] {
                        CommandLine.parseErrorsVars.addOptions(stringArray)
                } else if let optionArray = options as? [Option] {
                        CommandLine.parseErrorsVars.addOptions(optionArray)
                }
                
                let options = "'" + parseErrorsVars.options.joined(separator: "', '") + "'"
                let arguments = "'" + parseErrorsVars.arguments.joined(separator: "', '") + "'"
                var error: String?
                
                switch parserStatus {
                case .tooManyOptions:
                        error = "\(activeCommandOrProgramName): \(options) is invalid with previous options"
                case .unrecognizedCommand:
                        error = "\(activeCommandOrProgramName): unrecognised command \(arguments)"
                case .invalidInput:
                        error = "\(activeCommandOrProgramName): invalid input \(arguments)"
                case .unrecognisedOption:
                        error = "\(activeCommandOrProgramName): unrecognised option \(options)"
                case .invalidArgumentForOption:
                        if parseErrorsVars.arguments.count == 0 {
                                error = "\(activeCommandOrProgramName): option \(options) requires an argument"
                        } else if parseErrorsVars.arguments.count > 1 {
                                error = "\(activeCommandOrProgramName): invalid arguments \(arguments) for option \(options)"
                        } else {
                                error = "\(activeCommandOrProgramName): invalid argument \(arguments) for option \(options)"
                        }
                case .missingRequiredOptions:
                        if parseErrorsVars.options.count > 1 {
                                error = "\(activeCommandOrProgramName): missing required options \(options)"
                        } else {
                                error = "\(activeCommandOrProgramName): missing required option \(options)"
                        }
                case .missingRequiredOptionGroup:
                        error = "\(activeCommandOrProgramName): missing required option(s)"
                case .unparsedArguments:
                        error = "\(activeCommandOrProgramName): unparsed arguments \(arguments)"
                default:
                        break
                }
                
                if let error: String = error {
                        print(error, to: &standardError)
                }
                
                printUsage(showingCommands: showingCommands)
        }
        
        struct parseErrorsVars {
                static var options: [String] = []
                static var arguments: [String] = []
                
                static func addOption(_ option: Option) {
                        parseErrorsVars.options.append(option.optionDescription)
                }
                
                static func addOption(_ option: String) {
                        parseErrorsVars.options.append(option)
                }
                
                static func addOptions(_ options: [String]) {
                        for option in options {
                                parseErrorsVars.options.append(option)
                        }
                }
                
                static func addOptions(_ options: [Option]) {
                        for option in options {
                                parseErrorsVars.options.append(option.shortDescription)
                        }
                }
                
                static func addArgument(_ argument: String) {
                        parseErrorsVars.arguments.append(argument)
                }
                
                static func addArguments(_ arguments: [String]) {
                        for argument in arguments {
                                parseErrorsVars.arguments.append(argument)
                        }
                }
        }
}
