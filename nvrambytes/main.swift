/*
 * File: main.swift
 *
 * nvrambytes © vulgo 2017 - Generate a formatted string from an XML
 * property list for use with Apple's nvram command
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

func output(data: Data) -> Bool {
        if data.count > 32 {
                var outputString: String = ""
                for byte in data {
                        let formattedByteString = String.init(format: "%%%02x", arguments: [byte as CVarArg])
                        outputString.append(formattedByteString)
                }
                print(outputString)
                return true
        }
        return false
}

func main() {
        let argc = CommandLine.argc
        if argc == 2 {
                let fileName = CommandLine.arguments[1]
                let path = NSString(string: fileName).expandingTildeInPath
                let url = URL.init(fileURLWithPath: path)
                let dictionary = NSDictionary.init(contentsOf: url)
                if let data = dictionary?.value(forKey: "Boot") as? Data {
                        if output(data: data) {
                                exit(0)
                        }
                }
        }
        exit(1)
}

main()
