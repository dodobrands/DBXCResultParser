//
//  Shell.swift
//  
//
//  Created by Алексей Берёзка on 28.12.2021.
//

import Foundation

class Shell {
    @discardableResult
    static func execute(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
