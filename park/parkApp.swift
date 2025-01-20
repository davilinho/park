//
// Created by David Martin on 13/2/24.
//

import GoogleMobileAds
import FirebaseCore
import SwiftUI
import SwiftData

class AppDelegate: UIResponder, UIApplicationDelegate {
    let interstitial = AdMobManager()

    var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = keyWindow.rootViewController else {
            return nil
        }
        return rootViewController
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
}

@main
struct parkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var viewModel = ParkViewModel()
    @State private var interstitial = AdMobManager()

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
                    viewModel.locationManager.requestLocation()
                }
        }
        .modelContainer(self.container)
        .environment(self.viewModel)
    }
    
    init() {
        self.viewModel.locationManager.requestLocation()
    }
}
