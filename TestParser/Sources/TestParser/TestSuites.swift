//
//  TestSuites.swift
//  
//
//  Created by Mikhail Rubanov on 06.06.2021.
//

import Foundation

struct TestSuites: Codable {
    let name: String
    let tests: Int
    let failures: Int
    
    let testsuite: [TestSuite]
    var totalTime: TimeInterval {
        testsuite.reduce(0) { result, suite in
            result + suite.totalTime
        }
    }
}

struct TestSuite: Codable {
    let name: String
    let testcase: [TestCase]
    
    var totalTime: TimeInterval {
        testcase.reduce(0) { result, testcase in
            result + testcase.time
        }
    }
}

struct TestCase: Codable {
    let classname: String
    let name: String
    let time: TimeInterval
}
