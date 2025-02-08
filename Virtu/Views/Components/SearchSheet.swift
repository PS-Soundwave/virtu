import SwiftUI

struct SearchSheet: View {
    let onUserSelected: (User) -> Void
    @State private var searchText = ""
    @State private var showingSuggestions = false
    @State private var userSuggestions = [User]()

    init(onUserSelected: @escaping (User) -> Void = { _ in }) {
        self.onUserSelected = onUserSelected
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search creator", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .onChange(of: searchText) { _, newValue in
                        Task {
                            if !newValue.isEmpty {
                                do {
                                    userSuggestions = try await UserService.shared.searchUsers(newValue)
                                    showingSuggestions = !userSuggestions.isEmpty
                                } catch {
                                    print("Error searching users: \(error)")
                                }
                            } else {
                                userSuggestions = []
                                showingSuggestions = false
                            }
                        }
                    }
            }

            Spacer()
            
            if showingSuggestions {
                List(userSuggestions) { suggestion in
                    Button(action: {
                        Task {
                            do {
                                let user = try await UserService.shared.getUserForUsername(suggestion.username)!
                                searchText = suggestion.username
                                onUserSelected(user)
                            } catch {
                                print("Error validating username: \(error)")
                            }
                        }
                    }) {
                        Text(suggestion.username)
                    }
                }
            }
        }.padding()
    }
}
