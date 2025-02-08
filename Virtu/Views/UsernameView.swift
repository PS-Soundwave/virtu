import SwiftUI

struct UsernameView: View {
    @ObservedObject var viewModel: VirtuViewModel
    @State private var username = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose a Username")
                .font(.title)
                .bold()
            
            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                errorMessage = ""

                Task {
                    do {
                        try await UserService.shared.patchUsername(username)
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                        }
                    }
                    
                    if errorMessage.isEmpty {
                        await MainActor.run {
                            viewModel.hasUsername = true
                        }
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
            .disabled(username.isEmpty)
        }
        .padding()
    }
}
