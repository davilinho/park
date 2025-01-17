//
// Created by David Martin on 13/2/24.
//

import FirebaseCore
import SwiftUI
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct parkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @ObservedObject var locationManager = LocationManager()
    @State private var viewModel = ContentViewModel()

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
        @Bindable var viewModel = self.viewModel

        WindowGroup {
            ContentView()
                .onAppear {
                    self.locationManager.requestLocation()
                }
                .environmentObject(self.locationManager)
        }
        .modelContainer(self.container)
        .environment(self.viewModel)
    }
    
    init() {
        self.locationManager.requestLocation()
    }
}
