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
                
                // Subtle lines like notebook paper
                GeometryReader { geometry in
                    Path { path in
                        let lineSpacing: CGFloat = 30
                        var currentY: CGFloat = 100
                        
                        while currentY < geometry.size.height {
                            path.move(to: CGPoint(x: 20, y: currentY))
                            path.addLine(to: CGPoint(x: geometry.size.width - 20, y: currentY))
                            currentY += lineSpacing
                        }
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header with date and day counter
                        headerView
                        
                        // Question card
                        if let question = questionManager.todaysQuestion {
                            questionCard(question: question)
                        }
                        
                        // Previous answer (if in cycle 2+)
                        if let previousEntry = questionManager.previousAnswer {
                            previousAnswerCard(entry: previousEntry)
                        }
                        
                        // Answer input area
                        answerInputArea
                        
                        // Save button
                        if !questionManager.hasJournaledToday() {
                            saveButton
                        } else {
                            completedTodayView
                        }
                    }
                    .padding()
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
    
    private func questionCard(question: Question) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Reflection")
                .font(.custom("Noteworthy-Light", size: 14))
                .foregroundColor(accentColor)
            
            Text(question.text)
                .font(.custom("Noteworthy-Bold", size: 22))
                .foregroundColor(inkColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(paperColor)
                .shadow(color: inkColor.opacity(0.1), radius: 5, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func previousAnswerCard(entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
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
            
            Text(entry.answer)
                .font(.custom("Noteworthy-Light", size: 16))
                .foregroundColor(inkColor.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.opacity(0.05))
        )
    }
    
    private var answerInputArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your thoughts today...")
                .font(.custom("Noteworthy-Light", size: 14))
                .foregroundColor(inkColor.opacity(0.6))
            
            TextEditor(text: $answer)
                .font(.custom("Noteworthy-Light", size: 18))
                .foregroundColor(inkColor)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: 150)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
                .disabled(questionManager.hasJournaledToday())
        }
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