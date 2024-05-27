import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isSignedIn: Bool
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("BitPals")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("BitPals Companion App is designed to securely transmit your stand time and step count data from your Health app to the BitPals macOS application.")
                    .font(.subheadline)
                    .padding(.bottom, 32)
                
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(_):
                        isSignedIn = true
                    case .failure(let error):
                        print("Authorization failed: \(error.localizedDescription)")
                    }
                }
                .signInWithAppleButtonStyle(
                    colorScheme == .dark ? .white : .black
                )
                .frame(height: 48)
                .cornerRadius(8)
                
            }
            .padding()
        }
    }
}

#Preview {
    SignInView(isSignedIn: .constant(false))
}
