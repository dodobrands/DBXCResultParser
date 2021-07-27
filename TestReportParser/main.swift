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
let url = URL(fileURLWithPath: path)
let parser = ReportParser(filePath: url)
let result = parser.parse(mode: mode)

print("\(result)")
