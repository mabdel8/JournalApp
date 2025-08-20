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
    @State private var navigateToHistory = false
    @State private var navigateToTimeline = false
    @State private var autoSaveTimer: Timer?
    @State private var hasUnsavedChanges = false
    @State private var currentViewDate = Date() // Track which day we're viewing
    @State private var isViewingToday = true
    @State private var isPreviousAnswerExpanded = false // For expandable previous answers
    @FocusState private var isTextEditorFocused: Bool
    
    // Journal colors for handwritten feel
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    // Check if we're at the journal start date (can't go back further)
    private var isAtStartDate: Bool {
        guard let startDate = UserDefaults.standard.object(forKey: "journalStartDate") as? Date else {
            return false
        }
        return Calendar.current.isDate(currentViewDate, inSameDayAs: startDate)
    }
    
    // Check if there are previous journal entries
    private var hasPreviousJournalEntries: Bool {
        return questionManager.getPreviousJournaledDate(before: currentViewDate) != nil
    }
    
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
                            
                            // Auto-save indicator
                            if hasUnsavedChanges {
                                savingIndicator
                                    .padding(.top, 10)
                            } else if !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                savedIndicator
                                    .padding(.top, 10)
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
                        // Test button (remove in production)
                        Menu {
                            Button("Create Test Data") {
                                questionManager.createTestDataForPreviousAnswers()
                                // Force refresh to show the previous answer for current view date
                                questionManager.fetchPreviousAnswer(for: currentViewDate)
                            }
                            Button("Clear Test Data") {
                                questionManager.clearTestData()
                                questionManager.previousAnswer = nil
                            }
                        } label: {
                            Image(systemName: "flask")
                                .foregroundColor(accentColor.opacity(0.7))
                        }
                        
                        Button(action: { navigateToTimeline = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(accentColor)
                        }
                        
                        Button(action: { navigateToHistory = true }) {
                            Image(systemName: "book.pages")
                                .foregroundColor(accentColor)
                        }
                        
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
                
                // Done button for keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isTextEditorFocused = false
                    }
                    .font(.custom("Noteworthy-Bold", size: 16))
                    .foregroundColor(accentColor)
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
            .navigationDestination(isPresented: $navigateToHistory) {
                JournalHistoryView()
                    .environmentObject(storeManager)
            }
            .navigationDestination(isPresented: $navigateToTimeline) {
                QuestionTimelineView()
                    .environmentObject(storeManager)
            }
        }
        .onAppear {
            questionManager.modelContext = modelContext
            questionManager.calculateCurrentDay()
            updateViewForCurrentDate()
        }
        .onChange(of: currentViewDate) { _, _ in
            updateViewForCurrentDate()
        }
        .onDisappear {
            // Save any unsaved changes when leaving the view
            autoSaveTimer?.invalidate()
            if hasUnsavedChanges {
                autoSaveEntry()
            }
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
            // Date with navigation
            HStack {
                Button(action: previousDay) {
                    Image(systemName: hasPreviousJournalEntries ? "chevron.left.2" : "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor((isAtStartDate && !hasPreviousJournalEntries) ? inkColor.opacity(0.3) : accentColor)
                }
                .disabled(isAtStartDate && !hasPreviousJournalEntries)
                
                Spacer()
                
                Text(currentViewDate, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.custom("Noteworthy-Light", size: 18))
                    .foregroundColor(inkColor.opacity(0.8))
                
                Spacer()
                
                Button(action: nextDay) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isViewingToday ? inkColor.opacity(0.3) : accentColor)
                }
                .disabled(isViewingToday)
            }
            .padding(.horizontal)
            
            HStack(spacing: 5) {
                Text("Day")
                    .font(.custom("Noteworthy-Light", size: 16))
                Text("\(getDayNumber(for: currentViewDate))")
                    .font(.custom("Noteworthy-Bold", size: 20))
                Text("of 30")
                    .font(.custom("Noteworthy-Light", size: 16))
                
                let cycleNumber = getCycleNumber(for: currentViewDate)
                if cycleNumber > 1 {
                    Text("• Cycle \(cycleNumber)")
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
            // Dynamic reflection label based on current view date
            Text(isViewingToday ? "Today's Reflection" : "Reflection")
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
        VStack(alignment: .leading, spacing: 8) {
            // Header with better styling
            HStack {
                Image(systemName: "memories")
                    .foregroundColor(accentColor)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Previous Answer")
                        .font(.custom("Noteworthy-Bold", size: 16))
                        .foregroundColor(accentColor)
                    
                    Text(entry.date, format: .dateTime.month(.wide).day().year())
                        .font(.custom("Noteworthy-Light", size: 12))
                        .foregroundColor(inkColor.opacity(0.6))
                }
                
                Spacer()
                
                // Cycle indicator
                Text("Cycle \(entry.cycleNumber)")
                    .font(.custom("Noteworthy-Light", size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.7))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.6))
                    .shadow(color: inkColor.opacity(0.1), radius: 2, x: 1, y: 1)
            )
            
            // Previous answer text with expandable option
            VStack(alignment: .leading, spacing: 8) {
                // Show truncated or full text based on expansion state
                let characterLimit = 150
                let shouldTruncate = entry.answer.count > characterLimit && !isPreviousAnswerExpanded
                
                Text(shouldTruncate ? String(entry.answer.prefix(characterLimit)) + "..." : entry.answer)
                    .font(.custom("Noteworthy-Light", size: 17))
                    .foregroundColor(inkColor.opacity(0.7))
                    .lineSpacing(10)
                    .multilineTextAlignment(.leading)
                    .italic()
                    .animation(.easeInOut(duration: 0.3), value: isPreviousAnswerExpanded)
                
                // Show expand/collapse button if text is long
                if entry.answer.count > characterLimit {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPreviousAnswerExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isPreviousAnswerExpanded ? "See less" : "See more")
                                .font(.custom("Noteworthy-Light", size: 14))
                            Image(systemName: isPreviousAnswerExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
    
    private var answerOnLines: some View {
        VStack(alignment: .leading, spacing: 0) {
            // TextEditor with proper mathematical positioning and fixed placeholder
            ZStack(alignment: .topLeading) {
                // Background placeholder that doesn't block touches
                if answer.isEmpty && isViewingToday {
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
                    .focused($isTextEditorFocused)
                    .onTapGesture {
                        // Prevent unwanted scrolling when tapping
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTextEditorFocused = true
                        }
                    }
                    .onChange(of: answer) { _, newValue in
                        // Only auto-save if viewing today
                        if isViewingToday {
                            hasUnsavedChanges = true
                            autoSaveTimer?.invalidate()
                            autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                                autoSaveEntry()
                            }
                        }
                    }
                    .disabled(!isViewingToday) // Disable editing for past days
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 30)
    }
    
    private var savingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
            
            Text("Saving...")
                .font(.custom("Noteworthy-Light", size: 14))
                .foregroundColor(accentColor)
        }
        .padding(.horizontal)
    }
    
    private var savedIndicator: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))
            
            Text("Saved")
                .font(.custom("Noteworthy-Light", size: 14))
                .foregroundColor(.green)
        }
        .padding(.horizontal)
    }
    
    
    private func autoSaveEntry() {
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only save if there's content
        if !trimmedAnswer.isEmpty {
            questionManager.saveEntry(answer: trimmedAnswer)
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            hasUnsavedChanges = false
        }
    }
    
    private func updateViewForCurrentDate() {
        isViewingToday = Calendar.current.isDateInToday(currentViewDate)
        
        // Reset expanded state when changing dates
        isPreviousAnswerExpanded = false
        
        // Update question manager for the current date
        questionManager.updateQuestionForDate(currentViewDate)
        
        // Use DispatchQueue to ensure the question manager state updates before loading entry
        DispatchQueue.main.async {
            self.loadEntryForDate(self.currentViewDate)
        }
    }
    
    private func loadEntryForDate(_ date: Date) {
        guard let questionId = questionManager.todaysQuestion?.id else { 
            answer = ""
            return 
        }
        
        let context = modelContext
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
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
            answer = entries.first?.answer ?? ""
        } catch {
            print("Error loading entry for date: \(error)")
            answer = ""
        }
    }
    
    private func previousDay() {
        // Try to find the last journaled date before current view date
        if let previousJournaledDate = questionManager.getPreviousJournaledDate(before: currentViewDate) {
            // Navigate to the last journaled date
            currentViewDate = previousJournaledDate
        } else {
            // If no previous journal entries, try going back one day (but respect start date)
            let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentViewDate) ?? currentViewDate
            
            // Check if the new date is before the journal start date
            if let startDate = UserDefaults.standard.object(forKey: "journalStartDate") as? Date {
                if newDate >= startDate {
                    currentViewDate = newDate
                }
            } else {
                currentViewDate = newDate
            }
        }
    }
    
    private func nextDay() {
        // First try to find the next journaled date
        if let nextJournaledDate = questionManager.getNextJournaledDate(after: currentViewDate) {
            // Only navigate if it's not in the future
            if nextJournaledDate <= Date() {
                currentViewDate = nextJournaledDate
            } else {
                // If next journaled date is in the future, go to tomorrow if it's not future
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currentViewDate) ?? currentViewDate
                if tomorrow <= Date() {
                    currentViewDate = tomorrow
                }
            }
        } else {
            // No future journal entries, just go to tomorrow if it's not future
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currentViewDate) ?? currentViewDate
            if tomorrow <= Date() {
                currentViewDate = tomorrow
            }
        }
    }
    
    private func getDayNumber(for date: Date) -> Int {
        return questionManager.getDayNumber(for: date)
    }
    
    private func getCycleNumber(for date: Date) -> Int {
        return questionManager.getCycleNumber(for: date)
    }
}
