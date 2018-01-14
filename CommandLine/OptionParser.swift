/*
 * OptionParser.swift
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

class OptionParser {
        
        var status: CommandLine.ParserStatus = .noInput
        var errorMessage: String {
                return self.status.description
        }
        var precludedOptions: String = ""
        var unparsedArguments: [String] = [String]() // This property will contain any values that weren't captured by an option
        
        func getFlagValues(rawArguments: [String], flagIndex: Int, attachedArg: String? = nil) -> [String] {
                var args: [String] = [String]()
                var skipFlagChecks = false
                
                if let a = attachedArg {
                        args.append(a)
                }
                
                for i in flagIndex + 1 ..< rawArguments.count {
                        if !skipFlagChecks {
                                if rawArguments[i] == CommandLine.stopParsing {
                                        skipFlagChecks = true
                                        continue
                                }
                                
                                if rawArguments[i].hasPrefix(CommandLine.shortPrefix) && Int(rawArguments[i]) == nil && rawArguments[i].toDouble() == nil {
                                        break
                                }
                        }
                        
                        args.append(rawArguments[i])
                }
                
                return args
        }
        
        deinit {
                Log.info("OptionParser deinit")
        }
        
        init(options: [Option], rawArguments: [String], strict: Bool = false) {
                Log.info("Parsing command line options...")
                
                var raw = rawArguments
                
                if rawArguments.count == 0 {
                        return
                }
                
                let argumentsEnumerator = rawArguments.enumerated()
                
                for (index, string) in argumentsEnumerator {
                        if string == CommandLine.stopParsing {
                                break
                        }
                        
                        if !string.hasPrefix(CommandLine.shortPrefix) {
                                continue
                        }
                        
                        let skipChars = string.hasPrefix(CommandLine.longPrefix) ? CommandLine.longPrefix.characters.count : CommandLine.shortPrefix.characters.count
                        let flagWithArg = string[string.index(string.startIndex, offsetBy: skipChars)..<string.endIndex]
                        
                        /* The argument contained nothing but ShortOptionPrefix or LongOptionPrefix */
                        
                        if flagWithArg.isEmpty {
                                continue
                        }
                        
                        /* Remove attached argument from flag */
                        
                        let splitFlag = flagWithArg.split(separator: CommandLine.attached, maxSplits: 1)
                        let flag = splitFlag[0]
                        let attachedArgument: String? = splitFlag.count == 2 ? String(splitFlag[1]) : nil
                        var flagMatched = false
                        for option in options where option.flagMatch(String(flag)) {
                                
                                /* Preclude */
                                
                                if let c = option.shortFlag?.characters.first {
                                        
                                        if self.precludedOptions.characters.contains(c) {
                                                self.status = .tooManyOptions
                                                return
                                        }
                                        
                                        self.precludedOptions.append(option.precludes)
                                }
                                
                                let values = self.getFlagValues(rawArguments: rawArguments, flagIndex: index, attachedArg: attachedArgument)
                                guard option.setValue(values) else {
                                        self.status = .invalidValueForOption(option, values)
                                        return
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
                        if !flagMatched && !string.hasPrefix(CommandLine.longPrefix) {
                                let flagCharactersEnumerator = flag.characters.enumerated()
                                for (i, c) in flagCharactersEnumerator {
                                        for option in options where option.flagMatch(String(c)) {
                                                
                                                /* preclude */
                                                if let c = option.shortFlag?.characters.first {
                                                        if self.precludedOptions.characters.contains(c) {
                                                                self.status = .tooManyOptions
                                                                return
                                                        }
                                                        self.precludedOptions.append(option.precludes)
                                                }
                                                
                                                /*
                                                 *  Values are allowed at the end of the concatenated flags, e.g.
                                                 *  -xvf <file1> <file2>
                                                 */
                                                
                                                let values = (i == flagLength - 1) ? self.getFlagValues(rawArguments: rawArguments, flagIndex: index, attachedArg: attachedArgument) : [String]()
                                                guard option.setValue(values) else {
                                                        self.status = .invalidValueForOption(option, values)
                                                        return
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
                                self.status = .invalidArgument(string)
                                return
                        }
                }
                
                /* Check to see if any required options were not matched */
                
                let missingOptions = options.filter { $0.required && !$0.wasSet }
                guard missingOptions.count == 0 else {
                        self.status = .missingRequiredOptions(missingOptions)
                        return
                }
                
                self.unparsedArguments = raw.filter { $0 != "" }
                self.status = .success
        }
        
}
