//
//  ReusedDTO.swift
//  
//
//  Created by Алексей Берёзка on 05.01.2022.
//

import Foundation

struct StringReference: Codable {
    let id: StringValueDTO
}

struct StringValueDTO: Codable {
    let _value: String
}
