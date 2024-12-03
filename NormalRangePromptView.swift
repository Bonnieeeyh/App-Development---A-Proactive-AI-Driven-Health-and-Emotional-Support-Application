import SwiftUI

struct NormalRangePromptView: View {
    @Binding var generateMessage: Bool
    var onPreferenceSet: () -> Void

    var body: some View {
        VStack {
            Text("Set Receive Messages Preference")
                .font(.custom("ComicRelief", size: 20))
                .padding()
                .multilineTextAlignment(.center)

            Text("Would you like to receive messages when your health data is all within the normal range?")
                .font(.custom("ComicRelief", size: 14))
                .foregroundColor(.gray)
                .padding()
                .multilineTextAlignment(.center)

            Picker("Generate Messages?", selection: $generateMessage) {
                Text("Yes").tag(true)
                Text("No").tag(false)
            }
            .pickerStyle(WheelPickerStyle())
            .padding()

            Button("Confirm") {
                onPreferenceSet()
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

