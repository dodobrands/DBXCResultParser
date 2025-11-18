//
//  Math.swift
//
//
//  Created by Алексей Берёзка on 05.01.2022.
//

import Foundation

extension Sequence where Element: AdditiveArithmetic {
    /// Returns the total sum of all elements in the sequence
    func sum() -> Element {
        reduce(.zero, +)
    }
}

extension Collection where Element: BinaryFloatingPoint {
    /// Returns the average of all elements in the array
    func average() -> Element {
        isEmpty ? .zero : sum() / Element(count)
    }
}
