//
//  File.swift
//  
//
//  Created by Mikhail Rubanov on 07.06.2021.
//
import XCTest
import XMLCoder
import Foundation

@testable import TestParser

class UnitXMLParserTests: XCTestCase {
    func testExample2() throws {
        let sourceXML =
            """
<?xml version='1.0' encoding='UTF-8'?>
<testsuites name='DIDTestHelpers-Unit-Tests.xctest' tests='3809' failures='0'>
    <testsuite name='DodoPizzaTests.ActiveOrdersBadgeServiceSpec' tests='5' failures='0'>
        <testcase classname='DodoPizzaTests.ActiveOrdersBadgeServiceSpec' name='ActiveOrdersBadgeService__badge_count__delivery_orders__should_be_skipped' time='1.014'/>
        <testcase classname='DodoPizzaTests.ActiveOrdersBadgeServiceSpec' name='ActiveOrdersBadgeService__badge_count__carryout_orders__skipped_states__should_be_skipped' time='0.004'/>
        <testcase classname='DodoPizzaTests.ActiveOrdersBadgeServiceSpec' name='ActiveOrdersBadgeService__badge_count__carryout_orders__non_skipped_states__should_not_be_skipped' time='0.003'/>
        <testcase classname='DodoPizzaTests.ActiveOrdersBadgeServiceSpec' name='ActiveOrdersBadgeService__badge_count__restaurant_orders__skipped_states__should_be_skipped' time='0.003'/>
        <testcase classname='DodoPizzaTests.ActiveOrdersBadgeServiceSpec' name='ActiveOrdersBadgeService__badge_count__restaurant_orders__non_skipped_states__should_not_be_skipped' time='0.003'/>
    </testsuite>
</testsuites>
"""
        let report = try! XMLDecoder().decode(TestSuites.self,
                                              from: Data(sourceXML.utf8))
        XCTAssertEqual(report.tests, 3809)
        XCTAssertEqual(report.name, "DIDTestHelpers-Unit-Tests.xctest")
        XCTAssertEqual(report.failures, 0)
        XCTAssertEqual(report.testsuite.count, 1)
        
        let suite = try XCTUnwrap(report.testsuite.first)
        XCTAssertEqual(suite.testcase.count, 5)
        
        let test = try XCTUnwrap(suite.testcase.first)
        XCTAssertEqual(test.classname, "DodoPizzaTests.ActiveOrdersBadgeServiceSpec")
        XCTAssertEqual(test.name, "ActiveOrdersBadgeService__badge_count__delivery_orders__should_be_skipped")
        XCTAssertEqual(test.time, 1.014)
    }
}

class UnitParserTests: XCTestCase {
    func testExample2() throws {
        let path = Bundle.module.url(forResource: "report",
                                     withExtension: "junit")!
        let parser = UnitTestParser(filePath: path)
        
        let report = parser.parse()
        
        XCTAssertEqual(report.tests, 3809)
        XCTAssertEqual(report.testsuite.count, 514)
        
        XCTAssertEqual(report.totalTime, 63.427, accuracy: 0.001)
        
        parser.analyze(report: report)
    }
}
