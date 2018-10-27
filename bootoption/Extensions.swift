/*
 * File: Extensions.swift
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

typealias BootNumber = UInt16
extension BootNumber {
        var variableName: String {
                let number = String(format: "%04X", self)
                let name = "Boot\(number)"
                return name
        }
        var variableNameWithGuid: String {
                let name = "8BE4DF61-93CA-11D2-AA0D-00E098032B8C:\(variableName)"
                return name
        }
}

extension UInt64 {
        var data: Data {
                var value: UInt64 = self
                return Data(buffer: UnsafeBufferPointer<UInt64>(start: &value, count: 1))
        }
}

extension UInt32 {
        var data: Data {
                var value: UInt32 = self
                return Data(buffer: UnsafeBufferPointer<UInt32>(start: &value, count: 1))
        }
}

extension UInt16 {
        var data: Data {
                var value: UInt16 = self
                return Data(buffer: UnsafeBufferPointer<UInt16>(start: &value, count: 1))
        }
}

extension UInt8 {
        var data: Data {
                var value: UInt8 = self
                return Data(buffer: UnsafeBufferPointer<UInt8>(start: &value, count: 1))
        }
        
        var ascii: String {
                var string = ""
                if Range(0x21...0x7E).contains(self), let ascii = String(data: self.data, encoding: .ascii) {
                        string.append(ascii)
                } else {
                        string.append(".")
                }
                return string
        }
}

extension Data {
        var debugString: String {
                var string = "<"
                for byte in self {
                        string.append(String(format: "%02x", byte))
                }
                string += ">"
                return string
        }
        
        mutating func removeEfiString() -> String? {
                let sizeUInt16 = 2
                var string = String()
                for _ in 1...(self.count / sizeUInt16) {
                        if self.count < sizeUInt16 {
                                break
                        }
                        let removed: UInt16 = self.remove16()
                        if removed == 0x0000 {
                                break
                        }
                        let unicodeScalar = UnicodeScalar(removed)
                        if unicodeScalar == nil {
                                return nil
                        }
                        let unicodeValue = Int(unicodeScalar!.value)
                        if (unicodeValue < 0x0020) || (unicodeValue > 0xD7FF) {
                                return nil
                        }
                        string.append(Character(unicodeScalar!))
                }
                return string.count > 0 ? string : nil
        }
        
        var uint8: UInt8 {
                let value: UInt8 = self.withUnsafeBytes {
                        (pointer: UnsafePointer<UInt8>) -> UInt8 in
                        return pointer.pointee
                }
                return value
        }
        
        var uint16: UInt16 {
                let value: UInt16 = self.withUnsafeBytes {
                        (pointer: UnsafePointer<UInt16>) -> UInt16 in
                        return pointer.pointee
                }
                return value
        }
        
        var uint32: UInt32 {
                let value: UInt32 = self.withUnsafeBytes {
                        (pointer: UnsafePointer<UInt32>) -> UInt32 in
                        return pointer.pointee
                }
                return value
        }
        
        @discardableResult mutating func remove64() -> UInt64 {
                let range = Range(0...7)
                let buffer: Data = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes{$0.pointee}
        }
        
        @discardableResult mutating func remove32() -> UInt32 {
                let range = Range(0...3)
                let buffer: Data = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes{$0.pointee}
        }
        
        @discardableResult mutating func remove16() -> UInt16 {
                let range = Range(0...1)
                let buffer: Data = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer.withUnsafeBytes{$0.pointee}
        }
        
        @discardableResult mutating func remove8() -> UInt8 {
                return self.remove(at: 0)
        }
        
        @discardableResult mutating func removeData(bytes: Int) -> Data {
                let start = self.startIndex
                let end = index(start, offsetBy: bytes)
                let range = start..<end
                let buffer: Data = self.subdata(in: range)
                self.removeSubrange(range)
                return buffer
        }
}

extension Array {
        mutating func order(itemAtIndex index: Int, to destination: Int) {
                insert(remove(at: index), at: destination)
        }
}

extension FileHandle: TextOutputStream {
        public func write(_ string: String) {
                guard let data = string.data(using: .utf8) else {
                        return
                }
                self.write(data)
        }
}

extension String {
        func efiStringData(nullTerminated: Bool = true) -> Data? {
                var data = Data()
                for character in self {
                        let scalar: Unicode.Scalar? = UnicodeScalar(String(character))
                        guard scalar != nil && scalar!.value > 0x19 && scalar!.value < 0xD800 else {
                                Debug.log("%@ unicode scalar value for '%@' out of range", type: .error, argsList: self, String(character))
                                return nil
                        }
                        data.append(UInt16(scalar!.value).data)
                }
                if nullTerminated {
                        data.append(Data(bytes: [0x00, 0x00]))
                }
                return data
        }
        
        func asciiStringData(nullTerminated: Bool = true) -> Data? {
                guard self.canBeConverted(to: .ascii) else {
                        Debug.log("%@ cannot be converted to ascii", type: .error, argsList: self)
                        return nil
                }
                var data = Data(self.utf8)
                if nullTerminated {
                        data.append(Data(bytes: [0x00]))
                }
                return data
        }

        func toDouble() -> Double? {
                return NumberFormatter().number(from: self)?.doubleValue
        }
        
        func containsOutlawedCharacters() -> Bool {
                let allowed: Set<Character> = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-=(),.!_\\")
                for char in self {
                        if allowed.contains(char) {
                                continue
                        } else {
                                return true
                        }
                }
                return false
        }
        
        func subString(start: Int, end: Int) -> String {
                let start: String.Index = self.index(self.startIndex, offsetBy: start)
                let end: String.Index = self.index(self.startIndex, offsetBy: end)
                return String(self[start..<end])
        }
        
        func leftPadding(toLength: Int, withPad character: Character) -> String {
                let newLength = self.count
                if newLength < toLength {
                        return String(repeatElement(character, count: toLength - newLength)) + self
                } else {
                        let i: String.Index = index(self.startIndex, offsetBy: newLength - toLength)
                        return String(self[i...])
                }
        }
}
