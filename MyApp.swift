import SwiftUI


// MARK: - App Entry Point

@main
struct ChemistryApp: App {
    @StateObject var library = MoleculeLibrary()
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(library)
                    .preferredColorScheme(.dark)
                if !hasSeenOnboarding {
                    OnboardingView(isPresented: Binding(get: { !hasSeenOnboarding },
                                                         set: { hasSeenOnboarding = !$0 }))
                }
            }
        }
    }
}
