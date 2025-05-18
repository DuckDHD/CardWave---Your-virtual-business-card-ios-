import SwiftUI

@main
struct CardWaveApp: App {
    @StateObject private var contactViewModel = ContactViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(contactViewModel)
                .onAppear {
                    // Start background NFC detection when app launches
                    contactViewModel.startAutoDetection()
                }
        }
    }
}