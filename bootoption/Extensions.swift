/*
 * File: Extensions.swift
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

extension String {
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
        
        func hexToData(swap: Bool = false) -> Data? {
                var strings: [String] = Array()
                let width: Int = 2
                let max: Int = self.characters.count
                if swap {
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




extension Int {
        func times(f: () -> ()) {
                if self > 0 {
                        for _ in 0..<self {
                                f()
                        }
                }
        }
        func times(f: @autoclosure () -> ()) {
                if self > 0 {
                        for _ in 0..<self {
                                f()
                        }
                }
        }
}




@discardableResult func remove64BitInt(from: inout Data) -> UInt64 {
        var buffer = Data.init()
        8.times {
               buffer.append(from.remove(at: 0))
        }
        return buffer.withUnsafeBytes{$0.pointee}

}

@discardableResult func remove32BitInt(from: inout Data) -> UInt32 {
        var buffer = Data.init()
        4.times {
                buffer.append(from.remove(at: 0))
        }
        return buffer.withUnsafeBytes{$0.pointee}
        
}

@discardableResult func remove16BitInt(from: inout Data) -> UInt16 {
        var buffer = Data.init()
        2.times {
                buffer.append(from.remove(at: 0))
        }
        return buffer.withUnsafeBytes{$0.pointee}
}

@discardableResult func remove8BitInt(from: inout Data) -> UInt8 {
        return from.remove(at: 0)
}

/*
 *   Data return type
 */

@discardableResult func remove(from: inout Data, bytes: Int) -> Data {
        var buffer = Data.init()
        Int(bytes).times {
                buffer.append(from.remove(at: 0))
        }
        return buffer
}
