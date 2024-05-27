import SwiftUI
import CloudKit
import HealthKit

class MainViewModel: ObservableObject {
    @Published var stepCount: Int = 0
    @Published var standTime: Double = 0.0
    
    @Published var isOnline: Bool = false
    @Published var isStarting: Bool = false
    @Published var isStopping: Bool = false
    
    @Published var logDate: String = Date().formatted(date: .numeric, time: .standard)
    @Published var logMessage: String = "App successfully launched."
    @Published var logColor: Color = Color.green
    
    private var timer: Timer? = nil
    
    private let healthStore: HKHealthStore
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    func start() {
        isStarting = true
        
        logMessage(message: "Clearing data...", color: Color.white)
        clearCloudKitData { success in
            if success {
                self.getNewestData {
                    self.isStarting = false
                    self.isOnline = true
                    
                    self.startTimer()
                }
            } else {
                self.logMessage(message: "Error clearing datas.", color: Color.red)
            }
        }
    }
    
    func stop() {
        isStopping = true
        
        timer?.invalidate()
        timer = nil
        
        logMessage(message: "Clearing data...", color: Color.white)
        clearCloudKitData { success in
            if success {
                self.isStopping = false
                self.isOnline = false
            } else {
                self.logMessage(message: "Error clearing datas.", color: Color.red)
            }
            
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { _ in
            self.timer?.invalidate()
            
            self.getNewestData {
                self.startTimer()
            }
        }
    }
    
    func getNewestData(completion: @escaping () -> Void) {
        logMessage(message: "Fetching datas...", color: Color.white)
        fetchDatasFromHealthKit {
            self.logMessage(message: "Saving datas...", color: Color.white)
            self.saveDatasToCloudKit {
                self.logMessage(message: "Step count: \(self.stepCount)\nStand time: \(self.standTime)\n\nDatas fetched and saved successfully.", color: Color.green)
                
                completion()
            }
        }
    }
    
    private func fetchDatasFromHealthKit(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        group.enter()
        guard let standTimeType = HKObjectType.quantityType(forIdentifier: .appleStandTime) else {
            logMessage(message: "Stand Time type is unavailable.", color: Color.red)
            group.leave()
            completion()
            return
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let standTimePredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let standTimeQuery = HKStatisticsQuery(quantityType: standTimeType, quantitySamplePredicate: standTimePredicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.logMessage(message: "Error fetching stand time: \(error.localizedDescription).", color: Color.red)
                } else if let result = result, let sum = result.sumQuantity() {
                    self.standTime = sum.doubleValue(for: HKUnit.minute())
                }
                group.leave()
            }
        }
        healthStore.execute(standTimeQuery)
        
        group.enter()
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            logMessage(message: "Step Count type is unavailable.", color: Color.red)
            group.leave()
            completion()
            return
        }
        let stepCountPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let stepCountQuery = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: stepCountPredicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.logMessage(message: "Error fetching step count: \(error.localizedDescription).", color: Color.red)
                } else if let result = result, let sum = result.sumQuantity() {
                    self.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                }
                group.leave()
            }
        }
        healthStore.execute(stepCountQuery)
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    private func saveDatasToCloudKit(completion: @escaping () -> Void) {
        let record = CKRecord(recordType: "HealthDatas")
        record["stepCount"] = self.stepCount
        record["standTime"] = self.standTime
        
        let privateDatabase = CKContainer.default().privateCloudDatabase
        privateDatabase.save(record) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.logMessage(message: "Error saving datas: \(error.localizedDescription).", color: Color.red)
                } else {
                    self.logMessage(message: "Datas saved successfully.", color: Color.green)
                }
                completion()
            }
        }
    }
    
    private func clearCloudKitData(completion: @escaping (Bool) -> Void) {
        let privateDatabase = CKContainer.default().privateCloudDatabase
        let query = CKQuery(recordType: "HealthDatas", predicate: NSPredicate(value: true))
        
        privateDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
            switch result {
            case .success(let fetchResult):
                let recordIDs = fetchResult.matchResults.map { $0.0 }
                
                if recordIDs.isEmpty {
                    completion(true)
                    return
                }
                
                let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
                
                deleteOperation.modifyRecordsResultBlock = { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self.logMessage(message: "Datas cleared successfully.", color: Color.green)
                            completion(true)
                        case .failure(let error):
                            self.logMessage(message: "Error deleting datas: \(error.localizedDescription).", color: Color.red)
                            completion(false)
                        }
                    }
                }
                
                privateDatabase.add(deleteOperation)
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.logMessage(message: "Error fetching datas: \(error.localizedDescription).", color: Color.red)
                    completion(false)
                }
            }
        }
    }
    
    private func logMessage(message: String, color: Color) {
        logDate = Date().formatted(date: .numeric, time: .standard)
        logMessage = message
        logColor = color
    }
}


