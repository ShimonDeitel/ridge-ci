import Foundation

/// A pet whose weight is tracked over time.
struct RidgePet: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var species: String
    /// Optional target weight (Pro feature: goal-line on the ridge chart).
    var targetWeight: Double?

    init(id: UUID = UUID(), name: String, species: String, targetWeight: Double? = nil) {
        self.id = id
        self.name = name
        self.species = species
        self.targetWeight = targetWeight
    }
}

/// A single weight reading for a pet.
struct WeightEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var petID: UUID
    var weight: Double   // pounds
    var date: Date
    var note: String

    init(id: UUID = UUID(), petID: UUID, weight: Double, date: Date = Date(), note: String = "") {
        self.id = id
        self.petID = petID
        self.weight = weight
        self.date = date
        self.note = note
    }
}

enum TrendDirection: String {
    case up, down, flat
}

/// Derived trend summary for a pet's recent weight history.
struct WeightTrend {
    let entries: [WeightEntry]   // sorted ascending by date
    let targetWeight: Double?

    var latest: WeightEntry? { entries.last }
    var previous: WeightEntry? { entries.count >= 2 ? entries[entries.count - 2] : nil }

    var changeSincePrevious: Double? {
        guard let latest, let previous else { return nil }
        return latest.weight - previous.weight
    }

    var direction: TrendDirection {
        guard let change = changeSincePrevious else { return .flat }
        if change > 0.05 { return .up }
        if change < -0.05 { return .down }
        return .flat
    }

    /// Percent change from the first recorded weight to the latest —
    /// the headline "ridge climb/descent" stat.
    var percentChangeFromFirst: Double? {
        guard let first = entries.first, let latest, first.weight > 0 else { return nil }
        return ((latest.weight - first.weight) / first.weight) * 100
    }
}
