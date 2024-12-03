import HealthKit
import Foundation

class HealthKitManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    
    @Published var heartRate: Double?
    @Published var respiratoryRate: Double?
    
    private var apiKey: String {
        return Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String ?? ""
    }

    private var userAge: Int? {
        return UserDefaults.standard.integer(forKey: "userAge")
    }
    
    func updateAge(_ age: Int) {
        UserDefaults.standard.set(age, forKey: "userAge")
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data types not available"]))
            return
        }
        
        let readTypes: Set<HKObjectType> = [heartRateType, respiratoryRateType]
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            completion(success, error)
        }
    }
    
    func fetchAndAnalyzeData(completion: @escaping (String?) -> Void) {
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        fetchLatestHeartRate { [weak self] value, _ in
            DispatchQueue.main.async {
                self?.heartRate = value
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchLatestRespiratoryRate { [weak self] value, _ in
            DispatchQueue.main.async {
                self?.respiratoryRate = value
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            if let heartRate = self.heartRate, let respiratoryRate = self.respiratoryRate {
                self.analyzeAndRespond(messages: [], completion: completion)
            } else {
                completion("Error: Missing health data.")
            }
        }
    }

    
    func fetchLatestHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            print("Heart Rate type not available.")
            completion(nil, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Heart Rate type not available"]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Error fetching heart rate: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            if let sample = samples?.first as? HKQuantitySample {
                let heartRateUnit = HKUnit(from: "count/min")
                let heartRateValue = sample.quantity.doubleValue(for: heartRateUnit)
                DispatchQueue.main.async {
                    self.heartRate = heartRateValue
                }
                print("Fetched heart rate: \(heartRateValue)")
                completion(heartRateValue, nil)
            } else {
                print("No heart rate samples found.")
                completion(nil, nil)
            }
        }
        healthStore.execute(query)
    }

    func fetchLatestRespiratoryRate(completion: @escaping (Double?, Error?) -> Void) {
        guard let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            print("Respiratory Rate type not available.")
            completion(nil, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Respiratory Rate type not available"]))
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: respiratoryRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Error fetching respiratory rate: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            if let sample = samples?.first as? HKQuantitySample {
                let respiratoryRateUnit = HKUnit(from: "count/min")
                let respiratoryRateValue = sample.quantity.doubleValue(for: respiratoryRateUnit)
                DispatchQueue.main.async {
                    self.respiratoryRate = respiratoryRateValue
                }
                print("Fetched respiratory rate: \(respiratoryRateValue)")
                completion(respiratoryRateValue, nil)
            } else {
                print("No respiratory rate samples found.")
                completion(nil, nil)
            }
        }
        
        healthStore.execute(query)
    }

    func analyzeAndRespond(messages: [Message], completion: @escaping (String?) -> Void) {
        guard let heartRate = self.heartRate,
              let respiratoryRate = self.respiratoryRate,
              let userAge = self.userAge else {
                  completion("Error: Missing health data or age.")
                  return
              }

        var chatMessages: [[String: String]] = []
        let systemMessage = [
            "role": "system",
            "content": """
            You are a professional psychologist with expertise in analyzing heart rate and respiratory data to presume the user's psychological state and provide professional counseling. Respond to the user with empathy and a calm tone, induce the user to tell you what happened to them so you can have good references to help, do not rush to give advice, first give the user emotional comfort to calm them down with adequate empathy. Finally, give professional advice.
                    
            The data you should use are as follows:
                - Age: \(userAge) years
                - Heart Rate: \(heartRate) bpm
                - Respiratory Rate: \(respiratoryRate) breaths per minute

            Normal threshold that you need to compare for heart rate and respiratory rate are:
                - Normal range for heart rate: 
                    1 to 2 years old: 98 to 140 bmp. 
                    3 to 5 years old: 80 to 120 bmp. 
                    6 to 7 years old: 75 to 118 bmp. 
                    7 years and older: 60 to 100 bmp.
                - Normal range for respiratory rate: 
                    1 to 6 years old: 20 to 40 breaths per minute. 
                    6 to 12 years old: 14 to 30 breaths per minute. 
                    13 years and older: 12 to 20 breaths per minute.

            Your workflow should obey this following:

            First, you should tell the user their data follow "Your latest heart rate is \(heartRate) bpm, your latest rispiratory rate is \(respiratoryRate) breaths per minute", note that all data you tell should retain one decimal place

            Then, you have two circumstances

            Circumstance-1- If heart rate and respiratory rate are out of normal threshold:
                Ask the user proactively follow "I found your health data exceed normal threshold, it seems you are stressed or upset. Are you okay? Would you like to share with me what makes you feel not good?".
                Then wait user's respond to tell you what happened to them, then you should psychologize the user based on their answers, comfort them effectively and give some advice when appropriate. 
                Note that you should first induce the user to tell you what happened to them so you can have good references to help, do not rush to give advice, first give the user emotional comfort to calm them down with adequate empathy. Finally, you can give professional advice.
            Circumstance-2- If heart rate and respiratory rate within normal threshold:
                Tell the user follow "It's wonderful to see that your health indicators are in the normal threshold! However, I'm always here and willing to hear you if you have anything want to ask for help!"
                Then wait user's respond. 
                If the user tell you something made them feel bad, you should listen carefully and induce the user to tell you whole things so you can have good references to help, do not rush to give advice, first give the user emotional comfort to calm them down with adequate empathy. Finally, you can give professional advice.
                If the user said they're good, you should reply to express you're happy to hear that and give some simple advice for maintaing good health.
            """
        ]
        chatMessages.append(systemMessage)

        for message in messages {
            chatMessages.append([
                "role": message.sender == .user ? "user" : "assistant",
                "content": message.content
            ])
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let parameters: [String: Any] = [
            "model": "gpt-4o",
            "messages": chatMessages,
            "max_tokens": 2000
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)

        func sendRequest(retryCount: Int = 0) {
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard error == nil, let data = data else {
                    completion("Error: Could not connect to AI service.")
                    return
                }

                if let responseString = String(data: data, encoding: .utf8) {
                    print("Full API Response: \(responseString)")
                }

                if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = responseDict["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                } else if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let error = responseDict["error"] as? [String: Any],
                          let errorCode = error["code"] as? String, errorCode == "rate_limit_exceeded" {
                    
                    if retryCount < 2 {
                        let retryDelay = Double(120 + retryCount * 100) / 1000.0
                        DispatchQueue.global().asyncAfter(deadline: .now() + retryDelay) {
                            sendRequest(retryCount: retryCount + 1)
                        }
                    } else {
                        completion("Error: Rate limit exceeded. Please try again later.")
                    }
                } else {
                    completion("Error: Could not interpret AI response.")
                }
            }.resume()
        }
        
        sendRequest()
    }

}

