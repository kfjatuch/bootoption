/*
 * File: make.swift
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

func make() {
        
        let loaderPath = StringOption(shortFlag: "l", longFlag: "loader", required: true, helpMessage: "the PATH to an EFI loader executable")
        let displayLabel = StringOption(shortFlag: "L", longFlag: "label", required: true, helpMessage: "display LABEL in firmware boot manager")
        let unicodeString = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
        let outputFileDmpstore = StringOption(shortFlag: "d", longFlag: "dmpstore", helpMessage: "output to FILE for use with EDK2 dmpstore", precludes: "xn")
        let outputNvram = BoolOption(shortFlag: "n", longFlag: "nvram", helpMessage: "print Apple nvram style string instead of raw hex", precludes: "dx")
        let outputXml = BoolOption(shortFlag: "x", longFlag: "xml", helpMessage: "print an XML serialization instead of raw hex", precludes: "dn")
        let keyForXml = StringOption(shortFlag: "k", longFlag: "key", helpMessage: "use the named KEY with option -x")
        
        commandLine.invocationHelpText = "make -l PATH -L LABEL [-u STRING] [-d FILE | -n | -x [-k KEY]]"
        commandLine.setOptions(loaderPath, displayLabel, unicodeString, outputFileDmpstore, outputNvram, outputXml, keyForXml)
        do {
                try commandLine.parse(strict: true)
        } catch {
                commandLine.printUsage(error: error)
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
        
        let data: Data = getVariableData(loader: loaderPath.value!, label: displayLabel.value!, unicode: unicodeString.value)
        if data.count < testCount {
                exit(1)
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
