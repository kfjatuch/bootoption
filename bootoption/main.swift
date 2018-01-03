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

var pathToEfiExecutable: String?
var bootOptionDescription: String?
var outputPath: String?
var outputToFile: Bool = false
var outputFormatString: Bool = false
var outputXml: Bool = false
var testCount: Int = 54
var key: String = "Boot"

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

func main() {
        
        /* Attributes */
        
        let attributes = Data.init(bytes: [1, 0, 0, 0])
        
        /* Description */
        
        if bootOptionDescription!.containsOutlawedCharacters() {
                fatalError("Forbidden character(s) found in description")
        }
        
        var description = bootOptionDescription!.data(using: String.Encoding.utf16)!
        description.removeFirst()
        description.removeFirst()
        description.append(contentsOf: [0, 0])
        
        /* Device path list */
        
        var devicePathList = Data.init()
        let hardDrive = HardDriveMediaDevicePath(forFile: pathToEfiExecutable!)
        let file = FilePathMediaDevicePath(path: pathToEfiExecutable!, mountPoint: hardDrive.mountPoint)
        let end = EndDevicePath()
        devicePathList.append(hardDrive.data)
        devicePathList.append(file.data)
        devicePathList.append(end.data)
        
        /* Device path list length */
        
        var devicePathListLength = Data.init()
        var lengthValue = UInt16(devicePathList.count)
        devicePathListLength.append(UnsafeBufferPointer(start: &lengthValue, count: 1))
        
        /* Boot option variable data */
        
        var efiLoadOption = Data.init()
        efiLoadOption.append(attributes)
        efiLoadOption.append(devicePathListLength)
        efiLoadOption.append(description)
        efiLoadOption.append(devicePathList)
        
        if outputToFile {
                let data = efiLoadOption as NSData
                let dictionary: NSDictionary = ["\(key)": data]
                let url = URL(fileURLWithPath: outputPath!)
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
        
        if outputFormatString {
                printFormatString(data: data)
        } else if outputXml {
                printXml(data: data)
        } else {
                printRawHex(data: data)
        }
        exit(0)

}

func usage() {
        let basename = NSString(string: CommandLine.arguments[0]).lastPathComponent
        print("Usage: \(basename) -p path -d description [-o file [-k key] | -x [-k key] | -f]")
        print("  -p path to an EFI executable")
        print("  -d description for the boot option")
        print("  -o output to file (XML property list)")
        print("  -k dictionary key, defaults to Boot")
        print("  -x print XML instead of raw hex")
        print("  -f print format string instead of raw hex")
        exit(1)
}

func tooManyOptions() {
        print("Too many options")
        usage()
}

while case let option = getopt(CommandLine.argc, CommandLine.unsafeArgv, "p:d:o:k:xf"), option != -1 {
        switch UnicodeScalar(CUnsignedChar(option)) {
        case "p":
                pathToEfiExecutable = String(cString: optarg)
        case "d":
                bootOptionDescription = String(cString: optarg)
        case "o":
                if outputXml || outputFormatString {
                        tooManyOptions()
                }
                outputPath = String(cString: optarg)
                outputToFile = true
        case "k":
                key = String(cString: optarg)
        case "x":
                if outputToFile || outputFormatString {
                        tooManyOptions()
                }
                outputXml = true
        case "f":
                if outputToFile || outputXml {
                        tooManyOptions()
                }
                outputFormatString = true
        default:
                usage()
        }
}

if pathToEfiExecutable == nil || bootOptionDescription == nil || (outputToFile == true && outputPath == nil) {
        usage()
}

main()
