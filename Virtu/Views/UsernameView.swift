import SwiftUI

struct UsernameView: View {
    @StateObject private var viewModel = UsernameViewModel()
    @Binding var hasUsername: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose a Username")
                .font(.title)
                .bold()
            
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                Task {
                    await viewModel.setUsername()
                    if viewModel.errorMessage.isEmpty {
                        hasUsername = true
                    }
                }
            }) {
                Text("Continue")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .disabled(viewModel.username.isEmpty)
        }
        .padding()
    }
}

class UsernameViewModel: ObservableObject {
    @Published var username = ""
    @Published var errorMessage = ""
    
    func setUsername() async {
        do {
            try await UserService.shared.setUsername(username)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
