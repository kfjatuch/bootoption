/*
 * File: delete.swift
 *
 * bootoption © vulgo 2018 - A program to create / save an EFI boot
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

func delete() {
        let bootVariableName = StringOption(longFlag: "variable", required: true, helpMessage: "the NAME of the variable to delete")
        
        commandLine.invocationHelpText = "delete --variable NAME"
        commandLine.setOptions(bootVariableName)
        do {
                try commandLine.parse(strict: true)
        } catch {
                commandLine.printUsage(error: error)
                exit(EX_USAGE)
        }
        
        func invalidArgument(_ string: String) {
                var out = CommandLine.StderrOutputStream.stream
                print("Invalid name for BootXXXX variable: \(string)", to: &out)
                commandLine.printUsage()
        }
        
        if let choice: String = bootVariableName.value {
                guard choice.characters.count == 8 && choice.uppercased().hasPrefix("BOOT") else {
                        invalidArgument(choice)
                        exit(EX_USAGE)
                }
                let hexString: String = choice.subString(from: 4, to: 8)
                if hexString.containsNonHexCharacters() {
                        invalidArgument(choice)
                        exit(EX_USAGE)
                }
                let scanner = Scanner.init(string: hexString)
                var optionNumber: UInt32 = 0
                if !scanner.scanHexInt32(&optionNumber) || nvram.getBootOption(Int(optionNumber)) == nil {
                        invalidArgument(choice)
                        exit(EX_USAGE)
                }
                
                /* option exists */
                
                /*
                 *  to do: confirm removal
                 */

                /* update boot order if necessary */
                var bootOrder: [UInt16]? = nvram.getBootOrderArray()
                if let index: Int = bootOrder?.index(of: UInt16(optionNumber)) {
                        /* option also exists in bootOrder, remove it */
                        bootOrder?.remove(at: index)
                        /* make the new bootorder */
                        var newBootOrder = Data.init()
                        if !bootOrder!.isEmpty {
                                for option in bootOrder! {
                                        var buffer = option
                                        newBootOrder.append(UnsafeBufferPointer(start: &buffer, count: 1))
                                }
                        }
                        /* set the new bootorder */
                        if !nvram.setBootOrder(data: newBootOrder) {
                                 print("Error setting boot order")
                        }
                }
                /* delete the entry variable */
                nvram.deleteBootOption(Int(optionNumber))

        }
        
        
}

