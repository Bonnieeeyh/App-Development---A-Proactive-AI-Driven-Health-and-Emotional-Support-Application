import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Top Image
            Image("preview")
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .padding(.top, 40)

            // Text
            VStack(spacing: 10) {
                Text("Welcome to MindPulse!")
                    .font(.custom("ComicRelief", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.teal)
                    .multilineTextAlignment(.center)

                Text("Your best companion and listener \n Always here when you need it most ")
                    .font(.custom("ComicRelief", size: 18))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("MindPulse goes beyond just tracking your health data - it recognizes when your're feeling down or stressed")
                    .font(.custom("ComicRelief", size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)

                Text("In those moments, our AI will reach out proactively to offer comfort, guidance, and meaningful conversations.")
                    .font(.custom("ComicRelief", size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                ZStack {
                    HStack {
                        
                        Image("YHB")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        
                        Text("@ Developed by Bonnie")
                            .font(.custom("ComicRelief", size: 12))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, -10)

                    }
                    .padding(.top, 80)
                }

                
                    
            }

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            ContentView() // Transition to main page
        }
    }
}

struct SplashScreenView_Priviews:PreviewProvider {
    static var previews:some View {
        SplashScreenView()
    }
}
