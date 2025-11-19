import Foundation

extension Measurement where UnitType: UnitDuration {
    public static func testMake(
        unit: UnitDuration = .milliseconds,
        value: Double = 0
    ) -> Measurement<UnitDuration> {
        .init(value: value, unit: unit)
    }

    public static func * (left: Self, right: Int) -> Self {
        .init(value: left.value * Double(right), unit: left.unit)
    }

    public static func / (left: Self, right: Int) -> Self {
        .init(value: left.value / Double(right), unit: left.unit)
    }
}
