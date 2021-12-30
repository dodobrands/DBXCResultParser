//
//  main.swift
//  TestReportParser
//
//  Created by Станислав Карпенко on 23.04.2021.
//

import Foundation
import TestParser

let path = CommandLine.arguments[1]
let mode = CommandLine.arguments[2]
let parserMode = ParserMode(rawValue: mode)!
let url = URL(fileURLWithPath: path)
let parser = try ReportParser(filePath: url)
let result = try parser.parse(mode: parserMode)

print("\(result)")
