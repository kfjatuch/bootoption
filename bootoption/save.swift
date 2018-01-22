/*
 * File: save.swift
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
        let descriptionOption = StringOption(shortFlag: "d", longFlag: "description", required: 1, helpMessage: "display LABEL in firmware boot manager")
        let dataStringOption = StringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "an optional STRING passed to the loader command line")
        let outputOption = StringOption(shortFlag: "o", longFlag: "output", helpMessage: "write to FILE for use with EDK2 dmpstore", precludes: "x%")
        let appleOption = BoolOption(shortFlag: "%", longFlag: "apple", helpMessage: "print Apple nvram-style string instead of raw hex", precludes: "ox")
        let xmlOption = BoolOption(shortFlag: "x", longFlag: "xml", helpMessage: "print an XML serialization instead of raw hex", precludes: "o%")
        let keyOption = StringOption(shortFlag: "k", longFlag: "key", helpMessage: "specify named KEY, use with option -x")
        commandLine.invocationHelpMessage = "save -l PATH -d LABEL [-a STRING] [-o FILE | -% | -x [-k KEY]]"
        commandLine.setOptions(loaderOption, descriptionOption, dataStringOption, outputOption, appleOption, xmlOption, keyOption)
        
        func saveMain() {
                
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
                let option = EfiLoadOption(createFromLoaderPath: loaderOption.value!, descriptionString: descriptionOption.value!, optionalDataString: dataStringOption.value)
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
                
        }

        let optionParser = OptionParser(options: commandLine.options, rawArguments: commandLine.rawArguments, strict: true)
        switch optionParser.status {
        case .success:
                saveMain()
        default:
                commandLine.printUsage(withMessageForError: optionParser.status)
                Log.logExit(EX_USAGE)
        }
        
}

struct Dmpstore {
        
        static let crc = CRC32()
        
        struct Option {
                static let nameSizeConstant: Int = 18
                var data = Data.init()
                var created: Int? = nil
                let nameSize = Data.init(bytes: [UInt8(Dmpstore.Option.nameSizeConstant), 0x0, 0x0, 0x0])
                var dataSize = Data.init()
                var name: Data?
                let guid = Data.init(bytes: [0x61, 0xdf, 0xe4, 0x8b, 0xca, 0x93, 0xd2, 0x11, 0xaa, 0xd, 0x0, 0xe0, 0x98, 0x3, 0x2b, 0x8c])
                let attributes = Data.init(bytes: [0x7, 0x0, 0x0, 0x0])
                var variableData = Data.init()
                var crc32 = Data.init()
                
                init(fromData variable: Data) {
                        Log.info("Dmpstore.Option.init: Creating a boot variable for dmpstore")
                        var dataSizeValue = UInt32(variable.count)
                        /* store dataSize */
                        self.dataSize.append(UnsafeBufferPointer(start: &dataSizeValue, count: 1))
                        guard let emptyBootOption: Int = nvram.discoverEmptyBootNumber(leavingSpace: true) else {
                                Log.error("Empty boot option is nil")
                                Log.logExit(EX_UNAVAILABLE)
                        }
                        
                        let name = nvram.bootStringFromBoot(number: emptyBootOption)
                        if let nameData = name.efiStringData() {
                                self.name = nameData
                        } else {
                                Log.logExit(EX_SOFTWARE, "Failed to set name, did String.efiStringData() return nil?")
                        }
                        guard let nameData = self.name, nameData.count == Dmpstore.Option.nameSizeConstant else {
                                Log.error("Name is an incorrect size")
                                Log.logExit(EX_SOFTWARE)
                        }
                        
                        /* store variable data */
                        self.variableData.append(variable)
                        
                        var buffer = Data.init()
                        buffer.append(self.nameSize)
                        buffer.append(self.dataSize)
                        buffer.append(nameData)
                        buffer.append(self.guid)
                        buffer.append(self.attributes)
                        buffer.append(self.variableData)
                        
                        crc.run(data: buffer)
                        var crcValue: UInt32 = crc.crc
                        /* store crc32 data */
                        self.crc32.append(UnsafeBufferPointer(start: &crcValue, count: 1))
                        
                        /* store dmpstore data */
                        self.data.append(buffer)
                        self.data.append(self.crc32)
                        
                        /* store created */
                        self.created = emptyBootOption
                        Log.info("Created a new variable")
                }
        }
        
        struct Order {
                var data = Data.init()
                let nameSize = Data.init(bytes: [0x14, 0x0, 0x0, 0x0])
                var dataSize = Data.init()
                var name = Data.init(bytes: [0x42, 0x00, 0x6F, 0x00, 0x6F, 0x00, 0x74, 0x00, 0x4F, 0x00, 0x72, 0x00, 0x64, 0x00, 0x65, 0x00, 0x72, 0x00, 0x00, 0x00])
                let guid = Data.init(bytes: [0x61, 0xdf, 0xe4, 0x8b, 0xca, 0x93, 0xd2, 0x11, 0xaa, 0xd, 0x0, 0xe0, 0x98, 0x3, 0x2b, 0x8c])
                let attributes = Data.init(bytes: [0x7, 0x0, 0x0, 0x0])
                var variableData = Data.init()
                var crc32 = Data.init()
                
                init(adding: Int?) {
                        Log.info("Dmpstore.Order.init: Creating a boot order variable for dmpstore")
                        if adding == nil {
                                Log.error("Option to add is nil")
                                Log.logExit(EX_UNAVAILABLE)
                        }
                        
                        guard let bootOrder: Data = nvram.getBootOrder() else {
                                Log.error("Couldn't get boot order from nvram")
                                Log.logExit(EX_UNAVAILABLE)
                        }
                        
                        // add to boot order and store variable data
                        var newOption = UInt16(adding!)
                        self.variableData.append(UnsafeBufferPointer(start: &newOption, count: 1))
                        self.variableData.append(bootOrder)
                        
                        var dataSizeValue = UInt32(self.variableData.count)
                        /* store dataSize */
                        self.dataSize.append(UnsafeBufferPointer(start: &dataSizeValue, count: 1))
                        
                        var buffer = Data.init()
                        buffer.append(self.nameSize)
                        buffer.append(self.dataSize)
                        buffer.append(self.name)
                        buffer.append(self.guid)
                        buffer.append(self.attributes)
                        buffer.append(self.variableData)
                        
                        crc.run(data: buffer)
                        var crcValue: UInt32 = crc.crc
                        /* store crc32 data */
                        self.crc32.append(UnsafeBufferPointer(start: &crcValue, count: 1))
                        
                        /* store dmpstore data */
                        self.data.append(buffer)
                        self.data.append(self.crc32)
                        Log.info("Created an updated 'BootOrder' variable")
                }
        }
}
