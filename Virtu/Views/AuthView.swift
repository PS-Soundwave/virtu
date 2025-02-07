import SwiftUI
import FirebaseAuth

// TODO: Review

struct AuthView: View {
    @ObservedObject var viewModel: VirtuViewModel
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isSignUp ? "Create Account" : "Sign In")
                .font(.title)
                .bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .disabled(isLoading)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .disabled(isLoading)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: {
                guard !isLoading else { return }
                
                isLoading = true
                errorMessage = ""
                
                Task {
                    defer { isLoading = false }

                    do {
                        if isSignUp {
                            try await Auth.auth().createUser(withEmail: email, password: password)

                            await MainActor.run {
                                viewModel.isAuthenticated = true
                            }
                        } else {
                            try await Auth.auth().signIn(withEmail: email, password: password)

                            if let _ = try? await UserService.shared.getCurrentUser() {
                                await MainActor.run {
                                    viewModel.hasUsername = true
                                    viewModel.isAuthenticated = true
                                }
                            }
                            else {
                                await MainActor.run {
                                    viewModel.isAuthenticated = true
                                }
                            }
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                    }
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
        .onChange(of: isLoading) { wasLoading, isLoading in
            // Only update app state when loading finishes and there's no error
            if wasLoading && !isLoading && errorMessage.isEmpty {
                viewModel.isAuthenticated = true
            }
        }
    }
}