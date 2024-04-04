//
// Created by David Martin on 13/2/24.
//

import SwiftUI
import SwiftData

@main
struct parkApp: App {
    @StateObject var locationManager = LocationManager()

    var container: ModelContainer = {
        let schema = Schema([
            ParkModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    self.locationManager.requestLocation()
                }
                .environmentObject(self.locationManager)
        }
        .modelContainer(self.container)
    }
}
