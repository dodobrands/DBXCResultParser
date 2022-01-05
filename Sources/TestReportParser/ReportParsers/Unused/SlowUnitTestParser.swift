//
//  SlowUnitTestReportParser.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

//import Foundation
//import XMLCoder
//
///// Search for slowest tests
//class SlowUnitTestReportParser: FileParser {
//    func parse() -> TestSuites {
//        try! XMLDecoder().decode(TestSuites.self,
//                                 from: data())
//    }
//    
//    let threeshold: TimeInterval = 0.1
//    func analyze(report: TestSuites) {
//        let times = report.testsuite
//            .filter({ suite in
//                suite.totalTime > threeshold
//            })
//            .sorted(by: { suite1, suite2 in
//                suite1.totalTime > suite2.totalTime
//            })
//        
//            .map { suite in
//                (suite.name, suite.totalTime)
//            }
//        
//        let numberFormatter = NumberFormatter.slowTestsFormatter
//        
//        for time in times {
//            let number = numberFormatter.string(from: NSNumber(value: time.1))!
//            print("\(number) \(time.0)")
//        }
//        
//        let longestTime = times
//            .map({ (String, timeInterval) in
//                timeInterval
//            })
//            .reduce(0, +)
//        
//        let totalTime = report.testsuite.reduce(0) { result, suite in
//            result + suite.totalTime
//        }
//        print("\(times.count) spent \(longestTime), total: \(totalTime), \(longestTime/totalTime)")
//    }
//}
//
//fileprivate extension NumberFormatter {
//    static var slowTestsFormatter: NumberFormatter {
//        let numberFormatter = NumberFormatter()
//        numberFormatter.numberStyle = .decimal
//        numberFormatter.minimumFractionDigits = 3
//        return numberFormatter
//    }
//}
