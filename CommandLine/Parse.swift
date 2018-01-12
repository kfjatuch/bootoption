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
        
        /* A ParseError is thrown if the parse() method fails. */
        
        enum ParseError: Error, CustomStringConvertible {
                case invalidArgument(String)
                case tooManyOptions()
                case invalidValueForOption(Option, [String])
                case missingRequiredOptions([Option])
                var description: String {
                        switch self {
                        case let .invalidArgument(arg):
                                CommandLog.error("Parse error: Invalid argument")
                                return "Invalid argument: \(arg)"
                        case .tooManyOptions:
                                CommandLog.error("Parse error: Too many options")
                                return "Some options preclude the use of others."
                        case let .invalidValueForOption(opt, vals):
                                CommandLog.error("Parse error: Invalid value")
                                let joined: String = vals.joined(separator: " ")
                                return "Invalid value(s) for option \(opt.shortDescription): \(joined)"
                        case let .missingRequiredOptions(opts):
                                CommandLog.error("Parse error: Missing required options")
                                let mapped: Array = opts.map { return $0.shortDescription }
                                let joined: String = mapped.joined(separator: ", ")
                                return "Missing required option(s): \(joined)"
                        }
                }
        }
        
        /*
         *  parseVerb()
         *  See if a valid verb was specified and if yes set self.activeVerb
         */
        
        func parseVerb() {
                CommandLog.info("Parsing command line verb...")
                if rawArguments.count < 2 {
                        CommandLog.info("Nothing to parse, printing usage")
                        printUsage()
                        CommandLog.def("* exit code: %{public}d", args: EX_USAGE)
                        exit(EX_USAGE)
                }
                let verb = rawArguments[1].lowercased()
                if verb == self.helpLongOption {
                        self.activeVerb = "help"
                } else if verb == self.versionLongOption {
                        self.activeVerb = "version"
                } else if self.verbs.contains(where: { $0.name.uppercased() == verb.uppercased() } ) {
                        self.activeVerb = verb
                } else {
                        CommandLog.error("Found invalid verb '%{public}@'", args: String(verb))
                        printUsage()
                        CommandLog.def("* exit code: %{public}d", args: EX_USAGE)
                        exit(EX_USAGE)
                }
                CommandLog.info("Active verb is '%{public}@'", args: String(self.activeVerb))
        }
        
        /*
         *  Returns all argument values from flagIndex to the next flag
         *  or the end of the argument array.
         */
        
        func getFlagValues(_ flagIndex: Int, _ attachedArg: String? = nil) -> [String] {
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
        
        /*
         *  parse options
         */
        
        func parse(strict: Bool = false) throws {
                
                Log.info("Parsing command line options...")
                var raw = rawArguments
                raw[0] = ""
                raw[1] = ""
                
                let argumentsEnumerator = rawArguments.enumerated()
                for (index, string) in argumentsEnumerator {
                        if string == stopParsing {
                                break
                        }
                        
                        if !string.hasPrefix(shortPrefix) {
                                continue
                        }
                        
                        let skipChars = string.hasPrefix(longPrefix) ? longPrefix.characters.count : shortPrefix.characters.count
                        let flagWithArg = string[string.index(string.startIndex, offsetBy: skipChars)..<string.endIndex]
                        
                        /* The argument contained nothing but ShortOptionPrefix or LongOptionPrefix */
                        
                        if flagWithArg.isEmpty {
                                continue
                        }
                        
                        /* Remove attached argument from flag */
                        
                        let splitFlag = flagWithArg.split(separator: attached, maxSplits: 1)
                        let flag = splitFlag[0]
                        let attachedArgument: String? = splitFlag.count == 2 ? String(splitFlag[1]) : nil
                        var flagMatched = false
                        for option in self.options where option.flagMatch(String(flag)) {

                                /* Preclude */
                                
                                if let c = option.shortFlag?.characters.first {
                                        
                                        if self.precludedOptions.characters.contains(c) {
                                                throw ParseError.tooManyOptions()
                                        }
                                        
                                        self.precludedOptions.append(option.precludes)
                                }
                                
                                let values = self.getFlagValues(index, attachedArgument)
                                guard option.setValue(values) else {
                                        throw ParseError.invalidValueForOption(option, values)
                                }
                                
                                var claimedIndex = index + option.claimedValues
                                if attachedArgument != nil { claimedIndex -= 1 }
                                for i in index...claimedIndex {
                                        raw[i] = ""
                                }
                                
                                flagMatched = true

                                break
                        }
                        
                        /* Flags that do not take any arguments can be concatenated */
                        
                        let flagLength = flag.characters.count
                        if !flagMatched && !string.hasPrefix(longPrefix) {
                                let flagCharactersEnumerator = flag.characters.enumerated()
                                for (i, c) in flagCharactersEnumerator {
                                        for option in self.options where option.flagMatch(String(c)) {
                                                
                                                /* preclude */
                                                if let c = option.shortFlag?.characters.first {
                                                        if self.precludedOptions.characters.contains(c) {
                                                                throw ParseError.tooManyOptions()
                                                        }
                                                        self.precludedOptions.append(option.precludes)
                                                }
                                                
                                                /*
                                                 *  Values are allowed at the end of the concatenated flags, e.g.
                                                 *  -xvf <file1> <file2>
                                                 */
                                                
                                                let values = (i == flagLength - 1) ? self.getFlagValues(index, attachedArgument) : [String]()
                                                guard option.setValue(values) else {
                                                        throw ParseError.invalidValueForOption(option, values)
                                                }
                                                
                                                var claimedIndex = index + option.claimedValues
                                                if attachedArgument != nil { claimedIndex -= 1 }
                                                for i in index...claimedIndex {
                                                        raw[i] = ""
                                                }
                                                
                                                flagMatched = true
                                                break
                                        }
                                }
                        }
                        
                        /* Invalid flag */
                        
                        guard !strict || flagMatched else {
                                throw ParseError.invalidArgument(string)
                        }
                }
                
                /* Check to see if any required options were not matched */
                
                let missingOptions = self.options.filter { $0.required && !$0.wasSet }
                guard missingOptions.count == 0 else {
                        throw ParseError.missingRequiredOptions(missingOptions)
                }
                
                unparsedArguments = raw.filter { $0 != "" }
        }
}
