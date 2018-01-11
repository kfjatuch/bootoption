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

        Log.info("Setting up command line")
        let variableOption = StringOption(longFlag: "variable", required: true, helpMessage: "the NAME of the variable to delete")
        commandLine.invocationHelpMessage = "delete --variable NAME"
        commandLine.setOptions(variableOption)
        do {
                try commandLine.parse(strict: true)
        } catch {
                commandLine.printUsageToStandardError(withError: error)
                exit(EX_USAGE)
        }
        
        let result = nvram.bootNumberFromBoot(string: variableOption.value ?? "")
        
        /* BootNumber */
        guard let bootNumber: Int = result else {
                print("Supplied Boot#### name is invalid", to: &standardError)
                commandLine.printUsageToStandardError()
                exit(EX_USAGE)
        }
        
        let bootOrder: [UInt16]? = nvram.getBootOrderArray()
        if let _: Int = bootOrder?.index(of: UInt16(bootNumber)) {
                /* remove from boot order */
                let newBootOrder = nvram.removeFromBootOrder(number: bootNumber)
                if newBootOrder == nil {
                        Log.error("Error removing Boot#### from BootOrder")
                } else {
                        Log.info("Asked the kernel to update the boot order")
                        /* delete the entry variable */
                        let name: String = nvram.bootStringFromBoot(number: bootNumber)
                        Log.info("Asked the kernel to delete %{public}@", name)
                        nvram.deleteBootOption(Int(bootNumber))
                }
        } else {
                /* variable is not in the boot order, just 'delete' it */
                Log.info("Variable not found in boot order")
                nvram.deleteBootOption(Int(bootNumber))
        }
}

