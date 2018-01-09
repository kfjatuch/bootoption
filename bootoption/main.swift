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

let versionString = "0.2.0"
var testCount: Int = 54
var optionalData: Data?
let nvram = Nvram()
Log.info("*** Starting bootoption version %{public}@", args: String(versionString))
var commandLine = CommandLine(invocationHelpText: "VERB [options] where VERB is one from the following:")

/* Command line parsing */

func parseVerb() {
        let listVerb = Verb(withName: "list", helpMessage: "print the current entries from the firmware boot menu")
        let setVerb = Verb(withName: "set", helpMessage: "create a new entry and add it to the boot order")
        let makeVerb = Verb(withName: "make", helpMessage: "print or save boot variable data in different formats")
        let deleteVerb = Verb(withName: "delete", helpMessage: "remove an entry from the firmware boot menu")
        commandLine.addVerbs(listVerb, setVerb, makeVerb, deleteVerb)
        commandLine.parseVerb()
        switch commandLine.activeVerb {
        case listVerb.name:
                list()
        case setVerb.name:
                set()
        case deleteVerb.name:
                delete()
        case makeVerb.name:
                make()
        case commandLine.getVersionVerb():
                version()
        case commandLine.getHelpVerb():
                help()
        default:
                exit(EX_USAGE)
        }
}

func getVariableData(loader: String, label: String, unicode: String?) -> Data {

        /* Attributes */
        
        Log.info("Generating attributes")
        let attributes = Data.init(bytes: [1, 0, 0, 0])
        
        /* Description */
        
        Log.info("Generating description")
        if label.containsOutlawedCharacters() {
                Log.error("Forbidden character(s) found in description")
        }
        
        var description = label.data(using: String.Encoding.utf16)!
        description.removeFirst()
        description.removeFirst()
        description.append(contentsOf: [0, 0])
        
        /* Device path list */
        
        Log.info("Generating device path list")
        var devicePathList = Data.init()
        let hardDrive = HardDriveMediaDevicePath(forFile: loader)
        let file = FilePathMediaDevicePath(path: loader, mountPoint: hardDrive.mountPoint)
        let end = EndDevicePath()
        devicePathList.append(hardDrive.data)
        devicePathList.append(file.data)
        devicePathList.append(end.data)
        
        /* Device path list length */
        
        Log.info("Generating device path list length")
        var devicePathListLength = Data.init()
        var lengthValue = UInt16(devicePathList.count)
        devicePathListLength.append(UnsafeBufferPointer(start: &lengthValue, count: 1))
        
        /* Optional data */
        
        if unicode != nil {
                Log.info("Generating optional data")
                optionalData = unicode!.data(using: String.Encoding.utf16)!
                optionalData?.removeFirst()
                optionalData?.removeFirst()
        } else {
                Log.info("Not generating optional data, none specified")
        }
        
        /* Boot option variable data */
        
        Log.info("Generating EFI_LOAD_OPTION structured buffer")
        var efiLoadOption = Data.init()
        efiLoadOption.append(attributes)
        efiLoadOption.append(devicePathListLength)
        efiLoadOption.append(description)
        efiLoadOption.append(devicePathList)
        if (optionalData != nil) {
                efiLoadOption.append(optionalData!)
        }
        
        return efiLoadOption as Data
        
}

parseVerb()

