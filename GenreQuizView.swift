import SwiftUI

struct GenreQuizView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedGenre: Genre?
    @State private var currentQuestion: GenreQuestion?
    @State private var selectedOptionIndex: Int?
    @State private var isAnswered = false
    @State private var isCorrect = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let genre = selectedGenre {
                    if let question = currentQuestion {
                        quizContent(question: question)
                    } else {
                        ProgressView()
                            .onAppear { loadQuestion(for: genre) }
                    }
                } else {
                    genreSelectionContent
                }
            }
            .navigationTitle(selectedGenre == nil ? "Choose a Genre" : "Trivia Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedGenre != nil && !isAnswered {
                        Button("Back") {
                            selectedGenre = nil
                            currentQuestion = nil
                        }
                    } else if !isAnswered {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private var genreSelectionContent: some View {
        VStack(spacing: 30) {
            Text("Answer a quick question to unlock the solution!")
                .font(Theme.Typography.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            ForEach(Genre.allCases) { genre in
                Button(action: {
                    selectedGenre = genre
                }) {
                    HStack(spacing: 20) {
                        Image(systemName: genre.icon)
                            .font(Theme.Typography.title)
                        Text(genre.rawValue)
                            .font(Theme.Typography.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func quizContent(question: GenreQuestion) -> some View {
        VStack(spacing: 25) {
            Text(question.text)
                .font(Theme.Typography.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            VStack(spacing: 15) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    Button(action: {
                        if !isAnswered {
                            selectOption(index: index, question: question)
                        }
                    }) {
                        Text(question.options[index])
                            .font(Theme.Typography.body.weight(.semibold))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(optionBackground(for: index))
                            .foregroundColor(optionForegroundColor(for: index))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(optionBorderColor(for: index), lineWidth: 2)
                            )
                    }
                    .disabled(isAnswered)
                }
            }
            .padding(.horizontal)
            
            if isAnswered {
                VStack(spacing: 10) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60)) // Icon sizing is fine with system size
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    Text(isCorrect ? "Correct!" : "Incorrect")
                        .font(Theme.Typography.title2)
                        .bold()
                    
                    Text(isCorrect ? "Hint unlocked! Spend 2 coins to see the explanation." : "Try again or choose another genre.")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        if isCorrect {
                            gameManager.unlockHintWithGenreQuiz()
                            dismiss()
                        } else {
                            resetQuiz()
                        }
                    }) {
                        Text(isCorrect ? "Close" : "Try Again")
                            .font(Theme.Typography.body.weight(.bold))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isCorrect ? Color.green : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    private func loadQuestion(for genre: Genre) {
        let questions = gameManager.getGenreQuestions(for: genre)
        currentQuestion = questions.randomElement()
    }
    
    private func selectOption(index: Int, question: GenreQuestion) {
        selectedOptionIndex = index
        isAnswered = true
        isCorrect = (index == question.correctAnswerIndex)
    }
    
    private func resetQuiz() {
        isAnswered = false
        isCorrect = false
        selectedOptionIndex = nil
        currentQuestion = nil
        // stay in same genre or go back? user said "Retru" so stay in genre but new question
        loadQuestion(for: selectedGenre!)
    }
    
    // UI Helpers
    private func optionBackground(for index: Int) -> Color {
        guard let selected = selectedOptionIndex, let question = currentQuestion else {
            return Color.gray.opacity(0.1)
        }
        
        if index == question.correctAnswerIndex {
            return Color.green.opacity(0.2)
        }
        
        if index == selected && index != question.correctAnswerIndex {
            return Color.red.opacity(0.2)
        }
        
        return Color.gray.opacity(0.1)
    }
    
    private func optionForegroundColor(for index: Int) -> Color {
        guard let selected = selectedOptionIndex, let question = currentQuestion else {
            return .primary
        }
        
        if index == question.correctAnswerIndex {
            return .green
        }
        
        if index == selected && index != question.correctAnswerIndex {
            return .red
        }
        
        return .primary
    }
    
    private func optionBorderColor(for index: Int) -> Color {
        guard let selected = selectedOptionIndex, let question = currentQuestion else {
            return .clear
        }
        
        if index == question.correctAnswerIndex {
            return .green
        }
        
        if index == selected && index != question.correctAnswerIndex {
            return .red
        }
        
        return .clear
    }
}
