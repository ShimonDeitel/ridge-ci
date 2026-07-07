import XCTest
@testable import Ridge

final class RidgeTests: XCTestCase {
    var store: RidgeStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = RidgeStore()
        store.deleteAllData()
        for p in store.pets { store.deletePet(p.id) }
    }

    @MainActor
    func testAddPet() {
        let added = store.addPet(name: "Milo", species: "Cat", targetWeight: nil, isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.pets.count, 1)
    }

    @MainActor
    func testAddPetRejectsEmptyName() {
        let added = store.addPet(name: "  ", species: "Cat", targetWeight: nil, isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksSecondPet() {
        _ = store.addPet(name: "A", species: "Cat", targetWeight: nil, isPro: false)
        XCTAssertFalse(store.canAddPet(isPro: false))
        let second = store.addPet(name: "B", species: "Dog", targetWeight: nil, isPro: false)
        XCTAssertFalse(second)
        XCTAssertEqual(store.pets.count, 1)
    }

    @MainActor
    func testProAllowsMultiplePets() {
        _ = store.addPet(name: "A", species: "Cat", targetWeight: nil, isPro: true)
        let second = store.addPet(name: "B", species: "Dog", targetWeight: nil, isPro: true)
        XCTAssertTrue(second)
        XCTAssertEqual(store.pets.count, 2)
    }

    @MainActor
    func testUpdatePet() {
        _ = store.addPet(name: "Milo", species: "Cat", targetWeight: nil, isPro: false)
        let id = store.pets[0].id
        store.updatePet(id, name: "Milo", species: "Cat", targetWeight: 12.0)
        XCTAssertEqual(store.pets[0].targetWeight, 12.0)
    }

    @MainActor
    func testDeletePetAlsoDeletesEntries() {
        _ = store.addPet(name: "Milo", species: "Cat", targetWeight: nil, isPro: false)
        let id = store.pets[0].id
        store.addWeightEntry(petID: id, weight: 10.0)
        XCTAssertEqual(store.entries.count, 1)
        store.deletePet(id)
        XCTAssertTrue(store.entries.isEmpty)
    }

    @MainActor
    func testAddWeightEntry() {
        _ = store.addPet(name: "Milo", species: "Cat", targetWeight: nil, isPro: false)
        let id = store.pets[0].id
        let added = store.addWeightEntry(petID: id, weight: 10.5)
        XCTAssertTrue(added)
        XCTAssertEqual(store.entries.count, 1)
    }

    @MainActor
    func testAddWeightEntryRejectsZeroOrNegative() {
        _ = store.addPet(name: "Milo", species: "Cat", targetWeight: nil, isPro: false)
        let id = store.pets[0].id
        XCTAssertFalse(store.addWeightEntry(petID: id, weight: 0))
        XCTAssertFalse(store.addWeightEntry(petID: id, weight: -5))
    }

    @MainActor
    func testAddWeightEntryRejectsUnknownPet() {
        let added = store.addWeightEntry(petID: UUID(), weight: 10)
        XCTAssertFalse(added)
    }

    @MainActor
    func testDeleteEntry() {
        _ = store.addPet(name: "Milo", species: "Cat", targetWeight: nil, isPro: false)
        let id = store.pets[0].id
        store.addWeightEntry(petID: id, weight: 10)
        let entryID = store.entries[0].id
        store.deleteEntry(entryID)
        XCTAssertTrue(store.entries.isEmpty)
    }

    func testTrendDirectionUp() {
        let e1 = WeightEntry(petID: UUID(), weight: 10, date: Date().addingTimeInterval(-100))
        let e2 = WeightEntry(petID: e1.petID, weight: 11, date: Date())
        let trend = WeightTrend(entries: [e1, e2], targetWeight: nil)
        XCTAssertEqual(trend.direction, .up)
        XCTAssertEqual(trend.changeSincePrevious ?? 0, 1.0, accuracy: 0.001)
    }

    func testTrendDirectionDown() {
        let e1 = WeightEntry(petID: UUID(), weight: 11, date: Date().addingTimeInterval(-100))
        let e2 = WeightEntry(petID: e1.petID, weight: 10, date: Date())
        let trend = WeightTrend(entries: [e1, e2], targetWeight: nil)
        XCTAssertEqual(trend.direction, .down)
    }

    func testTrendDirectionFlatWithinTolerance() {
        let e1 = WeightEntry(petID: UUID(), weight: 10.0, date: Date().addingTimeInterval(-100))
        let e2 = WeightEntry(petID: e1.petID, weight: 10.02, date: Date())
        let trend = WeightTrend(entries: [e1, e2], targetWeight: nil)
        XCTAssertEqual(trend.direction, .flat)
    }

    func testPercentChangeFromFirst() {
        let e1 = WeightEntry(petID: UUID(), weight: 10, date: Date().addingTimeInterval(-200))
        let e2 = WeightEntry(petID: e1.petID, weight: 11, date: Date())
        let trend = WeightTrend(entries: [e1, e2], targetWeight: nil)
        XCTAssertEqual(trend.percentChangeFromFirst ?? 0, 10.0, accuracy: 0.01)
    }

    func testTrendWithNoEntriesHasNilLatest() {
        let trend = WeightTrend(entries: [], targetWeight: nil)
        XCTAssertNil(trend.latest)
        XCTAssertNil(trend.changeSincePrevious)
        XCTAssertEqual(trend.direction, .flat)
    }

    @MainActor
    func testEntriesForPetSortedAscending() {
        _ = store.addPet(name: "Milo", species: "Cat", targetWeight: nil, isPro: false)
        let id = store.pets[0].id
        let now = Date()
        store.addWeightEntry(petID: id, weight: 11, date: now)
        store.addWeightEntry(petID: id, weight: 10, date: now.addingTimeInterval(-1000))
        let sorted = store.entries(for: id)
        XCTAssertEqual(sorted.first?.weight, 10)
        XCTAssertEqual(sorted.last?.weight, 11)
    }

    @MainActor
    func testDeleteAllDataReseeds() {
        _ = store.addPet(name: "Extra", species: "Bird", targetWeight: nil, isPro: true)
        store.deleteAllData()
        XCTAssertFalse(store.pets.isEmpty)
    }
}
