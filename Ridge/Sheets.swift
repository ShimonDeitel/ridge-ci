import SwiftUI

enum RidgeSheet: Identifiable {
    case addPet
    case editPet(RidgePet)
    case addWeight(RidgePet)
    case paywall

    var id: String {
        switch self {
        case .addPet: return "addPet"
        case .editPet(let p): return "edit-\(p.id)"
        case .addWeight(let p): return "weight-\(p.id)"
        case .paywall: return "paywall"
        }
    }
}

struct RidgePetFormView: View {
    @EnvironmentObject private var store: RidgeStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: RidgePet?

    @State private var name: String
    @State private var species: String
    @State private var targetWeightText: String

    init(existing: RidgePet?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _species = State(initialValue: existing?.species ?? "Cat")
        _targetWeightText = State(initialValue: existing?.targetWeight.map { String($0) } ?? "")
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name (e.g. Biscuit)", text: $name)
                        .accessibilityIdentifier("petNameField")
                    TextField("Species (e.g. Cat, Dog)", text: $species)
                        .accessibilityIdentifier("petSpeciesField")
                }
                Section("Target Weight (optional)") {
                    TextField("Target weight (lb)", text: $targetWeightText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("targetWeightField")
                }

                if isEditing {
                    Section {
                        Button("Delete Pet", role: .destructive) {
                            if let existing {
                                store.deletePet(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deletePetButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Pet" : "New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        let target = Double(targetWeightText)
                        if isEditing, let existing {
                            store.updatePet(existing.id, name: name, species: species, targetWeight: target)
                        } else {
                            store.addPet(name: name, species: species, targetWeight: target, isPro: purchases.isPro)
                        }
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("savePetButton")
                }
            }
        }
    }
}

struct AddWeightView: View {
    @EnvironmentObject private var store: RidgeStore
    @Environment(\.dismiss) private var dismiss

    let pet: RidgePet

    @State private var weightText: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Weight for \(pet.name)") {
                    TextField("Weight (lb)", text: $weightText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("weightValueField")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("weightDatePicker")
                }
                Section("Note (optional)") {
                    TextField("e.g. vet visit", text: $note)
                        .accessibilityIdentifier("weightNoteField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let weight = Double(weightText) {
                            store.addWeightEntry(petID: pet.id, weight: weight, date: date, note: note)
                        }
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(Double(weightText) == nil)
                    .accessibilityIdentifier("saveWeightButton")
                }
            }
        }
    }
}
