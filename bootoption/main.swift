/*
 * File: main.swift
 *
 * bootoption © vulgo 2017-2018 - A command line utility for managing a
 * firmware's EFI boot menu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation

var standardError = FileHandle.standardError

let versionString = "0.2.2"
let programName = "bootoption"
let copyright = "Copyright © 2017-2018 vulgo"
let license = "GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.\nThis is free software: you are free to change and redistribute it.\nThere is NO WARRANTY, to the extent permitted by law."
Log.info("*** bootoption version %{public}@", String(versionString))

/* Nvram */

let nvram = Nvram()

/* Initialise command line */

var commandLine = CommandLine(invocationHelpMessage: "VERB [options] where VERB is one from the following:", version: versionString, programName: programName, copyright: copyright, license: license)

/* Command line verb parsing */

func parseCommandLineVerb() {
        let listVerb = Verb(withName: "list", helpMessage: "show the firmware boot menu")
        let infoVerb = Verb(withName: "info", helpMessage: "show an option's properties")
        let setVerb = Verb(withName: "set", helpMessage: "set/modify variables in NVRAM")
        let createVerb = Verb(withName: "create", helpMessage: "create a new boot option")
        let orderVerb = Verb(withName: "order", helpMessage: "re-arrange the boot order")
        let deleteVerb = Verb(withName: "delete", helpMessage: "unset/delete variables in NVRAM")
        let saveVerb = Verb(withName: "save", helpMessage: "print or save boot variable data in different formats")
        commandLine.addVerbs(listVerb, infoVerb, setVerb, createVerb, orderVerb, deleteVerb, saveVerb)
        let verbParser = VerbParser(argument: commandLine.verb(), verbs: commandLine.verbs)
        switch verbParser.status {
        case .success:
                switch verbParser.activeVerb {
                        case listVerb.name:
                                list()
                        case infoVerb.name:
                                info()
                        case setVerb.name:
                                set()
                        case createVerb.name:
                                create()
                        case orderVerb.name:
                                order()
                        case deleteVerb.name:
                                delete()
                        case saveVerb.name:
                                save()
                        case verbParser.versionVerb:
                                version()
                        case verbParser.helpVerb:
                                help()
                        default:
                                commandLine.printUsage(verbs: true)
                                Log.logExit(EX_USAGE)
                }
        case .noInput:
                commandLine.printUsage(verbs: true)
                Log.logExit(EX_USAGE)
        default:
                commandLine.printUsage(withMessageForError: verbParser.status, verbs: true)
                Log.logExit(EX_USAGE)
        }
}

parseCommandLineVerb()
