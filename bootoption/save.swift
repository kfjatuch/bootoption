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

/*
 *  Function for verb: save
 */

func save() {

        Log.info("Setting up command line")
        let loaderPathOption = StringOption(shortFlag: "l", longFlag: "loader", required: 1, helpMessage: "the PATH to an EFI loader executable")
        let loaderDescriptionOption = StringOption(shortFlag: "d", longFlag: "description", required: 1, helpMessage: "display LABEL in firmware boot manager")
        let loaderCommandLineOption = StringOption(shortFlag: "a", longFlag: "arguments", helpMessage: "an optional STRING passed to the loader command line")
        let outputOption = StringOption(shortFlag: "o", longFlag: "output", helpMessage: "write to FILE for use with EDK2 dmpstore", precludes: "x%")
        let appleOption = BoolOption(shortFlag: "%", longFlag: "apple", helpMessage: "print Apple nvram-style string instead of raw hex", precludes: "ox")
        let xmlOption = BoolOption(shortFlag: "x", longFlag: "xml", helpMessage: "print an XML serialization instead of raw hex", precludes: "o%")
        let keyOption = StringOption(shortFlag: "k", longFlag: "key", helpMessage: "specify named KEY, use with option -x")
        commandLine.invocationHelpMessage = "save -l PATH -d LABEL [-a STRING] [-o FILE | -% | -x [-k KEY]]"
        commandLine.setOptions(loaderPathOption, loaderDescriptionOption, loaderCommandLineOption, outputOption, appleOption, xmlOption, keyOption)
        
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
                        if let xml = String(data: propertyList, encoding: .utf8) {
                                let outputString = String(xml.filter { !"\n\t\r".contains($0) })
                                print(outputString)
                        } else {
                                Log.error("Error printing serialized xml property list representation")
                                Log.logExit(EX_UNAVAILABLE)
                        }
                }
                
                if loaderDescriptionOption.value == nil || loaderPathOption.value == nil {
                        Log.error("Required options should no longer be nil")
                        Log.logExit(EX_DATAERR)
                }
                
                let testCount: Int = 54
                let option = EfiLoadOption(createFromLoaderPath: loaderPathOption.value!, descriptionString: loaderDescriptionOption.value!, optionalDataString: loaderCommandLineOption.value)
                let loadOptionData = option.data
                if loadOptionData.count < testCount {
                        Log.error("Variable data is too small")
                        Log.logExit(EX_DATAERR)
                }
                
                /* Output to dmpstore format file */
                
                if outputOption.wasSet {
                        let dmpstoreOption = Dmpstore.Option(fromData: loadOptionData)
                        let dmpstoreOrder = Dmpstore.Order(bootNumberToAdd: dmpstoreOption.created!)
                        var buffer = Data()
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
                var data = Data()
                var created: Int? = nil
                let nameSize = Data(bytes: [UInt8(Dmpstore.Option.nameSizeConstant), 0x0, 0x0, 0x0])
                var dataSize = Data()
                var name: Data
                let guid = Data(bytes: [0x61, 0xdf, 0xe4, 0x8b, 0xca, 0x93, 0xd2, 0x11, 0xaa, 0xd, 0x0, 0xe0, 0x98, 0x3, 0x2b, 0x8c])
                let attributes = Data(bytes: [0x7, 0x0, 0x0, 0x0])
                var variableData = Data()
                var crc32 = Data()
                
                init(fromData variable: Data) {
                        
                        Log.info("Dmpstore.Option.init: Creating a boot variable for dmpstore")
                        var dataSize = UInt32(variable.count)
                        self.dataSize.append(UnsafeBufferPointer(start: &dataSize, count: 1))
                        guard let bootNumber: Int = nvram.discoverEmptyBootNumber(leavingSpace: true) else {
                                Log.logExit(EX_UNAVAILABLE, "Empty boot option is nil")
                        }
                        if let name: Data = String(nvram.bootStringFromNumber(bootNumber)).efiStringData() {
                                self.name = name
                        } else {
                                Log.logExit(EX_SOFTWARE, "Failed to set name, did String.efiStringData() return nil?")
                        }
                        guard self.name.count == Dmpstore.Option.nameSizeConstant else {
                                Log.logExit(EX_SOFTWARE, "Name is an incorrect size")
                        }
                        
                        /* Variable data */
                        
                        self.variableData.append(variable)
                        var buffer = Data()
                        buffer.append(self.nameSize)
                        buffer.append(self.dataSize)
                        buffer.append(self.name)
                        buffer.append(self.guid)
                        buffer.append(self.attributes)
                        buffer.append(self.variableData)
                        
                        /* CRC32 */
                        
                        crc.run(data: buffer)
                        var crcValue: UInt32 = crc.crc
                        self.crc32.append(UnsafeBufferPointer(start: &crcValue, count: 1))
                        
                        /* Store data + CRC32 */
                        
                        self.data.append(buffer)
                        self.data.append(self.crc32)
                        
                        /* Boot number of created variable */
                        
                        self.created = bootNumber
                        Log.info("Created a new variable")
                }
        }
        
        struct Order {
                
                var data = Data()
                let nameSize = Data(bytes: [0x14, 0x0, 0x0, 0x0])
                var dataSize = Data()
                var name = Data(bytes: [0x42, 0x00, 0x6F, 0x00, 0x6F, 0x00, 0x74, 0x00, 0x4F, 0x00, 0x72, 0x00, 0x64, 0x00, 0x65, 0x00, 0x72, 0x00, 0x00, 0x00])
                let guid = Data(bytes: [0x61, 0xdf, 0xe4, 0x8b, 0xca, 0x93, 0xd2, 0x11, 0xaa, 0xd, 0x0, 0xe0, 0x98, 0x3, 0x2b, 0x8c])
                let attributes = Data(bytes: [0x7, 0x0, 0x0, 0x0])
                var variableData = Data()
                var crc32 = Data()
                
                init(bootNumberToAdd bootNumber: Int) {
                        
                        Log.info("Dmpstore.Order.init: Creating a boot order variable for dmpstore")
                        guard let bootOrder: Data = nvram.getBootOrder() else {
                                Log.logExit(EX_UNAVAILABLE, "Couldn't get boot order from nvram")
                        }
                        
                        /* Add to boot order and store variable data */
                        
                        var newOption = UInt16(bootNumber)
                        variableData.append(UnsafeBufferPointer(start: &newOption, count: 1))
                        variableData.append(bootOrder)
                        
                        /* Data size */
                        
                        var dataSize = UInt32(self.variableData.count)
                        self.dataSize.append(UnsafeBufferPointer(start: &dataSize, count: 1))
                        
                        /* Variable data */
                        
                        var buffer = Data()
                        buffer.append(self.nameSize)
                        buffer.append(self.dataSize)
                        buffer.append(self.name)
                        buffer.append(self.guid)
                        buffer.append(self.attributes)
                        buffer.append(self.variableData)
                        
                        /* CRC32 */
                        
                        crc.run(data: buffer)
                        var crcValue: UInt32 = crc.crc
                        self.crc32.append(UnsafeBufferPointer(start: &crcValue, count: 1))
                        
                        /* Store variable data + CRC32 */
                        
                        self.data.append(buffer)
                        self.data.append(self.crc32)
                        Log.info("Created an updated 'BootOrder' variable")
                }
        }
}
