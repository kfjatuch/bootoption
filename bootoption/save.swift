/*
 * File: make.swift
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

func save() {

        Log.info("Setting up command line")
        let loaderOption = StringOption(shortFlag: "l", longFlag: "loader", required: 1, helpMessage: "the PATH to an EFI loader executable")
        let descriptionOption = StringOption(shortFlag: "L", longFlag: "label", required: 1, helpMessage: "display LABEL in firmware boot manager")
        let dataStringOption = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
        let outputOption = StringOption(shortFlag: "o", longFlag: "output", helpMessage: "write to FILE for use with EDK2 dmpstore", precludes: "xa")
        let appleOption = BoolOption(shortFlag: "a", longFlag: "apple", helpMessage: "print Apple nvram-style string instead of raw hex", precludes: "ox")
        let xmlOption = BoolOption(shortFlag: "x", longFlag: "xml", helpMessage: "print an XML serialization instead of raw hex", precludes: "oa")
        let keyOption = StringOption(shortFlag: "k", longFlag: "key", helpMessage: "specify named KEY, use with option -x")
        commandLine.invocationHelpMessage = "save -l PATH -L LABEL [-u STRING] [-o FILE | -a | -x [-k KEY]]"
        commandLine.setOptions(loaderOption, descriptionOption, dataStringOption, outputOption, appleOption, xmlOption, keyOption)

        let optionParser = OptionParser(options: commandLine.options, rawArguments: commandLine.rawArguments, strict: true)
        switch optionParser.status {
        case .success:
                
                /* Printed output functions */
                
                func printFormatString(data: Data) {
                        Log.info("Printing format string")
                        let strings = data.map { String(format: "%%%02x", $0) }
                        let outputString = strings.joined()
                        print(outputString)
                }
                
                func printRawHex(data: Data) {
                        Log.info("Printing raw hex")
                        let strings = data.map { String(format: "%02x", $0) }
                        let outputString = strings.joined()
                        print(outputString)
                }
                
                func printXml(data: Data) {
                        Log.info("Printing XML")
                        let key: String = keyOption.value ?? "Boot"
                        let dictionary: NSDictionary = ["\(key)": data]
                        var propertyList: Data
                        do {
                                propertyList = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
                        } catch let error as NSError {
                                let errorDescription = error.localizedDescription
                                let errorCode = error.code
                                print(errorDescription)
                                Log.error("Error serializing to XML (%{public}@)", String(errorCode))
                                Log.logExit(EX_UNAVAILABLE)
                        }
                        if let xml = String.init(data: propertyList, encoding: .utf8) {
                                let outputString = String(xml.characters.filter { !"\n\t\r".characters.contains($0) })
                                print(outputString)
                        } else {
                                Log.error("Error printing serialized xml property list representation")
                                Log.logExit(EX_UNAVAILABLE)
                        }
                }
                
                if descriptionOption.value == nil || loaderOption.value == nil {
                        Log.error("Required options should no longer be nil")
                        Log.logExit(EX_DATAERR)
                }
                
                let testCount: Int = 54
                let option = EfiLoadOption(createFromLoaderPath: loaderOption.value!, description: descriptionOption.value!, optionalData: dataStringOption.value)
                let loadOptionData = option.data
                if loadOptionData.count < testCount {
                        Log.error("Variable data is too small")
                        Log.logExit(EX_DATAERR)
                }
                
                /* Output to dmpstore format file */
                
                if outputOption.wasSet {
                        let dmpstoreOption = Dmpstore.Option(fromData: loadOptionData)
                        let dmpstoreOrder = Dmpstore.Order(adding: dmpstoreOption.created)
                        var buffer = Data.init()
                        buffer.append(dmpstoreOption.data)
                        buffer.append(dmpstoreOrder.data)
                        let url = URL(fileURLWithPath: outputOption.value!)
                        do {
                                try buffer.write(to: url)
                        } catch let error as NSError {
                                let errorDescription = error.localizedDescription
                                let errorCode = error.code
                                print(errorDescription)
                                Log.error("Error writing output file (%{public}@)", String(errorCode))
                                Log.logExit(EX_CANTCREAT)
                        }
                        Log.logExit(EX_OK)
                }
                
                /* Printed output */
                
                if appleOption.value {
                        printFormatString(data: loadOptionData)
                } else if xmlOption.value {
                        printXml(data: loadOptionData)
                } else {
                        printRawHex(data: loadOptionData)
                }
                Log.logExit(EX_OK)
                
        default:
                commandLine.printUsage(withMessageForError: optionParser.status)
                Log.logExit(EX_USAGE)
        }
        

}
