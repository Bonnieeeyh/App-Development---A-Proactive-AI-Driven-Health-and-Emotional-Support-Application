import SwiftUI

struct FrequencyPromptView: View {
    @Binding var frequency: (hours: Int, minutes: Int)
    var onFrequencyEntered: () -> Void

    var body: some View {
        VStack {
            Text("Set Fetching Frequency")
                .font(.custom("ComicRelief", size: 20))
                .padding()
                .multilineTextAlignment(.center)
            
            Text("- Please set how frequently you would like the app to fetch your health data and interact via our AI, ensuring a personalized and secure experience.")
                .font(.custom("ComicRelief", size: 14))
                .foregroundColor(.gray)
                .padding()
                .multilineTextAlignment(.center)

            // Hours and Minutes
            HStack(spacing: 20) {
                Picker("Hours", selection: $frequency.hours) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text("\(hour) hr").tag(hour)
                    }
                }
                .frame(maxWidth: 100)
                .clipped()
                .pickerStyle(WheelPickerStyle())
                
                Picker("Minutes", selection: $frequency.minutes) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .frame(maxWidth: 100)
                .clipped()
                .pickerStyle(WheelPickerStyle())
            }
            .padding()

            Button("Confirm") {
                onFrequencyEntered()
            }
            .padding()
            .font(.custom("ComicRelief", size: 16))
            .background(Color.teal)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

