import SwiftUI

class VirtuViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasUsername = false
}
