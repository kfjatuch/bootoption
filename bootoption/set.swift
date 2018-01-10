/*
 * File: set.swift
 *
 * bootoption © vulgo 2017-2018 - A program to create / save an EFI boot
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

func set() {

        Log.info("Setting up command line")
        let loaderOption = StringOption(shortFlag: "l", longFlag: "loader", required: true, helpMessage: "the PATH to an EFI loader executable")
        let labelOption = StringOption(shortFlag: "L", longFlag: "label", required: true, helpMessage: "display LABEL in firmware boot manager")
        let unicodeOption = StringOption(shortFlag: "u", longFlag: "unicode", helpMessage: "an optional STRING passed to the loader command line")
        commandLine.invocationHelpMessage = "set -l PATH -L LABEL [-u STRING]"
        commandLine.setOptions(loaderOption, labelOption, unicodeOption)
        do {
                try commandLine.parse(strict: true)
        } catch {
                commandLine.printUsageToStandardError(withError: error)
                exit(EX_USAGE)
        }
        
        /* Set in NVRAM */
        
        let data = efiLoadOption(loader: loaderOption.value!, label: labelOption.value!, unicode: unicodeOption.value)

        if let n: Int = nvram.createNewBootOption(withData: data, addToBootOrder: true) {
                let name = nvram.bootOptionName(for: n)
                Log.info("Set new boot variable %{public}@ in NVRAM", args: String(name))
                exit(0)
        } else {
                print("Error: Couldn't set variables in NVRAM")
                exit(1)
        }
}
