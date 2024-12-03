import SwiftUI

struct BirthdayPromptView: View {
    @Binding var birthday: Date
    var onBirthdayEntered: () -> Void

    var body: some View {
        VStack {
            Text("Please enter your birthday")
                .font(.custom("ComicRelief", size: 20))
                .padding()
                .multilineTextAlignment(.center)
            
            Text("- We collect your birthday data solely to calculate your age, which helps us provide more accurate health data evaluations. \n - Your data is securely stored and will never be shared or leaked to third parties. Protecting your privacy is our top priority.")
                .font(.custom("ComicRelief", size: 14))
                .foregroundColor(.gray)
                .padding()
                .multilineTextAlignment(.center)
                
            DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()
            

            Button("Confirm") {
                onBirthdayEntered()
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
