import SwiftUI

struct SearchSheet: View {
    let onUserSelected: (String) -> Void
    @State private var searchText = ""
    @State private var showingSuggestions = false
    @State private var userSuggestions: [String] = []

    init(onUserSelected: @escaping (String) -> Void = { _ in }) {
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
                                    userSuggestions = try await UserSearchService.shared.searchUsers(query: newValue)
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
                List(userSuggestions, id: \.self) { suggestion in
                    Button(action: {
                        Task {
                            do {
                                if try await UserSearchService.shared.validateUsername(suggestion) {
                                    searchText = suggestion
                                    onUserSelected(suggestion)
                                }
                            } catch {
                                print("Error validating username: \(error)")
                            }
                        }
                    }) {
                        Text(suggestion)
                    }
                }
            }
        }.padding()
    }
}
