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

let result: String
switch mode {
case "total":
    result = try! parser.parseTotalTests()
case "skipped":
    result = try! parser.parseSkippedTests()
case "failed":
    result = try! parser.parseFailedTests()
case "list":
    result = try! parser.parseList()
default:
    result = "Unknow argument"
}

print("\(result)")
