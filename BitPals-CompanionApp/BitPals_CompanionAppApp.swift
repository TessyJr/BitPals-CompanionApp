import SwiftUI
import HealthKit

@main
struct BitPals_CompanionAppApp: App {
  private let healthStore: HKHealthStore = HKHealthStore()

  init() {
    // Check for HealthKit availability before proceeding
    guard HKHealthStore.isHealthDataAvailable() else {
      fatalError("This app requires a device that supports HealthKit")
    }

    // Request permissions for required health data types
    requestHealthkitPermissions()
  }

  private func requestHealthkitPermissions() {
    let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
    let standTimeType = HKObjectType.quantityType(forIdentifier: .appleStandTime)!

    let readTypes = Set([stepCountType, standTimeType])

    healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
      print("HealthKit Authorization: Success: \(success), Error: \(error?.localizedDescription ?? "nil")")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(healthStore)
    }
  }
}

extension HKHealthStore: ObservableObject {}
