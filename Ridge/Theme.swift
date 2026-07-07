import SwiftUI

/// Ridge's identity: a teal-slate/coral palette evoking a mountain-range
/// weight-trend chart on a vet clipboard. Distinct from every sibling
/// app's colors (no sage/rust/plum/navy reused).
enum RGTheme {
    static let backdrop = Color(red: 0.925, green: 0.945, blue: 0.945)   // pale teal-mist
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.878, green: 0.910, blue: 0.910)
    static let ink = Color(red: 0.129, green: 0.169, blue: 0.180)        // deep slate-ink
    static let inkFaded = Color(red: 0.129, green: 0.169, blue: 0.180).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let tealSlate = Color(red: 0.176, green: 0.404, blue: 0.408)  // teal-slate ridge line
    static let tealBright = Color(red: 0.235, green: 0.522, blue: 0.522)
    static let coral = Color(red: 0.918, green: 0.451, blue: 0.376)      // coral accent (alert/goal)
    static let danger = Color(red: 0.780, green: 0.302, blue: 0.263)
    static let success = Color(red: 0.176, green: 0.404, blue: 0.408)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
