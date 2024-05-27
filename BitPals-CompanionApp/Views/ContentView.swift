import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var isSignedIn = false
    
    var body: some View {
        if isSignedIn {
            MainView(isSignedIn: $isSignedIn)
                .environmentObject(MainViewModel(healthStore: HKHealthStore()))
            
        } else {
            SignInView(isSignedIn: $isSignedIn)
        }
    }
}
