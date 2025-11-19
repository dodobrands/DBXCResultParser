//
//  BuildResultsDTO.swift
//
//
//  Created on 19.11.2025.
//

import Foundation

struct BuildResultsDTO: Decodable {
    let actionTitle: String?
    let destination: Device
    let startTime: Double
    let endTime: Double
    let status: String?
    let analyzerWarningCount: Int?
    let errorCount: Int?
    let warningCount: Int?
    let analyzerWarnings: [Issue]
    let warnings: [Issue]
    let errors: [Issue]

    struct Device: Decodable {
        let deviceId: String
        let deviceName: String
        let architecture: String
        let modelName: String
        let platform: String?
        let osVersion: String
        let osBuildNumber: String?
    }

    struct Issue: Decodable {
        let issueType: String
        let message: String
        let targetName: String?
        let sourceURL: String?
        let className: String?
    }
}
