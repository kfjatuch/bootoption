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
        let optionalDataStringOption = StringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "optional STRING passed to the loader command line", invalidates: "@")
        let ucs2EncodingOption = BoolOption(shortFlag: "u", helpMessage: "pass command line arguments as UCS-2 (default is ASCII)", invalidates: "@")
        let optionalDataFilePathOption = FilePathOption(shortFlag: "@", longFlag: "optional-data", helpMessage: "append optional data from FILE", invalidates: "a", "u")
        let appleOption = BoolOption(shortFlag: "%", longFlag: "apple", helpMessage: "print Apple nvram-style string instead of raw hex", invalidates: "x")
        let xmlOption = BoolOption(shortFlag: "x", longFlag: "xml", helpMessage: "print an XML serialization instead of raw hex", invalidates: "%")
        let keyOption = StringOption(shortFlag: "k", longFlag: "key", helpMessage: "specify named KEY, use with option -x")
        commandLine.invocationHelpMessage = "print -l PATH -d LABEL [-a STRING [-u] | -@ FILE]\n\t[-% | -x [-k KEY]]"
        commandLine.setOptions(loaderPathOption, loaderDescriptionOption, optionalDataStringOption, ucs2EncodingOption, optionalDataFilePathOption, appleOption, xmlOption, keyOption)
        
        commandLine.parseOptions(strict: true)
        
        var optionalData: Any?
        
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
        
        /* Optional data */
        
        optionalData = OptionalData.selectSourceFrom(data: optionalDataFilePathOption.data, arguments: optionalDataStringOption.value)
        
        /* EFI load option */
        
        let testCount: Int = 54
        let option = EfiLoadOption(createFromLoaderPath: loaderPathOption.value!, descriptionString: loaderDescriptionOption.value!, optionalData: optionalData, ucs2OptionalData: ucs2EncodingOption.value)
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

