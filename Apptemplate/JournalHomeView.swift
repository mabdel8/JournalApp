//
//  JournalHomeView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI
import SwiftData

struct JournalHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeManager: StoreManager
    @StateObject private var questionManager = QuestionManager()
    @State private var answer = ""
    @State private var showingSaved = false
    @State private var navigateToCalendar = false
    @State private var navigateToSettings = false
    
    // Journal colors for handwritten feel
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Paper texture background
                paperColor
                    .ignoresSafeArea()
                
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Notebook lines that scroll with content
                        notebookLinesView
                        
                        // Content positioned mathematically above the lines
                        VStack(spacing: 0) {
                            // Header with date and day counter
                            headerView
                                .padding(.top, 20) // Reduced to help align first text with first line
                                .padding(.bottom, 10)
                            
                            // Question text positioned on lines
                            if let question = questionManager.todaysQuestion {
                                questionOnLines(question: question)
                            }
                            
                            // Previous answer (if in cycle 2+)
                            if let previousEntry = questionManager.previousAnswer {
                                previousAnswerOnLines(entry: previousEntry)
                            }
                            
                            // Answer input area on lines
                            answerOnLines
                            
                            // Save button
                            if !questionManager.hasJournaledToday() {
                                saveButton
                                    .padding(.top, 30)
                            } else {
                                completedTodayView
                                    .padding(.top, 30)
                            }
                            
                            Spacer(minLength: 200) // Extra space for writing
                        }
                        .padding(.horizontal, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Journal")
                        .font(.custom("Noteworthy-Bold", size: 24))
                        .foregroundColor(inkColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        Button(action: { navigateToCalendar = true }) {
                            Image(systemName: "calendar")
                                .foregroundColor(accentColor)
                        }
                        
                        Button(action: { navigateToSettings = true }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToCalendar) {
                CalendarView()
                    .environmentObject(storeManager)
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
                    .environmentObject(storeManager)
            }
        }
        .onAppear {
            questionManager.modelContext = modelContext
            questionManager.calculateCurrentDay()
            loadTodaysEntry()
        }
    }
    
    private var notebookLinesView: some View {
        GeometryReader { geometry in
            Path { path in
                let lineSpacing: CGFloat = 41
                let totalHeight: CGFloat = max(geometry.size.height, 1200) // Ensure enough lines
                var currentY: CGFloat = 120 // Start after header space
                
                while currentY < totalHeight {
                    path.move(to: CGPoint(x: 30, y: currentY))
                    path.addLine(to: CGPoint(x: geometry.size.width - 30, y: currentY))
                    currentY += lineSpacing
                }
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        }
        .frame(minHeight: 1200) // Ensure scrollable content
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.custom("Noteworthy-Light", size: 18))
                .foregroundColor(inkColor.opacity(0.8))
            
            HStack(spacing: 5) {
                Text("Day")
                    .font(.custom("Noteworthy-Light", size: 16))
                Text("\(questionManager.currentDayNumber)")
                    .font(.custom("Noteworthy-Bold", size: 20))
                Text("of 30")
                    .font(.custom("Noteworthy-Light", size: 16))
                
                if questionManager.currentCycleNumber > 1 {
                    Text("• Cycle \(questionManager.currentCycleNumber)")
                        .font(.custom("Noteworthy-Light", size: 14))
                        .foregroundColor(accentColor)
                }
            }
            .foregroundColor(inkColor)
        }
        .padding(.top, 20)
    }
    
    private func questionOnLines(question: Question) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // "Today's Reflection" label - 8pt above first line position
            Text("Today's Reflection")
                .font(.custom("Noteworthy-Light", size: 22))
                .foregroundColor(accentColor)
                .padding(.leading, 10)
                .padding(.top, 14) // Mathematical positioning: gets us to Y≈98
                .padding(.bottom, 8)
            
            // Question text - positioned to sit above lines mathematically
            Text(question.text)
                .font(.custom("Noteworthy-Bold", size: 18))
                .foregroundColor(inkColor)
                .lineSpacing(12) // 30pt line spacing - 18pt font = 12pt line spacing
                .multilineTextAlignment(.leading)
                .padding(.leading, 10)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 30) // Consistent spacing to next section
    }
    
    private func previousAnswerOnLines(entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(accentColor)
                    .font(.system(size: 14))
                
                Text("Your answer from last cycle")
                    .font(.custom("Noteworthy-Light", size: 14))
                    .foregroundColor(accentColor)
                
                Spacer()
                
                Text(entry.date, format: .dateTime.month(.abbreviated).day())
                    .font(.custom("Noteworthy-Light", size: 12))
                    .foregroundColor(inkColor.opacity(0.6))
            }
            .padding(.leading, 10)
            .padding(.bottom, 8)
            
            // Previous answer text aligned above lines
            Text(entry.answer)
                .font(.custom("Noteworthy-Light", size: 18))
                .foregroundColor(inkColor.opacity(0.6))
                .lineSpacing(12) // 30pt line spacing - 18pt font = 12pt line spacing
                .multilineTextAlignment(.leading)
                .padding(.leading, 10)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 30)
    }
    
    private var answerOnLines: some View {
        VStack(alignment: .leading, spacing: 0) {
            // TextEditor with proper mathematical positioning and fixed placeholder
            ZStack(alignment: .topLeading) {
                // Background placeholder that doesn't block touches
                if answer.isEmpty && !questionManager.hasJournaledToday() {
                    VStack {
                        HStack {
                            Text("Your thoughts today...")
                                .font(.custom("Noteworthy-Light", size: 18))
                                .foregroundColor(inkColor.opacity(0.3))
                                .padding(.leading, 15)
                                .padding(.top, 8)
                            Spacer()
                        }
                        Spacer()
                    }
                    .allowsHitTesting(false) // Allows clicks to pass through to TextEditor
                }
                
                // TextEditor positioned above lines mathematically
                TextEditor(text: $answer)
                    .font(.custom("Noteworthy-Light", size: 18))
                    .foregroundColor(inkColor)
                    .lineSpacing(12) // 30pt line spacing - 18pt font = 12pt line spacing
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 210) // 7 lines × 30pt = 210pt
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
                    .disabled(questionManager.hasJournaledToday())
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 30)
    }
    
    private var saveButton: some View {
        Button(action: saveEntry) {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("Save Entry")
                    .font(.custom("Noteworthy-Bold", size: 18))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    private var completedTodayView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("Today's entry saved!")
                .font(.custom("Noteworthy-Bold", size: 18))
                .foregroundColor(inkColor)
            
            Text("Come back tomorrow for your next reflection")
                .font(.custom("Noteworthy-Light", size: 14))
                .foregroundColor(inkColor.opacity(0.6))
        }
        .padding()
    }
    
    private func saveEntry() {
        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        questionManager.saveEntry(answer: answer)
        
        withAnimation {
            showingSaved = true
        }
        
        // Clear the answer field after saving
        answer = ""
    }
    
    private func loadTodaysEntry() {
        guard let questionId = questionManager.todaysQuestion?.id else { return }
        
        let context = modelContext
        
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.questionId == questionId &&
                entry.date >= startOfDay &&
                entry.date < endOfDay
            }
        )
        
        do {
            let entries = try context.fetch(descriptor)
            if let todaysEntry = entries.first {
                answer = todaysEntry.answer
            }
        } catch {
            print("Error loading today's entry: \(error)")
        }
    }
}
