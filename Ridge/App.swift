import SwiftUI

@main
struct RidgeApp: App {
    @StateObject private var store = RidgeStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}
