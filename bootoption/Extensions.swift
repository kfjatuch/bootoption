/*
 * File: Extensions.swift
 *
 * bootoption © vulgo 2017 - A command line utility for managing a
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

extension Data {
        
        mutating func removeEfiString() -> String? {
                if self.count < 2 {
                        return nil
                }
                var string = String()
                for _ in 1...(self.count / 2) {
                        if self.count < 2 {
                                break
                        }
                        let bytes: UInt16 = self.remove16()
                        if bytes == 0 {
                                break
                        }
                        if let unicode = UnicodeScalar(bytes) {
                                if 0x20 ... 0xD7FF ~= Int(unicode.value) {
                                        string.append(Character(unicode))
                                } else {
                                        return nil
                                }
                        } else {
                                return nil
                        }
                }
                return string
        }
        
        @discardableResult mutating func remove64() -> UInt64 {
                var buffer = Data.init()
                for _ in 1...8 {
                        buffer.append(self.remove(at: 0))
                }
                return buffer.withUnsafeBytes{$0.pointee}
                
        }
        
        @discardableResult mutating func remove32() -> UInt32 {
                var buffer = Data.init()
                for _ in 1...4 {
                        buffer.append(self.remove(at: 0))
                }
                return buffer.withUnsafeBytes{$0.pointee}
                
        }
        
        @discardableResult mutating func remove16() -> UInt16 {
                var buffer = Data.init()
                for _ in 1...2  {
                        buffer.append(self.remove(at: 0))
                }
                return buffer.withUnsafeBytes{$0.pointee}
        }
        
        @discardableResult mutating func remove8() -> UInt8 {
                return self.remove(at: 0)
        }
        
        @discardableResult mutating func remove(bytesAsData bytes: Int) -> Data {
                var buffer = Data.init()
                for _ in 1...bytes {
                        buffer.append(self.remove(at: 0))
                }
                return buffer
        }
        
}

extension Array {
        mutating func order(from: Int, to: Int) {
                insert(remove(at: from), at: to)
        }
}

extension FileHandle : TextOutputStream {
        public func write(_ string: String) {
                guard let data = string.data(using: .utf8) else { return }
                self.write(data)
        }
}

extension String {
        
        func efiStringData(withNullTerminator: Bool = true) -> Data? {
                let characters = self.characters
                var data = Data()
                for c in characters {
                        if let scalar: Unicode.Scalar = UnicodeScalar(String(c)) {
                                if scalar.value > 0xFFFF {
                                        Log.log("efiStringData(): unicode scalar value out of range")
                                        return nil
                                }
                                var bytes = UInt16(scalar.value)
                                data.append(UnsafeBufferPointer(start: &bytes, count: 1))
                        }
                }
                if withNullTerminator {
                        var null = UInt16(0)
                        data.append(UnsafeBufferPointer(start: &null, count: 1))
                }
                return data
        }

        func toDouble() -> Double? {
                return NumberFormatter().number(from: self)?.doubleValue
        }
        
        func toZeroBasedIndex() -> Int? {
                if let intVal = Int(self) {
                        return intVal - 1
                }
                return nil
        }
        
        func containsOutlawedCharacters() -> Bool {
                let allowed: Set<Character> = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-=(),.!_\\".characters)
                for char in self.characters {
                        if allowed.contains(char) {
                                continue
                        } else {
                                return true
                        }
                }
                return false
        }
        
        func containsNonHexCharacters() -> Bool {
                let allowed: Set<Character> = Set("abcdefABCDEF1234567890".characters)
                for char in self.characters {
                        if allowed.contains(char) {
                                continue
                        } else {
                                return true
                        }
                }
                return false
        }
        
        func subString(from: Int, to: Int) -> String {
                let start: String.Index = self.index(self.startIndex, offsetBy: from)
                let end: String.Index = self.index(self.startIndex, offsetBy: to)
                return String(self[start..<end])
        }
        
        func hexToData(byteSwapped: Bool = false) -> Data? {
                var strings: [String] = Array()
                let width: Int = 2
                let max: Int = self.characters.count
                if byteSwapped {
                        var start: Int = max - width, end: Int = max
                        while start >= 0 {
                                strings.append(self.subString(from: start, to: end))
                                start -= width; end = start + width
                        }
                } else {
                        var start: Int = 0, end: Int = start + width
                        while end <= max {
                                strings.append(self.subString(from: start, to: end))
                                start += width; end = start + width
                        }
                }
                let bytes: [UInt8] = strings.map { UInt8(strtoul(String($0), nil, 16)) }
                return bytes.withUnsafeBufferPointer { Data(buffer: $0) }
        }
        
        func leftPadding(toLength: Int, withPad character: Character) -> String {
                let newLength = self.characters.count
                if newLength < toLength {
                        return String(repeatElement(character, count: toLength - newLength)) + self
                } else {
                        let i:String.Index = index(self.startIndex, offsetBy: newLength - toLength)
                        return String(self[i...])
                }
        }
        
}
