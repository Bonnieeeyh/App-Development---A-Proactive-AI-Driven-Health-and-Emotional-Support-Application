import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isThinking = false
    @State private var birthday: Date = Date()
    @State private var age: Int? = nil
    @State private var frequency: (hours: Int, minutes: Int) = (0, 30)
    @State private var showBirthdayPrompt = false
    @State private var showFrequencyPrompt = false
    @State private var showSettingsMenu = false
    @State private var lastMessageID: UUID? = nil
    @State private var timer: Timer? = nil
    @State private var generateNormalRangeMessage = true
    @State private var showNormalRangePrompt = false
    @ObservedObject private var healthKitManager = HealthKitManager()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                // Top Logo and Settings Menu
                ZStack {
                    
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)

                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showSettingsMenu.toggle()
                            }
                        }) {
                            Image("setting")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding()
                        }
                    }
                }
                .padding(.top)
                Spacer()

                // Fetch Health Data Button
                Button(action: {
                    healthKitManager.requestAuthorization { success, error in
                        if success {
                            healthKitManager.fetchAndAnalyzeData { response in
                                if let responseText = response {
                                    let aiMessage = Message(content: responseText, sender: .ai, timestamp: Date())
                                    messages.append(aiMessage)
                                    lastMessageID = aiMessage.id
                                }
                            }
                        }
                    }
                }) {
                    Text("Fetch Your Health Data Manually")
                        .font(.custom("ComicRelief", size: 12))
                        .padding(10)
                        .background(Color.green.opacity(0.3))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
                .frame(height: 20)
                .padding()

                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        ForEach(messages) { message in
                            VStack(alignment: message.sender == .ai ? .leading : .trailing, spacing: 4) {
                                if message.sender == .ai {
                                    Text("\(message.timestamp, formatter: timeFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.leading, 10)
                                }
                                HStack {
                                    if message.sender == .user {
                                        Spacer()
                                        Text(message.content)
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            .frame(maxWidth: 250, alignment: .trailing)
                                            .font(.custom("ComicRelief", size: 16))
                                    } else {
                                        Text(message.content)
                                            .padding()
                                            .background(Color.gray.opacity(0.2))
                                            .foregroundColor(.black)
                                            .cornerRadius(8)
                                            .frame(maxWidth: 250, alignment: .leading)
                                            .font(.custom("ComicRelief", size: 16))
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .id(message.id)
                        }
                    }
                    .padding()
                    .onChange(of: lastMessageID) { id in
                        if let id = id {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Chat Input
                HStack(spacing:2) {
                    TextField("Type your message here...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.custom("ComicRelief", size: 14))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)

                    Button(action: sendMessage) {
                        Text("Send")
                            .font(.custom("ComicRelief", size: 16))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Color(UIColor(
                                    red: inputText.isEmpty ? 178/255 : 56/255,
                                    green: inputText.isEmpty ? 228/255 : 202/255,
                                    blue: inputText.isEmpty ? 203/255 : 169/255,
                                    alpha: 1.0
                                ))
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(inputText.isEmpty || isThinking)
                }
                .padding(.bottom)

            }

            // Settings Menu
            if showSettingsMenu {
                VStack {
                    Spacer()
                    VStack {
                        Button(action: {
                            showSettingsMenu = false
                            showBirthdayPrompt = true
                        }) {
                            Text("Edit Your Birthday")
                                .font(.custom("ComicRelief", size: 15))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor(red: 163/255, green: 240/255, blue: 200/255, alpha: 1.0)))
                                .foregroundColor(.black)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        Button(action: {
                            showSettingsMenu = false
                            showFrequencyPrompt = true
                        }) {
                            Text("Edit Fetching Frequency")
                                .font(.custom("ComicRelief", size: 15))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor(red: 145/255, green: 230/255, blue: 240/255, alpha: 1.0)))
                                .foregroundColor(.black)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        Button(action: {
                            showSettingsMenu = false
                            showNormalRangePrompt = true
                        }) {
                            Text("Set Receive Messages Preference")
                                .font(.custom("ComicRelief", size: 15))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor(red: 255/255, green: 204/255, blue: 153/255, alpha: 1.0)))
                                .foregroundColor(.black)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        Button(action: {
                            withAnimation {
                                showSettingsMenu.toggle()
                            }
                        }) {
                            Text("Close Menu")
                                .font(.custom("ComicRelief", size: 15))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor(red: 246/255, green: 242/255, blue: 230/255, alpha: 1.0)))
                                .foregroundColor(.black)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
                }
                .background(Color.black.opacity(0.3).edgesIgnoringSafeArea(.all))
            }
        }
        .onAppear {
            loadBirthday()
            loadFrequency()
            loadGenerateNormalRangeMessagePreference()
            startTimer()

            healthKitManager.requestAuthorization { success, error in
                if success {
                    print("HealthKit authorization successful.")
                }
            }

            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus != .authorized {
                    requestNotificationPermission()
                }
            }
        }
        .onDisappear {
            stopTimer()
            MindPulseApp().scheduleAppRefresh()
        }
        .sheet(isPresented: $showBirthdayPrompt, content: {
            BirthdayPromptView(birthday: $birthday, onBirthdayEntered: saveBirthdayAndCalculateAge)
        })
        .sheet(isPresented: $showFrequencyPrompt, content: {
            FrequencyPromptView(frequency: $frequency, onFrequencyEntered: storeFrequencyAndDismiss)
        })
        .sheet(isPresented: $showNormalRangePrompt, content: {
            NormalRangePromptView(generateMessage: $generateNormalRangeMessage, onPreferenceSet: saveNormalRangePreference)
        })
    }
    
    private func checkInitialSettings() {
        if UserDefaults.standard.object(forKey: "userBirthday") == nil {
            showBirthdayPrompt = true
        }
        if UserDefaults.standard.object(forKey: "frequency") == nil {
            showFrequencyPrompt = true
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        let frequencyInSeconds = (frequency.hours * 60 * 60) + (frequency.minutes * 60)
        print("Starting timer with frequency: \(frequencyInSeconds) seconds.")
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(frequencyInSeconds), repeats: true) { _ in
            fetchHealthData()
        }
    }

    func stopTimer() {
        print("Stopping timer.")
        timer?.invalidate()
        timer = nil
    }
    
    private func loadGenerateNormalRangeMessagePreference() {
        generateNormalRangeMessage = UserDefaults.standard.bool(forKey: "generateNormalRangeMessage")
    }

    private func saveNormalRangePreference() {
        UserDefaults.standard.set(generateNormalRangeMessage, forKey: "generateNormalRangeMessage")
        showNormalRangePrompt = false
    }
    
    func fetchHealthData() {
        healthKitManager.fetchAndAnalyzeData { response in
            if let heartRate = healthKitManager.heartRate,
               let respiratoryRate = healthKitManager.respiratoryRate,
               let age = age {
                print("Fetched health data: Heart Rate = \(heartRate), Respiratory Rate = \(respiratoryRate), Age = \(age)")
                
                if shouldNotifyForNormalRange(age: age, heartRate: heartRate, respiratoryRate: respiratoryRate) {
                    if let responseText = response {
                        DispatchQueue.main.async {
                            let aiMessage = Message(content: responseText, sender: .ai, timestamp: Date())
                            messages.append(aiMessage)
                            lastMessageID = aiMessage.id
                            sendNotification(with: responseText)
                        }
                    } else {
                        print("No response text from AI.")
                    }
                }
            }
        }
    }


    private func shouldNotifyForNormalRange(age: Int, heartRate: Double, respiratoryRate: Double) -> Bool {
        if generateNormalRangeMessage {
            return true
        }
        let heartRateNormal = isHeartRateInNormalRange(age: age, heartRate: heartRate)
        let respiratoryRateNormal = isRespiratoryRateInNormalRange(age: age, respiratoryRate: respiratoryRate)
        return !(heartRateNormal && respiratoryRateNormal)
    }

    private func isHeartRateInNormalRange(age: Int, heartRate: Double) -> Bool {
        switch age {
        case 1...2: return (98...140).contains(heartRate)
        case 3...5: return (80...120).contains(heartRate)
        case 6...7: return (75...118).contains(heartRate)
        default: return (60...100).contains(heartRate)
        }
    }

    private func isRespiratoryRateInNormalRange(age: Int, respiratoryRate: Double) -> Bool {
        switch age {
        case 1...6: return (20...40).contains(respiratoryRate)
        case 7...12: return (14...30).contains(respiratoryRate)
        default: return (12...20).contains(respiratoryRate)
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission denied.")
            }
        }
    }

    private func sendNotification(with message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Health Update from AI"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification Error: \(error.localizedDescription)")
            }
        }
    }

    private func storeFrequencyAndDismiss() {
        let frequencyInMinutes = frequency.hours * 60 + frequency.minutes
        UserDefaults.standard.set(frequencyInMinutes, forKey: "frequency")
        startTimer()
        showFrequencyPrompt = false
    }

    
    private func loadFrequency() {
        let storedFrequency = UserDefaults.standard.integer(forKey: "frequency")
        if storedFrequency > 0 {
            frequency = (hours: storedFrequency / 60, minutes: storedFrequency % 60)
        }
    }

    private func loadBirthday() {
        if let savedBirthday = UserDefaults.standard.object(forKey: "userBirthday") as? Date {
            birthday = savedBirthday
            calculateAge(from: savedBirthday)
        } else {
            showBirthdayPrompt = true
        }
    }
    private func saveBirthdayAndCalculateAge() {
        UserDefaults.standard.set(birthday, forKey: "userBirthday")
        calculateAge(from: birthday)
        showBirthdayPrompt = false
    }

    private func calculateAge(from birthday: Date) {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        age = ageComponents.year
        if let calculatedAge = age {
            UserDefaults.standard.set(calculatedAge, forKey: "userAge")
            print("User's age calculated and saved: \(calculatedAge)")
        }
    }
    
    private func sendMessage() {
        let userMessage = Message(content: inputText, sender: .user, timestamp: Date())
        messages.append(userMessage)
        lastMessageID = userMessage.id
        inputText = ""
        isThinking = true

        healthKitManager.analyzeAndRespond(messages: messages) { response in
            DispatchQueue.main.async {
                if let responseText = response {
                    let aiMessage = Message(content: responseText, sender: .ai, timestamp: Date())
                    messages.append(aiMessage)
                    lastMessageID = aiMessage.id
                }
                isThinking = false
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
}
