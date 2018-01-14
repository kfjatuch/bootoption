/*
 * CommandLineExtensions.swift
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

extension CommandLine {
        
        func addVerbs(_ verbs: Verb...) {
                for verb in verbs {
                        addVerb(verb)
                }
        }
        
        func addVerbs(_ verbs: [Verb]) {
                for verb in verbs {
                        addVerb(verb)
                }
        }
        
        func addOptions(_ options: [Option]) {
                for option in options {
                        addOption(option)
                }
        }
        
        func addOptions(_ options: Option...) {
                for option in options {
                        addOption(option)
                }
        }
        
        func printUsage(withMessageForError error: ParserStatus, verbs: Bool = false) {
                printDefault(self.format!("\(error.description)", style.errorMessage))
                printUsage(verbs: verbs)
        }
        
}
