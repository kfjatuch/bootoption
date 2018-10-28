/*
 * File: NvramHelper.swift
 *
 * bootoption © vulgo 2018 - A command line utility for managing a
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

/* Create boot order data from array */

func newBootOrderData(fromArray bootOrder: [BootNumber]) -> Data {
        var data = Data()
        for bootNumber in bootOrder {
                data.append(bootNumber.data)
        }
        return data
}

/* Boot order array functions adding/removing */

func newBootOrderArray(removing bootNumber: BootNumber) -> [BootNumber]? {
        var newBootOrderArray: [BootNumber] = Nvram.shared.bootOrderArray
        if let index: Int = newBootOrderArray.index(of: bootNumber) {
                newBootOrderArray.remove(at: index)
                Debug.log("Returned an updated boot order array", type: .info)
                return newBootOrderArray
        } else {
                Debug.log("Boot number wasn't found in boot order", type: .info)
        }
        Debug.log("returned nil", type: .info)
        return nil
}

func newBootOrderArray(adding bootNumber: BootNumber, atIndex index: Int = 0) -> [BootNumber]? {
        var newBootOrderArray: [BootNumber] = Nvram.shared.bootOrderArray
        if newBootOrderArray.indices.contains(index) {
                Debug.log("Inserted to boot order at index %@", type: .info, argsList: index)
                newBootOrderArray.insert(bootNumber, at: index)
        } else {
                Debug.log("Index out of range, appending to boot order instead", type: .info)
                newBootOrderArray.append(bootNumber)
        }
        return newBootOrderArray
}

/* Return an unused boot option number to write to */

func discoverEmptyBootNumber() -> BootNumber? {
        for test: BootNumber in 0x0000 ..< 0x007F {
                if let _: Data = Nvram.shared.bootOptionData(test) {
                        continue
                } else {
                        Debug.log("Empty boot option discovered: %@", type: .info, argsList: test.variableName)
                        return test
                }
        }
        Debug.log("Empty option discovery failed", type: .error)
        return nil
}

/* Convert between boot number integer and variable name string */

func bootNumberFromString(_ string: String) -> BootNumber? {
        var mutableString = string.uppercased()
        mutableString = mutableString.replacingOccurrences(of: "0X", with: "")
        mutableString = mutableString.replacingOccurrences(of: "BOOT", with: "")
        let hex = Set("ABCDEF1234567890")
        guard hex.isSuperset(of: mutableString) else {
                Debug.log("Found non-hex characters '%@' while attempting to parse boot number", type: .error, argsList: mutableString)
                print("invalid boot number: '\(string)'", to: &standardError)
                return nil
        }
        guard mutableString.count <= 4 else {
                Debug.log("Boot number string '%@' is too long", type: .error, argsList: mutableString)
                print("invalid boot number: '\(string)'", to: &standardError)
                return nil
        }
        let scanner = Scanner(string: mutableString)
        var scanned: UInt32 = 0
        if !scanner.scanHexInt32(&scanned) {
                Debug.log("Scanning string '%@' to integer failed", type: .error, argsList: mutableString)
                print("invalid boot number: '\(string)'", to: &standardError)
                return nil
        }
        let number = BootNumber(scanned)
        if Nvram.shared.bootOptionData(number) == nil  {
                Debug.log("Boot number from string succeeded but %@ does not exist", type: .error, argsList: number.variableName)
                print("'\(number.variableName)' does not exist", to: &standardError)
                return nil
        }
        Debug.log("0x%@", type: .info, argsList: String(format: "%04X", number))
        return BootNumber(number)
}
