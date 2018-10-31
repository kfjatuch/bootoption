/*
 * File: print.swift
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

/*
 *  Function for command: print
 */

func print() {

        Debug.log("Setting up command line", type: .info)
        let loaderPathOption = StringOption(shortFlag: "l", longFlag: "loader", required: 1, helpMessage: "the PATH to an EFI loader executable")
        let loaderDescriptionOption = StringOption(shortFlag: "d", longFlag: "description", required: 1, helpMessage: "display LABEL in firmware boot manager")
        let loaderCommandLineOption = StringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "an optional STRING passed to the loader command line")
        let ucs2EncodingOption = BoolOption(shortFlag: "u", helpMessage: "pass command line arguments as UCS-2 (default is ASCII)")
        let fileDataOption = StringOption(shortFlag: "f", longFlag: "file", helpMessage: "append binary optional data from FILE", precludes: "au")
        let appleOption = BoolOption(shortFlag: "%", longFlag: "apple", helpMessage: "print Apple nvram-style string instead of raw hex", precludes: "x")
        let xmlOption = BoolOption(shortFlag: "x", longFlag: "xml", helpMessage: "print an XML serialization instead of raw hex", precludes: "%")
        let keyOption = StringOption(shortFlag: "k", longFlag: "key", helpMessage: "specify named KEY, use with option -x")
        commandLine.invocationHelpMessage = "print -l PATH -d LABEL [-a STRING] [-u] [-f FILE]\n\t[-% | -x [-k KEY]]"
        commandLine.setOptions(loaderPathOption, loaderDescriptionOption, loaderCommandLineOption, ucs2EncodingOption, fileDataOption, appleOption, xmlOption, keyOption)
        
        func printMain() {
                
                var fileData: Data?
                
                /* Printed output functions */
                
                func printFormatString(data: Data) {
                        Debug.log("Printing format string", type: .info)
                        let strings = data.map { String(format: "%%%02x", $0) }
                        let outputString = strings.joined()
                        print(outputString)
                }
                
                func printRawHex(data: Data) {
                        Debug.log("Printing raw hex", type: .info)
                        let strings = data.map { String(format: "%02x", $0) }
                        let outputString = strings.joined()
                        print(outputString)
                }
                
                func printXml(data: Data) {
                        Debug.log("Printing XML", type: .info)
                        let key: String = keyOption.value ?? "Boot"
                        let dictionary: NSDictionary = ["\(key)": data]
                        var propertyList: Data
                        do {
                                propertyList = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
                        } catch let error as NSError {
                                let errorDescription = error.localizedDescription
                                let errorCode = error.code
                                print(errorDescription)
                                Debug.log("%@ (%@)", type: .error, argsList: errorDescription, errorCode)
                                Debug.fault("Error serializing to XML")
                        }
                        if let xml = String(data: propertyList, encoding: .utf8) {
                                let outputString = String(xml.filter { !"\n\t\r".contains($0) })
                                print(outputString)
                        } else {
                                Debug.fault("Error printing serialized xml property list representation")
                        }
                }
                
                if loaderDescriptionOption.value == nil || loaderPathOption.value == nil {
                        Debug.fault("Required options should no longer be nil")
                }
                
                /* Read data from file if path specified */
                
                if let filePath = fileDataOption.value {
                        guard FileManager.default.fileExists(atPath: filePath) else {
                                Debug.fault("\(filePath) not found")
                        }
                        let data = NSData.init(contentsOfFile: filePath)
                        guard data != nil else {
                                Debug.fault("Data from \(filePath) should no longer be nil")
                        }
                        fileData = data as Data?
                }
                
                let testCount: Int = 54
                let option = EfiLoadOption(createFromLoaderPath: loaderPathOption.value!, descriptionString: loaderDescriptionOption.value!, optionalDataString: loaderCommandLineOption.value, ucs2OptionalData: ucs2EncodingOption.value, optionalDataRaw: fileData)
                let loadOptionData = option.data
                if loadOptionData.count < testCount {
                        Debug.fault("Variable data is too small")
                }
                
                /* Printed output */
                
                if appleOption.value {
                        printFormatString(data: loadOptionData)
                } else if xmlOption.value {
                        printXml(data: loadOptionData)
                } else {
                        printRawHex(data: loadOptionData)
                }
                Debug.terminate(EX_OK)
                
        }

        commandLine.parseOptions(strict: true)
        switch commandLine.parserStatus {
        case .success:
                printMain()
        default:
                commandLine.printErrorAndUsage()
                Debug.terminate(EX_USAGE)
        }
        
}

