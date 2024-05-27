import SwiftUI
import HealthKit

struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Binding var isSignedIn: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            VStack(alignment: .leading) {
                Text("[\(viewModel.logDate)]")
                Text("\(viewModel.logMessage)")
                    .foregroundColor(viewModel.logColor)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black)
            .foregroundColor(Color.white)
            .border(Color.white, width: 1.0)
            
            Spacer()
            
            if !viewModel.isOnline && !viewModel.isStarting {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .onTapGesture {
                    viewModel.start()
                }
            } else if viewModel.isStarting {
                HStack {
                    Image(systemName: "play.fill")
                        .symbolEffect(.pulse)
                    Text("Starting...")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .opacity(0.5)
            } else if viewModel.isStopping {
                HStack {
                    Image(systemName: "stop.fill")
                        .symbolEffect(.pulse)
                    Text("Stopping...")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .opacity(0.5)
            } else if viewModel.isOnline {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .onTapGesture {
                    viewModel.stop()
                }
            }
            
            Text("*Starting this app will periodically transmit your stand time and step count data every 5 minutes.")
                .font(.caption)
        }
        .padding()
    }
}

#Preview {
    MainView(isSignedIn: .constant(true))
        .environmentObject(MainViewModel(healthStore: HKHealthStore()))
}
