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
        private let attached: Character = "="
        private let programInfo: ProgramInfo
        private var formatFunction: ((String, CommandLine.format.style) -> String)?
        private var precludedOptions: String = ""
        
        private var activeCommandOrProgramName: String {
                return activeCommand ?? programInfo.name
        }
        
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
        var parserStatus: ParserStatus = .noInput
        var activeCommand: String?
        var unparsedArguments: [String] = []
        
        var versionMessage: String {
                var string = programInfo.name + " " + programInfo.version
                string = string + " " + programInfo.copyright + "\n" + programInfo.license
                return string
        }
        
        static var standardInput: Data {
                let standardInputFileHandle = FileHandle.init(fileDescriptor: FileHandle.standardInput.fileDescriptor, closeOnDealloc: true)
                let data = standardInputFileHandle.readDataToEndOfFile()
                standardInputFileHandle.closeFile()
                return data
        }
        
        public struct format {
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
        
        public func setOptions(_ options: Option...) {
                self.options = [Option]()
                for option in options {
                        addOption(option)
                }
                let mapped = options.map { $0.optionDescription.count }
                format.optionMaxWidth = (mapped.sorted().last ?? 0) + format.listPadding.count
                parserStatus = .noInput
        }
    
        public func setCommands(_ commands: Command...) {
                self.commands = [Command]()
                for command in commands {
                        addCommand(command)
                }
                let mapped = commands.map { $0.name.count }
                format.commandMaxWidth = (mapped.sorted().last ?? 0) + format.listPadding.count
                parserStatus = .noInput
        }
        
        public func printUsage(showingCommands: Bool = false) {
                print(formatFunction!("usage: \(baseName) \(invocationHelpMessage)", format.style.invocationMessage), terminator: "", to: &standardError)
                if showingCommands {
                        for command in commands {
                                print(formatFunction!(command.name, format.style.commandListItem), terminator: "", to: &standardError)
                                print(formatFunction!(command.helpMessage, format.style.helpMessage), terminator: "", to: &standardError)
                        }
                } else {
                        for option in options {
                                print(formatFunction!(option.optionDescription, format.style.optionListItem), terminator: "", to: &standardError)
                                print(formatFunction!(option.helpMessage, format.style.helpMessage), terminator: "", to: &standardError)
                        }
                }
                if showingCommands, let commandHelpMessage = commandHelpMessage {
                        print(String(format: commandHelpMessage, baseName))
                }
        }
        
        private func removeFirstArgument() -> String? {
                let commandString = rawArguments.count != 0 ? rawArguments.removeFirst() : nil
                return commandString
        }
        
        public func parseCommand() {
                Debug.log("Parsing command...", type: .info)
                let firstArgument: String? = removeFirstArgument()
                
                guard let command: String = firstArgument else {
                        Debug.log("No input", type: .info)
                        parserStatus = .noInput
                        return
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
                        Debug.log("Invalid command", type: .error)
                        errorCausing.command = command
                        parserStatus = .unrecognizedCommand
                        return
                }
                Debug.log("Active command is '%@'", type: .info, argsList: activeCommand ?? "nil")
        }
        
        private func getFlagValues(rawArguments: [String], flagIndex: Int, attachedArg: String? = nil) -> [String] {
                var args: [String] = [String]()
                var skipFlagChecks = false
                
                if let a = attachedArg {
                        args.append(a)
                }
                
                for i in flagIndex + 1 ..< rawArguments.count {
                        
                        if !skipFlagChecks {
                                
                                if rawArguments[i] == stopParsing {
                                        skipFlagChecks = true
                                        continue
                                }
                                
                                if rawArguments[i].hasPrefix(shortPrefix) && Int(rawArguments[i]) == nil && rawArguments[i].toDouble() == nil {
                                        break
                                }
                        }
                        
                        args.append(rawArguments[i])
                }
                
                return args
        }
        
        public func parseOptions(strict: Bool = false) {
                Debug.log("Parsing command options...", type: .info)
                var rawArguments = self.rawArguments
               
                if rawArguments.count == 0 {
                        Debug.log("No input", type: .info)
                        parserStatus = .noInput
                        return
                }
                
                let argumentsEnumerator = rawArguments.enumerated()
                
                for (index, argumentString) in argumentsEnumerator {
                        
                        Debug.log("%@: %@", type: .info, argsList: index, argumentString)
                        
                        if argumentString == stopParsing {
                                break
                        }
                        
                        if !argumentString.hasPrefix(shortPrefix) {
                                continue
                        }
                        
                        let skipChars = argumentString.hasPrefix(longPrefix) ? longPrefix.count : shortPrefix.count
                        let flagWithArg = argumentString[argumentString.index(argumentString.startIndex, offsetBy: skipChars)..<argumentString.endIndex]
                        
                        /* The argument contained nothing but ShortOptionPrefix or LongOptionPrefix */
                        
                        if flagWithArg.isEmpty {
                                continue
                        }
                        
                        /* Remove attached argument from flag */
                        
                        let splitFlag = flagWithArg.split(separator: attached, maxSplits: 1)
                        let flag = splitFlag[0]
                        let attachedArgument: String? = splitFlag.count == 2 ? String(splitFlag[1]) : nil
                        var flagMatched = false
                        
                        for option in options where option.flagMatch(String(flag)) {
                                
                                /* Preclude */
                                
                                if let c = option.shortFlag?.first {
                                        
                                        if precludedOptions.contains(c) {
                                                Debug.log("Too many options", type: .error)
                                                errorCausing.addOption(argumentString)
                                                parserStatus = .tooManyOptions
                                                return
                                        }
                                        
                                        precludedOptions.append(option.precludes)
                                }
                                
                                let values = getFlagValues(rawArguments: rawArguments, flagIndex: index, attachedArg: attachedArgument)
                                
                                guard option.setValue(values) else {
                                        Debug.log("Invalid argument for option", type: .error)
                                        errorCausing.addArguments(values)
                                        errorCausing.addOption(option)
                                        parserStatus = .invalidArgumentForOption
                                        return
                                }
                                
                                var claimedIndex = index + option.claimedValues
                                
                                if attachedArgument != nil {
                                        claimedIndex -= 1
                                }
                                
                                for i in index...claimedIndex {
                                        rawArguments[i] = ""
                                }
                                
                                flagMatched = true
                                
                                break
                        }
                        
                        /* Flags that do not take any arguments can be concatenated */
                        
                        let flagLength = flag.count
                        
                        if !flagMatched && !argumentString.hasPrefix(longPrefix) {
                                let flagCharactersEnumerator = flag.enumerated()
                                
                                for (i, c) in flagCharactersEnumerator {
                                        
                                        for option in options where option.flagMatch(String(c)) {
                                                
                                                /* preclude concatenated */
                                                if let c = option.shortFlag?.first {
                                                        
                                                        if precludedOptions.contains(c) {
                                                                Debug.log("Too many options", type: .error)
                                                                errorCausing.addOption(option.shortDescription)
                                                                parserStatus = .tooManyOptions
                                                                return
                                                        }
                                                        
                                                        precludedOptions.append(option.precludes)
                                                }
                                                
                                                /*
                                                 *  Values are allowed at the end of the concatenated flags, e.g.
                                                 *  -xvf <file1> <file2>
                                                 */
                                                
                                                let values = (i == flagLength - 1) ? getFlagValues(rawArguments: rawArguments, flagIndex: index, attachedArg: attachedArgument) : [String]()
                                                
                                                guard option.setValue(values) else {
                                                        Debug.log("Invalid argument for option", type: .error)
                                                        errorCausing.addArguments(values)
                                                        errorCausing.addOption(option)
                                                        parserStatus = .invalidArgumentForOption
                                                        return
                                                }
                                                
                                                var claimedIndex = index + option.claimedValues
                                                
                                                if attachedArgument != nil {
                                                        claimedIndex -= 1
                                                }
                                                
                                                for i in index...claimedIndex {
                                                        rawArguments[i] = ""
                                                }
                                                
                                                flagMatched = true
                                                break
                                        }
                                }
                        }
                        
                        /* Invalid flag */
                        
                        guard !strict || flagMatched else {
                                Debug.log("Unrecognised option", type: .error)
                                errorCausing.addOption(argumentString)
                                parserStatus = .unrecognisedOption
                                return
                        }
                }
                
                /* Check to see if any required options were not matched */
                
                var groupings: [Int] = Array()
                
                for option in options {
                        /* Get the unique values of options' required property */
                        let required = option.required
                        
                        if required != 0 && !groupings.contains(required) {
                                groupings.append(required)
                        }
                }
                
                if groupings.count > 0 {
                        Debug.log("Found required option groupings: %@", type: .info, argsList: groupings)
                }
                
                if groupings.count > 1 {
                        
                        /* if we have different groups of required options */
                        
                        for group in groupings {
                                
                                for option in options {
                                        
                                        /*  remove a unique value from the groups array if not
                                         *  all options specifying it have been set */
                                        
                                        if option.required == group && !option.wasSet {
                                                groupings.remove(at: groupings.index(where: { $0 == group } )!)
                                                break
                                        }
                                }
                        }
                        
                        /* return if there are no groups with all required options set */
                        
                        if groupings.count == 0 {
                                /* this error ambiguous */
                                Debug.log("Missing required option(s)", type: .error)
                                parserStatus = .missingRequiredOptionGroup
                                return
                        }
                        
                } else {
                        
                        /* only one set of required options with same required value */
                        
                        let missingOptions = options.filter {
                                $0.required != 0 && !$0.wasSet
                        }
                        
                        guard missingOptions.count == 0 else {
                                /* this error is specific about missing arguments */
                                Debug.log("Missing required options", type: .error)
                                errorCausing.addOptions(missingOptions)
                                parserStatus = .missingRequiredOptions
                                return
                        }
                }
                
                /* Capture any unparsed arguments */
                
                unparsedArguments = rawArguments.filter { $0 != "" }
                parserStatus = .success
        }
        
        public func printErrorAndUsage(showingCommands: Bool = false) {
                let command = "'" + (errorCausing.command ?? "nil") + "'"
                let options = "'" + errorCausing.options.joined(separator: "', '") + "'"
                let arguments = "'" + errorCausing.arguments.joined(separator: "', '") + "'"
                
                var error: String?
                
                switch parserStatus {
                case .tooManyOptions:
                        error = "\(activeCommandOrProgramName): too many options, stopped at \(options)"
                case .unrecognizedCommand:
                        error = "\(activeCommandOrProgramName): unrecognised command \(command)"
                case .invalidInput:
                        error = "\(activeCommandOrProgramName): invalid input \(arguments)"
                case .unrecognisedOption:
                        error = "\(activeCommandOrProgramName): unrecognised option \(options)"
                case .invalidArgumentForOption:
                        if errorCausing.arguments.count == 0 {
                                error = "\(activeCommandOrProgramName): option \(options) requires an argument"
                        } else if errorCausing.arguments.count > 1 {
                                error = "\(activeCommandOrProgramName): invalid arguments \(arguments) for option \(options)"
                        } else {
                                error = "\(activeCommandOrProgramName): invalid argument \(arguments) for option \(options)"
                        }
                case .missingRequiredOptions:
                        if errorCausing.options.count > 1 {
                                error = "\(activeCommandOrProgramName): missing required options \(options)"
                        } else {
                                error = "\(activeCommandOrProgramName): missing required option \(options)"
                        }
                case .missingRequiredOptionGroup:
                        error = "\(activeCommandOrProgramName): missing required option(s)"
                default:
                        break
                }
                
                if let error: String = error {
                        print(error, to: &standardError)
                }
                printUsage(showingCommands: showingCommands)
        }
        
        public func printErrorAndUsage(settingStatus status: ParserStatus, option: Option? = nil, argument: String? = nil, showingCommands: Bool = false) {
                commandLine.parserStatus = status
                if let argument = argument {
                        CommandLine.errorCausing.addArgument(argument)
                }
                if let option = option {
                        CommandLine.errorCausing.addOption(option.shortDescription)
                }
                commandLine.printErrorAndUsage()
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
        }
        
        struct errorCausing {
                static var command: String?
                static var options: [String] = []
                static var arguments: [String] = []
                
                static func addOption(_ option: Option) {
                        errorCausing.options.append(option.optionDescription)
                }
                
                static func addOption(_ option: String) {
                        errorCausing.options.append(option)
                }
                
                static func addOptions(_ options: [String]) {
                        for option in options {
                                errorCausing.options.append(option)
                        }
                }
                
                static func addOptions(_ options: [Option]) {
                        for option in options {
                                errorCausing.options.append(option.shortDescription)
                        }
                }
                
                static func addArgument(_ argument: String) {
                        errorCausing.arguments.append(argument)
                }
                
                static func addArguments(_ arguments: [String]) {
                        for argument in arguments {
                                errorCausing.arguments.append(argument)
                        }
                }
        }
}
