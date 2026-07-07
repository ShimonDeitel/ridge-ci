import Foundation
import Combine

@MainActor
final class RidgeStore: ObservableObject {
    @Published private(set) var pets: [RidgePet] = []
    @Published private(set) var entries: [WeightEntry] = []

    static let freePetLimit = 1

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("ridge_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if pets.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        let pet = RidgePet(name: "Biscuit", species: "Cat", targetWeight: 10.0)
        pets = [pet]
        let cal = Calendar.current
        entries = [
            WeightEntry(petID: pet.id, weight: 11.2, date: cal.date(byAdding: .day, value: -60, to: Date())!),
            WeightEntry(petID: pet.id, weight: 10.8, date: cal.date(byAdding: .day, value: -30, to: Date())!),
            WeightEntry(petID: pet.id, weight: 10.4, date: Date())
        ]
        save()
    }

    func canAddPet(isPro: Bool) -> Bool {
        isPro || pets.count < Self.freePetLimit
    }

    @discardableResult
    func addPet(name: String, species: String, targetWeight: Double?, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddPet(isPro: isPro) else { return false }
        pets.append(RidgePet(name: trimmed, species: species, targetWeight: targetWeight))
        save()
        return true
    }

    func updatePet(_ id: UUID, name: String, species: String, targetWeight: Double?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = pets.firstIndex(where: { $0.id == id }) else { return }
        pets[idx].name = trimmed
        pets[idx].species = species
        pets[idx].targetWeight = targetWeight
        save()
    }

    func deletePet(_ id: UUID) {
        pets.removeAll { $0.id == id }
        entries.removeAll { $0.petID == id }
        save()
    }

    @discardableResult
    func addWeightEntry(petID: UUID, weight: Double, date: Date = Date(), note: String = "") -> Bool {
        guard weight > 0, pets.contains(where: { $0.id == petID }) else { return false }
        entries.append(WeightEntry(petID: petID, weight: weight, date: date, note: note))
        save()
        return true
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func deleteAllData() {
        pets = []
        entries = []
        seedDefaults()
    }

    // MARK: - Derived

    func entries(for petID: UUID) -> [WeightEntry] {
        entries.filter { $0.petID == petID }.sorted { $0.date < $1.date }
    }

    func trend(for pet: RidgePet) -> WeightTrend {
        WeightTrend(entries: entries(for: pet.id), targetWeight: pet.targetWeight)
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var pets: [RidgePet]
        var entries: [WeightEntry]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            pets = decoded.pets
            entries = decoded.entries
        }
    }

    func save() {
        let snapshot = Snapshot(pets: pets, entries: entries)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
