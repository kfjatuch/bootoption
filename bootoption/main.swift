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

var testCount: Int = 54
var optionalData: Data?
let nvram = Nvram()
var commandLine = CommandLine(invocation: "VERB [options] where VERB is as follows:")

/* Command line parsing */

func parseVerb() {
        enum verbs {
                static let list = "list"
                static let make = "make"
                static let set = "set"
        }
        commandLine.addVerbs(verbs.list, verbs.make, verbs.set)
        commandLine.parseVerb()
        switch commandLine.verb {
        case verbs.make:
                make()
        case verbs.list:
                list()
        case verbs.set:
                set()
        default:
                commandLine.printUsage()
                exit(EX_USAGE)
        }

}

/* verb: list */

func list() {
        let menu = BootMenu()
        print(menu.string)
        exit(0)
}

func set() {
        commandLine = CommandLine(invocation: "set -l PATH -L LABEL [-u STRING]")
        let loaderPath = StringOption(shortFlag: "l", longFlag: "loader", required: true, helpMessage: "the PATH to an EFI loader executable")
        let displayLabel = StringOption(shortFlag: "L", longFlag: "label", required: true, helpMessage: "display LABEL in firmware boot manager")
        let unicodeString = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
        
        commandLine.addOptions(loaderPath, displayLabel, unicodeString)
        do {
                try commandLine.parse(strict: true)
        } catch {
                commandLine.printUsage(error)
                exit(EX_USAGE)
        }
}

func make() {
        
        commandLine = CommandLine(invocation: "make -l PATH -L LABEL [-u STRING]\n[--create | -d FILE | -n | -x [-k KEY]]")
        
        /* Command line options */
        
        let loaderPath = StringOption(shortFlag: "l", longFlag: "loader", required: true, helpMessage: "the PATH to an EFI loader executable")
        let displayLabel = StringOption(shortFlag: "L", longFlag: "label", required: true, helpMessage: "display LABEL in firmware boot manager")
        let unicodeString = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
        let create = BoolOption(shortFlag: "c", longFlag: "create", helpMessage: "save an option to NVRAM and add it to the BootOrder", precludes: "dpxn")
        let outputFileDmpstore = StringOption(shortFlag: "d", longFlag: "dmpstore", helpMessage: "output to FILE for use with EDK2 dmpstore", precludes: "pxns")
        let outputNvram = BoolOption(shortFlag: "n", longFlag: "nvram", helpMessage: "print Apple nvram style string instead of raw hex", precludes: "pdxs")
        let outputXml = BoolOption(shortFlag: "x", longFlag: "xml", helpMessage: "print an XML serialization instead of raw hex", precludes: "pdns")
        let keyForXml = StringOption(shortFlag: "k", longFlag: "key", helpMessage: "use the named KEY with option -x")

        commandLine.addOptions(loaderPath, displayLabel, unicodeString, create, outputFileDmpstore, outputNvram, outputXml, keyForXml)
        do {
                try commandLine.parse(strict: true)
        } catch {
                commandLine.printUsage(error)
                exit(EX_USAGE)
        }
        
        /* Printed output functions */
        
        func printFormatString(data: Data) {
                let strings = data.map { String(format: "%%%02x", $0) }
                let outputString = strings.joined()
                print(outputString)
        }
        
        func printRawHex(data: Data) {
                let strings = data.map { String(format: "%02x", $0) }
                let outputString = strings.joined()
                print(outputString)
        }
        
        func printXml(data: Data) {
                let key: String = keyForXml.value ?? "Boot"
                let dictionary: NSDictionary = ["\(key)": data]
                var propertyList: Data
                do {
                        propertyList = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
                } catch {
                        print(error)
                        exit(1)
                }
                if let xml = String.init(data: propertyList, encoding: .utf8) {
                        let outputString = String(xml.characters.filter { !"\n\t\r".characters.contains($0) })
                        print(outputString)
                } else {
                        print("Error printing serialized xml property list representation")
                        exit(1)
                }
        }
        
        if displayLabel.value == nil || loaderPath.value == nil {
                print("Required options should no longer be nil")
                exit(1)
        }
        
        /* Attributes */
        
        let attributes = Data.init(bytes: [1, 0, 0, 0])
        
        /* Description */
        
        if displayLabel.value!.containsOutlawedCharacters() {
                fatalError("Forbidden character(s) found in description")
        }
        
        var description = displayLabel.value!.data(using: String.Encoding.utf16)!
        description.removeFirst()
        description.removeFirst()
        description.append(contentsOf: [0, 0])
        
        /* Device path list */
        
        var devicePathList = Data.init()
        let hardDrive = HardDriveMediaDevicePath(forFile: loaderPath.value!)
        let file = FilePathMediaDevicePath(path: loaderPath.value!, mountPoint: hardDrive.mountPoint)
        let end = EndDevicePath()
        devicePathList.append(hardDrive.data)
        devicePathList.append(file.data)
        devicePathList.append(end.data)
        
        /* Device path list length */
        
        var devicePathListLength = Data.init()
        var lengthValue = UInt16(devicePathList.count)
        devicePathListLength.append(UnsafeBufferPointer(start: &lengthValue, count: 1))
        
        /* Optional data */
        
        if unicodeString.value != nil {
                optionalData = unicodeString.value!.data(using: String.Encoding.utf16)!
                optionalData?.removeFirst()
                optionalData?.removeFirst()
        }
        
        /* Boot option variable data */
        
        var efiLoadOption = Data.init()
        efiLoadOption.append(attributes)
        efiLoadOption.append(devicePathListLength)
        efiLoadOption.append(description)
        efiLoadOption.append(devicePathList)
        if (optionalData != nil) {
                efiLoadOption.append(optionalData!)
        }
        
        let data = efiLoadOption as Data
        if data.count < testCount {
                exit(1)
        }
        
        /* Set in NVRAM */
        
        if create.value {
                if let n: Int = nvram.createNewBootOption(withData: data, addToBootOrder: true) {
                        let name = nvram.bootOptionName(for: n)
                        print("Set variable: \(name)")
                        exit(0)
                } else {
                        print("--set was not a success")
                        exit(1)
                }
        }
        
        /* Output to dmpstore format file */
        
        if outputFileDmpstore.wasSet {
                let dmpstoreOption = Dmpstore.Option(fromData: data)
                let dmpstoreOrder = Dmpstore.Order(adding: dmpstoreOption.created)
                var buffer = Data.init()
                buffer.append(dmpstoreOption.data)
                buffer.append(dmpstoreOrder.data)
                let url = URL(fileURLWithPath: outputFileDmpstore.value!)
                do {
                        try buffer.write(to: url)
                } catch {
                        print(error)
                        exit(1)
                }
                print("Written to '\(outputFileDmpstore.value!)'")
                exit(0)
        }
        
        /* Printed output */
        
        if outputNvram.value {
                printFormatString(data: data)
        } else if outputXml.value {
                printXml(data: data)
        } else {
                printRawHex(data: data)
        }
        exit(0)
}

parseVerb()

