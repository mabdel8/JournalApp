//
//  SimpleQuestionManagerView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI

struct SimpleQuestionManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreManager
    @StateObject private var questionManager = QuestionManager()
    @State private var questions: [Question] = []
    @State private var editingQuestion: Question?
    @State private var showingEditSheet = false
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question Management")
                            .font(.custom("Noteworthy-Bold", size: 24))
                            .foregroundColor(inkColor)
                        
                        Text("Edit and reorder your 30 reflection questions. Drag to reorder, tap to edit.")
                            .font(.custom("Noteworthy-Light", size: 16))
                            .foregroundColor(inkColor.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal)
                    
                    // Questions list
                    questionsList
                }
            }
            .navigationTitle("30 Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Reset to Default") {
                            resetToDefault()
                        }
                        .foregroundColor(.red)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadQuestions()
            }
            .sheet(item: $editingQuestion) { question in
                EditQuestionSheet(
                    question: question,
                    onSave: { updatedText in
                        updateQuestion(question.id, newText: updatedText)
                    }
                )
            }
        }
    }
    
    private var questionsList: some View {
        List {
            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                SimpleQuestionRow(
                    question: question,
                    position: index + 1,
                    onEdit: {
                        editingQuestion = question
                    }
                )
            }
            .onMove(perform: moveQuestions)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private func loadQuestions() {
        questionManager.loadQuestions()
        questions = questionManager.orderedQuestions
    }
    
    private func updateQuestion(_ questionId: Int, newText: String) {
        questionManager.updateQuestionText(questionId: questionId, newText: newText)
        loadQuestions()
    }
    
    private func moveQuestions(from source: IndexSet, to destination: Int) {
        // Perform the move on our local array
        questions.move(fromOffsets: source, toOffset: destination)
        
        // Update the question manager
        if let sourceIndex = source.first {
            questionManager.moveQuestion(from: sourceIndex, to: destination > sourceIndex ? destination - 1 : destination)
            loadQuestions()
        }
    }
    
    private func resetToDefault() {
        questionManager.resetToDefaultOrder()
        loadQuestions()
    }
}

struct SimpleQuestionRow: View {
    let question: Question
    let position: Int
    let onEdit: () -> Void
    
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        Button(action: onEdit) {
            HStack {
                // Position number
                Text("\(position)")
                    .font(.custom("Noteworthy-Bold", size: 16))
                    .foregroundColor(accentColor)
                    .frame(width: 30, alignment: .leading)
                
                // Question content
                VStack(alignment: .leading, spacing: 4) {
                    Text(question.text)
                        .font(.custom("Noteworthy-Light", size: 16))
                        .foregroundColor(inkColor)
                        .multilineTextAlignment(.leading)
                    
                    Text(question.category.capitalized)
                        .font(.custom("Noteworthy-Light", size: 12))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
                
                // Edit indicator
                Image(systemName: "pencil")
                    .foregroundColor(accentColor)
                    .font(.system(size: 14))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditQuestionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let question: Question
    let onSave: (String) -> Void
    @State private var editedText: String
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    init(question: Question, onSave: @escaping (String) -> Void) {
        self.question = question
        self.onSave = onSave
        self._editedText = State(initialValue: question.text)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Edit Question \(question.id)")
                            .font(.custom("Noteworthy-Bold", size: 24))
                            .foregroundColor(inkColor)
                        
                        Text("Modify this reflection question to better suit your journaling practice.")
                            .font(.custom("Noteworthy-Light", size: 16))
                            .foregroundColor(inkColor.opacity(0.8))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question Text")
                            .font(.custom("Noteworthy-Bold", size: 16))
                            .foregroundColor(inkColor)
                        
                        TextField("Enter question text...", text: $editedText, axis: .vertical)
                            .font(.custom("Noteworthy-Light", size: 16))
                            .foregroundColor(inkColor)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...5)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedText.isEmpty {
                            onSave(trimmedText)
                            dismiss()
                        }
                    }) {
                        Text("Save Changes")
                            .font(.custom("Noteworthy-Bold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentColor)
                            .cornerRadius(12)
                    }
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}