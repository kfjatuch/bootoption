/*
 * VerbParser.swift
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
        
        var status: ParserStatus = .noInput
        var helpVerb = "help"
        var versionVerb = "version"
        var activeVerb = ""
        var helpLongOption: String {
                return "\(getOpt.longPrefix)\(helpVerb)"
        }
        var versionLongOption: String {
                return "\(getOpt.longPrefix)\(versionVerb)"
        }
        
        init(argument: String?, verbs: [Verb]) {
                Log.info("Parsing command line verb...")
                if argument == nil {
                        status = .noInput
                        return
                }
                let verb = argument!.lowercased()
                if verb == helpLongOption {
                        activeVerb = "help"
                        status = .success
                } else if verb == versionLongOption {
                        activeVerb = "version"
                        status = .success
                } else if verbs.contains(where: { $0.name.uppercased() == verb.uppercased() } ) {
                        activeVerb = verb
                        status = .success
                } else {
                        status = .invalidVerb(verb)
                        return
                }
                Log.info("Active verb is '%{public}@'", String(activeVerb))
        }
        
        
}
