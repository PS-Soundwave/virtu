import FirebaseAuth
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
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""

    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            Task {
                if let _ = try? await UserService.shared.getCurrentUser() {
                    await MainActor.run {
                        self.hasUsername = true
                        self.isAuthenticated = true
                    }
                }
                else {
                    await MainActor.run {
                        self.isAuthenticated = true
                    }
                }
            }
        }
    }

    func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }

            self.isAuthenticated = true
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AuthView: View {
    @StateObject var viewModel: VirtuViewModel
    @State private var isSignUp = false
    @State private var isLoading = false

    var body: some View {
            VStack(spacing: 20) {
                Text(isSignUp ? "Create Account" : "Sign In")
                    .font(.title)
                    .bold()

                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disabled(isLoading)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    isLoading = true
                    if isSignUp {
                        viewModel.signUp()
                    } else {
                        viewModel.signIn()
                    }
                }) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isLoading)

                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(
                        isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up"
                    )
                    .foregroundColor(.blue)
                }
                .disabled(isLoading)
            }
            .padding()
            .overlay {
                if isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onChange(of: viewModel.isAuthenticated) { _, newValue in
                isLoading = false
            }
    }
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
                        UsernameView(hasUsername: $viewModel.hasUsername)
                    }
                } else {
                    AuthView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.red)
        }
    }
}
