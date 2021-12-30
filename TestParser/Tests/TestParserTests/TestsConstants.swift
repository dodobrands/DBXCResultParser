//
//  TestsConstants.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

struct TestsConstants {
    private static var projectPath: URL? {
        Process().currentDirectoryURL?.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
    
    static var resourcesPath: URL? {
        projectPath?.appendingPathComponent("TestParser/Sources/TestParser/Resources")
    }
}
