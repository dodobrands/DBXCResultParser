//
//  Constants.swift
//
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation
import Testing

@testable import DBXCResultParser

struct Constants {
    static var resourcesPath: URL {
        get throws {
            try testsReportPath.deletingLastPathComponent()
        }
    }

    static var testsReportPath: URL {
        get throws {
            try path(filename: "DBXCResultParser", type: "xcresult")
        }
    }

    static private func path(filename: String, type: String) throws -> URL {
        guard let path = Bundle.module.path(forResource: filename, ofType: type) else {
            throw TestError("Could not find resource: \(filename).\(type)")
        }
        guard let url = URL(string: path) else {
            throw TestError("Could not create URL from path: \(path)")
        }
        return url
    }
}

private struct TestError: Error {
    let message: String
    init(_ message: String) {
        self.message = message
    }
}
