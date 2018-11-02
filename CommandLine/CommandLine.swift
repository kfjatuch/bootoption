/*
 * CommandLine.swift
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

class CommandLine {
        
        private var standardError = FileHandle.standardError
        private let shortPrefix: String = "-"
        private let longPrefix: String = "--"
        private let stopParsing: String = "--"
        private let assignmentOperator: Character = "="
        private let programInfo: ProgramInfo
        private var formatFunction: ((String, CommandLine.format.style) -> String)?
        
        static let fileOperand: String = "-"

        private var baseName: String {
                return NSString(string: Swift.CommandLine.arguments[0]).lastPathComponent
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
        var options: [Option] = []
        var commands: [Command] = []
        var invocationHelpMessage: String
        var commandHelpMessage: String?
        var activeCommand: String?
        var unparsedArguments: [String]?
        var invalidatedOptions: Set<Character> = []
        
        private var _parserStatus: ParserStatus = .noInput
        var parserStatus: ParserStatus {
                get {
                        return _parserStatus
                }
                set {
                        switch newValue {
                        case .tooManyOptions:
                                Debug.log("Too many options", type: .error)
                        case .unrecognizedCommand:
                                Debug.log("Unrecognized command", type: .error)
                        case .invalidInput:
                                Debug.log("Invalid input", type: .error)
                        case .unrecognisedOption:
                                Debug.log("Unrecognized option", type: .error)
                        case .invalidArgumentForOption:
                                Debug.log("Invalid argument for option", type: .error)
                        case .missingRequiredOptions:
                                Debug.log("Missing required option", type: .error)
                        case .missingRequiredOptionGroup:
                                Debug.log("Missing required option group", type: .error)
                        case .unparsedArguments:
                                Debug.log("Unparsed arguments", type: .error)
                        case .success:
                                Debug.log("Success", type: .info)
                        case .noInput:
                                Debug.log("No input", type: .info)
                        }
                        _parserStatus = newValue
                }
        }
        
        var versionMessage: String {
                var string = programInfo.name + " " + programInfo.version
                string = string + " " + programInfo.copyright + "\n" + programInfo.license
                return string
        }
        
        struct format {
                static var listPadding: String = "  "
                static var optionMaxWidth: Int = 0
                static var commandMaxWidth: Int = 0
                static func defaultFormatFunction(forString string: String, style: style) -> String {
                        switch style {
                        case .invocationMessage:
                                return "\(string)\n"
                        case .errorMessage:
                                return string != "" ? "\(string)\n" : ""
                        case .optionListItem:
                                let option = string.padding(toLength: optionMaxWidth, withPad: " ", startingAt: 0)
                                return "\(format.listPadding)\(option)"
                        case .commandListItem:
                                let command = string.padding(toLength: commandMaxWidth + 3, withPad: " ", startingAt: 0)
                                return "\(format.listPadding)\(command)"
                        case .helpMessage:
                                return "\(string)\n"
                        }
                }
                enum style {
                        case invocationMessage
                        case errorMessage
                        case commandListItem
                        case optionListItem
                        case helpMessage
                }
        }
        
        enum ParserStatus {
                case success
                case noInput
                case tooManyOptions
                case unrecognizedCommand
                case invalidInput
                case unrecognisedOption
                case invalidArgumentForOption
                case missingRequiredOptions
                case missingRequiredOptionGroup
                case unparsedArguments
        }

        init(invocationHelpMessage: String = "[options]", commandHelpMessage: String? = nil, info: ProgramInfo, userFormatFunction: ((String, CommandLine.format.style) -> String)? = nil) {
                var arguments: [String] = Swift.CommandLine.arguments
                arguments.removeFirst()
                rawArguments = arguments
                self.invocationHelpMessage = invocationHelpMessage
                self.commandHelpMessage = commandHelpMessage
                self.programInfo = info
                if userFormatFunction == nil {
                        formatFunction = format.defaultFormatFunction
                } else {
                        formatFunction = userFormatFunction
                }
                Debug.log("Command line initialized", type: .info)
        }
        
        private func addCommand(_ command: Command) {
                assert(!commands.contains(where: { $0.name == command.name } ), "Command '\(command.name)' already in use")
                commands.append(command)
        }
        
        private func addOption(_ option: Option) {
                for case let flag? in [option.shortFlag, option.longFlag] {
                        assert(!usedFlags.contains(flag), "Flag '\(flag)' already in use")
                }
                options.append(option)
        }
        
        func setOptions(_ options: Option...) {
                self.options = [Option]()
                for option in options {
                        addOption(option)
                }
                let mapped = options.map { $0.optionDescription.count }
                format.optionMaxWidth = (mapped.sorted().last ?? 0) + format.listPadding.count
                parserStatus = .noInput
        }
    
        func setCommands(_ commands: Command...) {
                self.commands = [Command]()
                for command in commands {
                        addCommand(command)
                }
                let mapped = commands.map { $0.name.count }
                format.commandMaxWidth = (mapped.sorted().last ?? 0) + format.listPadding.count
                parserStatus = .noInput
        }
        
        func printUsage(showingCommands: Bool = false) {
                print(formatFunction!("usage: \(baseName) \(invocationHelpMessage)", format.style.invocationMessage), terminator: "", to: &standardError)
                if showingCommands {
                        for command in commands {
                                print(formatFunction!(command.name, format.style.commandListItem), terminator: "", to: &standardError)
                                print(formatFunction!(command.helpMessage, format.style.helpMessage), terminator: "", to: &standardError)
                        }
                } else {
                        for option in options {
                                if let helpMessage = option.helpMessage {
                                        print(formatFunction!(option.optionDescription, format.style.optionListItem), terminator: "", to: &standardError)
                                        print(formatFunction!(helpMessage, format.style.helpMessage), terminator: "", to: &standardError)
                                }
                        }
                }
                if showingCommands, let commandHelpMessage = commandHelpMessage {
                        print(String(format: commandHelpMessage, baseName))
                }
        }
        
        func getArguments(followingIndex index: Int, fileOperandIsValid: Bool = false) -> [String] {
                var arguments: [String] = []
                var checkPrefix = true
                var argument: String
                
                for i in index + 1 ..< rawArguments.count {
                        argument = rawArguments[i]
                        
                        if checkPrefix, argument == stopParsing {
                                
                                checkPrefix = false
                                continue
                                
                        }
                        
                        if checkPrefix, argument.hasPrefix(shortPrefix) {
                                
                                if fileOperandIsValid, argument == CommandLine.fileOperand {
                                        arguments.append(argument)
                                        continue
                                } else if Int(argument) != nil || argument.toDouble() != nil {
                                        arguments.append(argument)
                                        continue
                                } else {
                                        break
                                }
                        }
                        
                        arguments.append(rawArguments[i])
                }
                
                return arguments
        }
        
        func parseCommand() {
                Debug.log("Parsing command...", type: .info)
                let firstArgument: String? = removeFirstArgument()
                
                guard let command: String = firstArgument else {
                        commandLine.parserStatus = .noInput
                        printUsage(showingCommands: true)
                        Debug.terminate(0)
                }
                if command == "--help" {
                        activeCommand = "help"
                        parserStatus = .success
                } else if command == "--version" {
                        activeCommand = "version"
                        parserStatus = .success
                } else if commands.contains(where: { $0.name.lowercased() == command }) {
                        activeCommand = command
                        parserStatus = .success
                } else {
                        printErrorAndUsage(settingStatus: .unrecognizedCommand, arguments: command, showingCommands: true)
                        Debug.terminate(16)
                }
                Debug.log("Active command is '%@'", type: .info, argsList: activeCommand ?? "nil")
        }
        
        func parseOptions(strict: Bool = false) {
                Debug.log("Parsing options...", type: .info)
                var unparsedArguments: [String] = self.rawArguments
               
                if unparsedArguments.count == 0 {
                        commandLine.parserStatus = .noInput
                        printUsage()
                        Debug.terminate(0)
                }
                
                // Debug.log("begin args enumeration...", type: .info)
                argsEnumeration: for (argumentIndex, unparsedArgument) in unparsedArguments.enumerated() {
                        
                        var mightBeAssignment = false
                        var mightBeConcatenated = false
                        var optionFlagString: String = ""
                        var attachedArgument: String?
                        var argumentsForOption: [String] = []
                        var string = unparsedArgument
                        
                        if string == stopParsing {
                                
                                break
                                
                        } else if string.hasPrefix(longPrefix) {
                                
                                mightBeAssignment = string.contains(assignmentOperator)
                                string.removeFirst(longPrefix.count)
                                
                        } else if string.hasPrefix(shortPrefix) {
                                
                                mightBeConcatenated = string.count > shortPrefix.count + 1
                                string.removeFirst(shortPrefix.count)
                                
                        } else {
                                
                                continue
                        }

                        if string.isEmpty {
                                continue
                        }
                      
                        // Debug.log("arg %@: \"%@\"", type: .info, argsList: argumentIndex, unparsedArgument)
                        
                        if mightBeAssignment {
                        
                                let splitByAssignmentOperator = string.split(separator: assignmentOperator, maxSplits: 1)
                                optionFlagString = String(splitByAssignmentOperator[0])
                                // Debug.log("optionFlagString: %@", type: .info, argsList: optionFlagString)
                                
                                /* See if an argument is attached e.g. --option=argument */
                                
                                if splitByAssignmentOperator.count == 2 {
                                        attachedArgument = String(splitByAssignmentOperator[1])
                                        argumentsForOption.append(attachedArgument!)
                                        // Debug.log("attached argument: %@", type: .info, argsList: attachedArgument!)
                                }
                                
                        } else {

                                optionFlagString = string
                                // Debug.log("optionFlagString: %@", type: .info, argsList: optionFlagString)
                        }
                        
                        /* Try to match optionFlagString to an option */
                        for option in options where option.stringMatches(optionFlagString) {
                                // Debug.log("optionFlagString matches: %@", type: .info, argsList: option.optionDescription)
                                
                                assertOptionIsValidAndAppendInvalidatesOthers(option)
                                appendArgs(to: &argumentsForOption, option: option, index: argumentIndex)
                                // Debug.log("arguments for option: %@", type: .info, argsList: argumentsForOption)
                                
                                guard option.setValue(argumentsForOption) else {
                                        printErrorAndUsage(settingStatus: .invalidArgumentForOption, options: option, arguments: argumentsForOption)
                                        Debug.terminate(8)
                                }
                                
                                setStringValue(array: &unparsedArguments, newValue: "", index: argumentIndex, count: option.claimedValues, attachedArgument: attachedArgument)
                                
                                Debug.log("%@ %@", type: .info, argsList: option.optionDescription, argumentsForOption)
                                // Debug.log("continuing args enumeration...", type: .info)
                                continue argsEnumeration
                        }
                        
                        /* Flags that do not take any arguments can be concatenated */
                        
                        if !mightBeConcatenated, strict {
                                printErrorAndUsage(settingStatus: .unrecognisedOption, options: unparsedArgument)
                                Debug.terminate(8)
                                
                        } else if mightBeConcatenated {
                                
                                var unparsedCharacters = Set(optionFlagString)
                                let lastCharacterIndex: Int = optionFlagString.count - 1
                                
                                // Debug.log("begin character enumeration: \"-%@\"", type: .info, argsList: optionFlagString)
                                for (characterIndex, concatenatedCharacter) in optionFlagString.enumerated() {
                                        
                                        var argumentsForOption: [String] = []
                                        
                                        // Debug.log("char %@: \"%@\"", type: .info, argsList: characterIndex, concatenatedCharacter)
                                        
                                        /* Try to match concatenatedCharacter to an option */
                                        for option in options where option.stringMatches(concatenatedCharacter) {
                                                
                                                // Debug.log("concatenated \"%@\" matches: %@", type: .info, argsList: concatenatedCharacter, option.optionDescription)
                                                
                                                assertOptionIsValidAndAppendInvalidatesOthers(option)
                                                
                                                /*  arguments are allowed at the end of the concatenated flags, e.g. -xvf <file1> <file2> */
                                                if (characterIndex == lastCharacterIndex) {
                                                        appendArgs(to: &argumentsForOption, option: option, index: argumentIndex)
                                                }
                                                
                                                guard option.setValue(argumentsForOption) else {
                                                        printErrorAndUsage(settingStatus: .invalidArgumentForOption, options: option, arguments: argumentsForOption)
                                                        Debug.terminate(8)
                                                }
                                                
                                                Debug.log("%@ %@", type: .info, argsList: option.optionDescription, argumentsForOption)
                                                
                                                setStringValue(array: &unparsedArguments, newValue: "", index: argumentIndex, count: option.claimedValues, attachedArgument: attachedArgument)
                                                
                                                unparsedCharacters.remove(concatenatedCharacter)
                                        }
                                        
                                        // Debug.log("continuing...", type: .info)
                                } // characterEnumeration
                                
                                if strict, !unparsedCharacters.isEmpty {
                                        let unrecognised = "-\(unparsedCharacters.first!)"
                                        printErrorAndUsage(settingStatus: .unrecognisedOption, options: unrecognised)
                                        Debug.terminate(8)
                                }
                        }
                        // Debug.log("continuing args enumeration...", type: .info)
                } // argsEnumeration
                
                
                /* Add options' "required" values to array */
                var array: [Int] = Array()
                for option in options {
                        if option.required != 0 && !array.contains(option.required) {
                                array.append(option.required)
                        }
                }
                if !array.isEmpty {
                        Debug.log("Required option groups: %@", type: .info, argsList: array)
                }
                
                switch array.count {
                case 0:
                        break
                case 1:
                        /* single required option group */
                        let missingOptions = options.filter { $0.required != 0 && !$0.wasSet }
                        guard missingOptions.isEmpty else {
                                /* this error is specific about missing arguments */
                                printErrorAndUsage(settingStatus: .missingRequiredOptions, options: missingOptions)
                                Debug.terminate(8)
                        }
                default:
                        /* more than one required option group */
                        for optionGroup in array {
                                for option in options {
                                        if option.required == optionGroup && !option.wasSet {
                                                /*  remove optionGroup from array if not all options were set */
                                                array = array.filter { $0 != optionGroup }
                                                break
                                        }
                                }
                        }
                        
                        if array.isEmpty {
                                Debug.log("Missing required option(s)", type: .error)
                                printErrorAndUsage(settingStatus: .missingRequiredOptionGroup)
                                Debug.terminate(8)
                        }
                }
                
                
                
                /* Capture any unparsed arguments */
                
                self.unparsedArguments = unparsedArguments.filter { $0 != "" }
                // Debug.log("self.unparsedArguments:", type: .info, argsList: self.unparsedArguments as Any)
                
                if strict, let unparsed = self.unparsedArguments, !unparsed.isEmpty {
                        printErrorAndUsage(settingStatus: .unparsedArguments, arguments: unparsed)
                        Debug.terminate(8)
                }
                
                Debug.log("Finished parsing options", type: .info)
                parserStatus = .success
        }
        
}
