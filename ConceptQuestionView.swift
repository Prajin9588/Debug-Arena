import SwiftUI

struct ConceptQuestionView: View {
    let question: Question
    @Binding var isPresented: Bool
    let onCorrect: () -> Void
    
    @State private var selectedOption: Int? = nil
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dimmed background
            Theme.Colors.background.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal Content
            VStack(spacing: 25) {
                // Header
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Theme.Colors.gold)
                        .font(.title2)
                    Text("KNOWLEDGE CHECK")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .tracking(2)
                }
                .padding(.top)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Question
                Text(question.conceptQuestion)
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Options
                VStack(spacing: 12) {
                    ForEach(0..<question.conceptOptions.count, id: \.self) { index in
                        Button(action: {
                            handleSelection(index)
                        }) {
                            HStack {
                                Text(question.conceptOptions[index])
                                    .font(Theme.Typography.body)
                                    .foregroundColor(getOptionColor(index))
                                Spacer()
                                if selectedOption == index {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isCorrect ? Theme.Colors.success : Theme.Colors.error)
                                }
                            }
                            .padding()
                            .background(getOptionBackground(index))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(getOptionBorder(index), lineWidth: 1)
                            )
                        }
                        .disabled(showFeedback && isCorrect)
                    }
                }
                .padding(.horizontal)
                
                if showFeedback && !isCorrect {
                    Text("Incorrect. Try again!")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.error)
                        .padding(.top, 5)
                }
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("CANCEL")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.bottom)
                }
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isCorrect ? Theme.Colors.success : Theme.Colors.accent.opacity(0.3), lineWidth: 2)
            )
            .padding(.horizontal, 30)
            .offset(x: shakeOffset)
        }
    }
    
    func handleSelection(_ index: Int) {
        selectedOption = index
        showFeedback = true
        
        if index == question.conceptCorrectAnswer {
            isCorrect = true
            // Delay closing to show success state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onCorrect()
                isPresented = false
            }
        } else {
            isCorrect = false
            shake()
        }
    }
    
    func getOptionColor(_ index: Int) -> Color {
        if selectedOption == index {
            return isCorrect ? Theme.Colors.success : Theme.Colors.error
        }
        return Theme.Colors.textPrimary
    }
    
    func getOptionBackground(_ index: Int) -> Color {
        if selectedOption == index {
            return (isCorrect ? Theme.Colors.success : Theme.Colors.error).opacity(0.1)
        }
        return Theme.Colors.background
    }
    
    func getOptionBorder(_ index: Int) -> Color {
        if selectedOption == index {
            return isCorrect ? Theme.Colors.success : Theme.Colors.error
        }
        return Color.white.opacity(0.1)
    }
    
    func shake() {
        withAnimation(Animation.default.repeatCount(3, autoreverses: true).speed(2)) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                shakeOffset = 0
            }
        }
    }
}
