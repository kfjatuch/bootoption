/*
 * File: main.swift
 *
 * bootoption © vulgo 2017 - A program to create / save an EFI boot
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

let commandLine = CommandLine(invocation: "-l PATH -L LABEL [-u STRING]\n          [-p FILE | -d FILE | -x | -n] [-k KEY]")

let loaderPath = StringOption(shortFlag: "l", longFlag: "loader", required: true, helpMessage: "the PATH to an EFI loader executable")
let displayLabel = StringOption(shortFlag: "L", longFlag: "label", required: true, helpMessage: "display LABEL in firmware boot manager")
let unicodeString = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
let outputFilePlist = StringOption(shortFlag: "p", longFlag: "plist", helpMessage: "output to FILE as an XML property list", precludes: "dxn")
let outputFileDmpstore = StringOption(shortFlag: "d", longFlag: "dmpstore", helpMessage: "output to FILE for use with EDK2 dmpstore", precludes: "pxn")
let outputXml = BoolOption(shortFlag: "x", longFlag: "xml", helpMessage: "print an XML serialization instead of raw hex", precludes: "pdn")
let outputNvram = BoolOption(shortFlag: "n", longFlag: "nvram", helpMessage: "print Apple nvram style string instead of raw hex", precludes: "pdx")
let keyForXml = StringOption(shortFlag: "k", longFlag: "key", helpMessage: "use the named KEY for options -p or -x")

func parseOptions() {
        
        commandLine.addOptions(loaderPath, displayLabel, unicodeString, outputFilePlist, outputFileDmpstore, outputXml, outputNvram, keyForXml)
        
        do {
                try commandLine.parse(strict: true)
        } catch {
                commandLine.printUsage(error)
                exit(EX_USAGE)
        }
        
}

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
        let dictionary: NSDictionary = ["\(keyForXml)": data]
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

func main() {
        
        if displayLabel.value == nil || loaderPath.value == nil {
                print("Error: Required variables should no longer be nil")
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
        
        if outputFilePlist.wasSet {
                let data = efiLoadOption as NSData
                var keyString: String = ""
                if keyForXml.wasSet {
                        keyString = keyForXml.value!
                } else {
                        keyString = "Boot"
                }
                let dictionary: NSDictionary = ["\(keyString)": data]
                let url = URL(fileURLWithPath: outputFilePlist.value!)
                do {
                        try dictionary.write(to: url)
                } catch {
                        print(error)
                        exit(1)
                }
                exit(0)
        }
        
        let data = efiLoadOption as Data
        if data.count < testCount {
                exit(1)
        }
        
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
        
        if outputNvram.value {
                printFormatString(data: data)
        } else if outputXml.value {
                printXml(data: data)
        } else {
                printRawHex(data: data)
        }

        exit(0)

}

parseOptions()
main()
