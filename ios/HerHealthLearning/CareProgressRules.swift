import Foundation

enum CareProgressRules {
    static let initialNeed = 55
    static let minimumNeed = 15
    static let startingCare = 20
    static let maximumCare = 100
    static let badgeCareThreshold = 80

    static func normalizeNeed(_ value: Int) -> Int {
        max(minimumNeed, max(0, value))
    }

    static func decay(_ value: Int, days: Int) -> Int {
        let elapsedDays = max(0, days)
        let decayed = Int(Double(normalizeNeed(value)) * pow(0.5, Double(elapsedDays)))
        return normalizeNeed(decayed)
    }

    static func dailyCare(starting: [Int], current: [Int]) -> Int {
        guard starting.count == current.count, !starting.isEmpty else { return startingCare }
        let room = starting.reduce(0) { $0 + (100 - min(100, max(0, $1))) }
        guard room > 0 else { return maximumCare }
        let restored = zip(starting, current).reduce(0) { total, pair in
            total + max(0, min(100, pair.1) - min(100, max(0, pair.0)))
        }
        return min(maximumCare, startingCare + restored * (maximumCare - startingCare) / room)
    }

    static func applying(_ requested: Int, to needs: [Int]) -> (needs: [Int], applied: Int) {
        guard requested > 0, !needs.isEmpty else { return (needs, 0) }
        var updated = needs.map { min(100, max(0, $0)) }
        var remaining = requested
        while remaining > 0, let index = updated.indices
            .filter({ updated[$0] < 100 })
            .min(by: { updated[$0] < updated[$1] }) {
            let amount = min(remaining, 100 - updated[index])
            updated[index] += amount
            remaining -= amount
        }
        return (updated, requested - remaining)
    }

    static func age(completedLessonCount: Int) -> Int {
        min(100, 16 + max(0, completedLessonCount) / 10)
    }

    static func qualifiesForBadge(studied: Bool, dailyCare: Int) -> Bool {
        studied && dailyCare > badgeCareThreshold
    }
}
