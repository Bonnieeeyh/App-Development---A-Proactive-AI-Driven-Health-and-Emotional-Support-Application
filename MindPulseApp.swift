import BackgroundTasks
import SwiftUI

@main
struct MindPulseApp: App {
    @State private var generateNormalRangeMessage: Bool = true 

    init() {
        loadGenerateNormalRangeMessagePreference() 
        registerBackgroundTasks()
        scheduleAppRefresh()
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.bonnie.Mind-Pulse.fetch", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() 

        let healthKitManager = HealthKitManager()

        task.expirationHandler = {
            print("Background task expired.")
            task.setTaskCompleted(success: false) 
        }

        healthKitManager.fetchAndAnalyzeData { response in
            if let heartRate = healthKitManager.heartRate,
               let respiratoryRate = healthKitManager.respiratoryRate,
               let userAge = UserDefaults.standard.integer(forKey: "userAge") as Int? {
                let shouldNotify = !self.isHealthDataInNormalRange(age: userAge, heartRate: heartRate, respiratoryRate: respiratoryRate) || self.generateNormalRangeMessage

                if shouldNotify, let responseText = response {
                    // Send notification
                    let content = UNMutableNotificationContent()
                    content.title = "Health Update from AI"
                    content.body = responseText
                    content.sound = .default

                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error adding notification: \(error.localizedDescription)")
                        }
                    }
                    task.setTaskCompleted(success: true)
                } else {
                    print("No notification required. Data in normal range or no response.")
                    task.setTaskCompleted(success: true)
                }
            } else {
                print("Error fetching health data or missing user age.")
                task.setTaskCompleted(success: false)
            }
        }
    }

    func scheduleAppRefresh() {
        let frequencyInSeconds = max(60, UserDefaults.standard.integer(forKey: "frequency") * 60)
        let request = BGAppRefreshTaskRequest(identifier: "com.bonnie.Mind-Pulse.fetch")
        request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(frequencyInSeconds))

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled for \(frequencyInSeconds) seconds.")
        } catch {
            print("Error scheduling background refresh: \(error.localizedDescription)")
        }
    }

    private func isHealthDataInNormalRange(age: Int, heartRate: Double, respiratoryRate: Double) -> Bool {
        // Heart rate normal ranges
        let heartRateNormal: Bool
        switch age {
        case 1...2: heartRateNormal = (98...140).contains(heartRate)
        case 3...5: heartRateNormal = (80...120).contains(heartRate)
        case 6...7: heartRateNormal = (75...118).contains(heartRate)
        default: heartRateNormal = (60...100).contains(heartRate)
        }

        // Respiratory rate normal ranges
        let respiratoryRateNormal: Bool
        switch age {
        case 1...6: respiratoryRateNormal = (20...40).contains(respiratoryRate)
        case 7...12: respiratoryRateNormal = (14...30).contains(respiratoryRate)
        default: respiratoryRateNormal = (12...20).contains(respiratoryRate)
        }

        return heartRateNormal && respiratoryRateNormal
    }

    private func loadGenerateNormalRangeMessagePreference() {
        generateNormalRangeMessage = UserDefaults.standard.bool(forKey: "generateNormalRangeMessage")
    }
}
