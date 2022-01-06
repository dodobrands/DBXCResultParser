//
//  XCResultSeeker.swift
//  
//
//  Created by Алексей Берёзка on 30.12.2021.
//

import Foundation

public class XCResultSeeker {
    public func seek(in path: URL) throws -> [URL] {
        try FileManager
            .default
            .contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            .filter{ $0.pathExtension == "xcresult" }
    }
}
