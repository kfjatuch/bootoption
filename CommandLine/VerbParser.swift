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

class VerbParser {
        
        var status: CommandLine.ParserStatus = .noInput
        let helpLongOption = "--help"
        let versionLongOption = "--version"
        let helpVerb = "help"
        let versionVerb = "version"
        var activeVerb = ""
        
        init(rawArguments: [String], verbs: [Verb]) {
                Log.info("Parsing command line verb...")
                if rawArguments.count < 2 {
                        self.status = .noInput
                        return
                }
                let verb = rawArguments[1].lowercased()
                if verb == self.helpLongOption {
                        self.activeVerb = "help"
                        self.status = .success
                } else if verb == self.versionLongOption {
                        self.activeVerb = "version"
                        self.status = .success
                } else if verbs.contains(where: { $0.name.uppercased() == verb.uppercased() } ) {
                        self.activeVerb = verb
                        self.status = .success
                } else {
                        Log.error("Found invalid verb '%{public}@'", String(verb))
                        self.status = .invalidInput
                }
                Log.info("Active verb is '%{public}@'", String(self.activeVerb))
        }
        
        
}
