import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: RidgeStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: RidgeSheet?
    @State private var selectedPetID: UUID?

    private var selectedPet: RidgePet? {
        store.pets.first { $0.id == selectedPetID } ?? store.pets.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RGTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Ridge")
                                .font(RGTheme.titleFont)
                                .foregroundStyle(RGTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddPet(isPro: purchases.isPro) {
                                    activeSheet = .addPet
                                } else {
                                    activeSheet = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(RGTheme.tealSlate)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addPetButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        if store.pets.count > 1 {
                            petPicker
                        }

                        if let pet = selectedPet {
                            let trend = store.trend(for: pet)
                            ridgeCard(pet: pet, trend: trend)
                            statsRow(trend: trend)
                            historyList(pet: pet, trend: trend)
                        } else {
                            emptyState
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addPet:
                    RidgePetFormView(existing: nil)
                case .editPet(let pet):
                    RidgePetFormView(existing: pet)
                case .addWeight(let pet):
                    AddWeightView(pet: pet)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private var petPicker: some View {
        Picker("Pet", selection: Binding(
            get: { selectedPetID ?? store.pets.first?.id },
            set: { selectedPetID = $0 }
        )) {
            ForEach(store.pets) { pet in
                Text(pet.name).tag(Optional(pet.id))
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 18)
    }

    /// Quirky signature feature: a literal mountain-ridge silhouette drawn
    /// from the pet's weight history — climbing peaks for weight gain,
    /// descending valleys for weight loss, with an optional dashed
    /// "target elevation" goal line.
    private func ridgeCard(pet: RidgePet, trend: WeightTrend) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(pet.name.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.75))
                    .tracking(1.0)
                Spacer()
                Button {
                    activeSheet = .editPet(pet)
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("editPetButton")
            }

            RidgeChartView(entries: trend.entries, targetWeight: pet.targetWeight)
                .frame(height: 140)
                .accessibilityIdentifier("ridgeChart_\(pet.name)")
                .accessibilityValue(trend.latest.map { "\(Int($0.weight)) pounds" } ?? "no data")

            if let latest = trend.latest {
                Text("\(String(format: "%.1f", latest.weight)) lb as of \(latest.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Button {
                activeSheet = .addWeight(pet)
            } label: {
                Text("Log Weight")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RGTheme.coral)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("logWeightButton")
        }
        .padding(16)
        .background(RGTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 18)
    }

    private func statsRow(trend: WeightTrend) -> some View {
        HStack(spacing: 24) {
            statTile(label: "Change", value: trend.changeSincePrevious.map { String(format: "%+.1f lb", $0) } ?? "--", color: colorFor(trend.direction))
            statTile(label: "Since Start", value: trend.percentChangeFromFirst.map { String(format: "%+.0f%%", $0) } ?? "--", color: RGTheme.tealSlate)
        }
        .padding(.horizontal, 18)
    }

    private func colorFor(_ direction: TrendDirection) -> Color {
        switch direction {
        case .up: return RGTheme.coral
        case .down: return RGTheme.tealSlate
        case .flat: return RGTheme.inkFaded
        }
    }

    private func statTile(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RGTheme.inkFaded)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RGTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RGTheme.rule, lineWidth: 1))
    }

    private func historyList(pet: RidgePet, trend: WeightTrend) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(RGTheme.headlineFont)
                .foregroundStyle(RGTheme.ink)
                .padding(.horizontal, 18)

            ForEach(trend.entries.reversed()) { entry in
                HStack {
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(RGTheme.ink)
                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.caption)
                            .foregroundStyle(RGTheme.inkFaded)
                    }
                    Spacer()
                    Text("\(String(format: "%.1f", entry.weight)) lb")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RGTheme.tealSlate)
                }
                .padding(12)
                .background(RGTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RGTheme.rule, lineWidth: 1))
                .padding(.horizontal, 18)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(RGTheme.inkFaded)
            Text("No pets yet")
                .font(RGTheme.headlineFont)
                .foregroundStyle(RGTheme.ink)
            Text("Add a pet to start tracking their weight trend.")
                .font(.subheadline)
                .foregroundStyle(RGTheme.inkFaded)
        }
        .padding(.top, 24)
        .padding(.horizontal, 18)
    }
}

/// A literal mountain-ridge silhouette chart: weight history rendered as
/// a filled ridge shape (climbing = gaining weight, descending = losing),
/// with a dashed horizontal "target elevation" line when a goal is set.
struct RidgeChartView: View {
    let entries: [WeightEntry]
    let targetWeight: Double?

    var body: some View {
        GeometryReader { geo in
            let weights = entries.map(\.weight)
            let minW = (weights.min() ?? 0) - 1
            let maxW = (weights.max() ?? 1) + 1
            let range = max(maxW - minW, 0.1)

            ZStack {
                if entries.count >= 2 {
                    ridgePath(in: geo.size, minW: minW, range: range)
                        .fill(
                            LinearGradient(
                                colors: [RGTheme.tealBright.opacity(0.9), RGTheme.tealSlate.opacity(0.5)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    ridgeLinePath(in: geo.size, minW: minW, range: range)
                        .stroke(RGTheme.tealBright, lineWidth: 3)
                } else {
                    Text("Log at least 2 readings to see the ridge")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                if let target = targetWeight, range > 0 {
                    let y = geo.size.height * (1 - CGFloat((target - minW) / range))
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(RGTheme.coral, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            }
        }
    }

    private func points(in size: CGSize, minW: Double, range: Double) -> [CGPoint] {
        guard entries.count > 1 else { return [] }
        return entries.enumerated().map { index, entry in
            let x = size.width * CGFloat(index) / CGFloat(entries.count - 1)
            let y = size.height * (1 - CGFloat((entry.weight - minW) / range))
            return CGPoint(x: x, y: y)
        }
    }

    private func ridgeLinePath(in size: CGSize, minW: Double, range: Double) -> Path {
        var path = Path()
        let pts = points(in: size, minW: minW, range: range)
        guard let first = pts.first else { return path }
        path.move(to: first)
        for p in pts.dropFirst() { path.addLine(to: p) }
        return path
    }

    private func ridgePath(in size: CGSize, minW: Double, range: Double) -> Path {
        var path = Path()
        let pts = points(in: size, minW: minW, range: range)
        guard let first = pts.first else { return path }
        path.move(to: CGPoint(x: first.x, y: size.height))
        path.addLine(to: first)
        for p in pts.dropFirst() { path.addLine(to: p) }
        if let last = pts.last {
            path.addLine(to: CGPoint(x: last.x, y: size.height))
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    HomeView()
        .environmentObject(RidgeStore())
        .environmentObject(PurchaseManager())
}
