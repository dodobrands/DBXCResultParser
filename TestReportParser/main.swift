//
//  main.swift
//  TestReportParser
//
//  Created by Станислав Карпенко on 23.04.2021.
//

import TestParser
import Foundation

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path)
let parser = ReportParser(folder: url)
let result = try! parser.parse()
print("\(result)")


