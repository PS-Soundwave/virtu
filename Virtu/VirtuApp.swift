import FirebaseCore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

class VirtuViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasUsername = false
}

@main
struct VirtuApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var viewModel = VirtuViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if viewModel.isAuthenticated {
                    if viewModel.hasUsername {
                        ContentView()
                    } else {
                        UsernameView(viewModel: viewModel)
                    }
                } else {
                    AuthView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.red)
        }
    }
}
