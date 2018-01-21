/*
 * File: order.swift
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

func orderUsage() {
        print("Usage: bootoption order <current position> to <new position>" , to: &standardError)
        Log.logExit(EX_USAGE)
}

func changePosition(from optionIndex: Int, to destination: Int) {
        if commandLine.userName != "root" {
                Log.logExit(EX_NOPERM, "Only root can modify the boot order.")
        }
        if var bootOrder = nvram.getBootOrderArray() {
                let i = bootOrder.indices
                guard i.contains(optionIndex) && i.contains(destination) else {
                        Log.error("Index out of range")
                        Log.logExit(EX_SOFTWARE)
                }
                // Re-order array
                bootOrder.order(from: optionIndex, to: destination)
                // Get data
                let data = nvram.bootOrderData(fromArray: bootOrder)
                // Set bootorder
                if !nvram.setBootOrder(data: data) {
                        Log.error("Error setting new boot order")
                        Log.logExit(EX_UNAVAILABLE)
                }
                Log.logExit(EX_OK)
        } else {
                Log.error("Couldn't read boot order")
                Log.logExit(EX_UNAVAILABLE)
        }
}

func order() {
        var arguments = commandLine.rawArguments
        var optionIndex: Int?
        var destination: Int?
        
        switch arguments.count {
        case 2:
                optionIndex = arguments[0].toZeroBasedIndex()
                destination = arguments[1].toZeroBasedIndex()
        case 3:
                let preposition = arguments[1].lowercased()
                if preposition == "to" || preposition == "-to" || preposition == "--to" {
                        optionIndex = arguments[0].toZeroBasedIndex()
                        destination = arguments[2].toZeroBasedIndex()
                }
        default:
                orderUsage()
        }
        
        if optionIndex == nil || destination == nil {
                orderUsage()
        } else {
                changePosition(from: optionIndex!, to: destination!)
        }
}
