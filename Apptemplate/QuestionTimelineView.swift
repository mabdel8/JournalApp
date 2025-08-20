//
//  QuestionTimelineView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/20/25.
//

import SwiftUI
import SwiftData

struct QuestionTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeManager: StoreManager
    @StateObject private var questionManager = QuestionManager()
    @State private var selectedQuestion: Question?
    @State private var showingAnswerTimeline = false
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question Timeline")
                            .font(.custom("Noteworthy-Bold", size: 24))
                            .foregroundColor(inkColor)
                        
                        Text("See all your answers to each reflection question across different cycles and dates.")
                            .font(.custom("Noteworthy-Light", size: 16))
                            .foregroundColor(inkColor.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal)
                    
                    // Questions list
                    questionsList
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                questionManager.modelContext = modelContext
                questionManager.loadQuestions()
            }
            .sheet(item: $selectedQuestion) { question in
                AnswerTimelineView(question: question)
                    .environmentObject(storeManager)
            }
        }
    }
    
    private var questionsList: some View {
        List {
            ForEach(Array(questionManager.orderedQuestions.enumerated()), id: \.element.id) { index, question in
                QuestionTimelineRow(
                    question: question,
                    position: index + 1,
                    answerCount: getAnswerCount(for: question.id),
                    onTap: {
                        selectedQuestion = question
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private func getAnswerCount(for questionId: Int) -> Int {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.questionId == questionId
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            return entries.count
        } catch {
            return 0
        }
    }
}

struct QuestionTimelineRow: View {
    let question: Question
    let position: Int
    let answerCount: Int
    let onTap: () -> Void
    
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        Button(action: onTap) {
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
                    
                    HStack {
                        Text(question.category.capitalized)
                            .font(.custom("Noteworthy-Light", size: 12))
                            .foregroundColor(accentColor.opacity(0.7))
                        
                        Spacer()
                        
                        // Answer count badge
                        if answerCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 10))
                                Text("\(answerCount)")
                                    .font(.custom("Noteworthy-Bold", size: 12))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.8))
                            .cornerRadius(8)
                        } else {
                            Text("No answers yet")
                                .font(.custom("Noteworthy-Light", size: 10))
                                .foregroundColor(inkColor.opacity(0.5))
                                .italic()
                        }
                    }
                }
                
                Spacer()
                
                // Timeline indicator
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(accentColor)
                    .font(.system(size: 16))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(answerCount == 0)
        .opacity(answerCount == 0 ? 0.5 : 1.0)
    }
}