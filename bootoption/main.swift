/*
 * File: main.swift
 *
 * bootoption © vulgo 2017-2018 - A program to create / save an EFI boot
 * option - so that it might be added to the firmware menu later
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

let versionString = "0.2.1"
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
        let setVerb = Verb(withName: "set", helpMessage: "set/create variables in NVRAM")
        let orderVerb = Verb(withName: "order", helpMessage: "change the boot order")
        let deleteVerb = Verb(withName: "delete", helpMessage: "unset/delete variables in NVRAM")
        let makeVerb = Verb(withName: "make", helpMessage: "print or save boot variable data in different formats")

        commandLine.addVerbs(listVerb, setVerb, orderVerb, deleteVerb, makeVerb)
        commandLine.parseVerb()
        switch commandLine.activeVerb {
        case listVerb.name:
                list()
        case setVerb.name:
                set()
        case orderVerb.name:
                order()
        case deleteVerb.name:
                delete()
        case makeVerb.name:
                make()
        case commandLine.versionVerb:
                version()
        case commandLine.helpVerb:
                help()
        default:
                logExit(EX_USAGE)
        }
}

func logExit(_ status: Int32) -> Never {
        if status != 0 {
                Log.def("* exit code: %{public}d", status)
        } else {
                Log.info("* exit code: %{public}d", status)
        }
        exit(status)
}

parseCommandLineVerb()
