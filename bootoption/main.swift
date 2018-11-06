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

#if DEBUG
let DEBUG = true
#else
let DEBUG = false
#endif

import Foundation

var standardError = FileHandle.standardError
if isatty(standardError.fileDescriptor) == 1 {
        Debug.infoCode = "\u{001B}[0;32m"
        Debug.warningCode = "\u{001B}[0;33m"
        Debug.errorCode = "\u{001B}[0;31m"
        Debug.resetCode = "\u{001B}[0;0m"
}

if Nvram.shared.emuVariableUefiPresent {
        Debug.fault("EmuVariableUefiPresent found in options")
}

var programInfo = ProgramInfo(name: "bootoption", version: "0.2.12", copyright: "Copyright © 2017-2018 vulgo", license: "This is free software: you are free to change and redistribute it.\nThere is NO WARRANTY, to the extent permitted by law.\nSee the GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>")

Debug.log("Version %@", type: .info, argsList: programInfo.version)

var commandLine = CommandLine(invocationHelpMessage: "<command> [options]\n\navailable commands:", commandHelpMessage: "\nfor command usage use: %@ <command>", info: programInfo)
let listCommand = Command("list", helpMessage: "show the firmware boot menu")
let infoCommand = Command("info", helpMessage: "show an option's properties")
let createCommand = Command("create", helpMessage: "create a new EFI load option")
let orderCommand = Command("order", helpMessage: "re-arrange the boot order")
let setCommand = Command("set", helpMessage: "set/modify variables in NVRAM")
let deleteCommand = Command("delete", helpMessage: "delete variables from NVRAM")
let rebootCommand = Command("reboot", helpMessage: "reboot to firmware settings")
commandLine.setCommands(listCommand, infoCommand, createCommand, orderCommand, setCommand, deleteCommand, rebootCommand)

commandLine.parseCommand()
        
switch commandLine.activeCommand {
case listCommand.name:
        list()
case infoCommand.name:
        info()
case setCommand.name:
        set()
case createCommand.name:
        create()
case orderCommand.name:
        order()
case deleteCommand.name:
        delete()
case rebootCommand.name:
        reboot()
case "version":
        version()
case "help":
        help()
default:
        commandLine.printUsage(showingCommands: true)
        Debug.terminate(EX_USAGE)
}
