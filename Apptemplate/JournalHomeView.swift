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
    @State private var autoSaveTimer: Timer?
    @State private var hasUnsavedChanges = false
    @State private var currentViewDate = Date() // Track which day we're viewing
    @State private var isViewingToday = true
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
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isAtStartDate ? inkColor.opacity(0.3) : accentColor)
                }
                .disabled(isAtStartDate)
                
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
        
        // Update question manager for the current date
        questionManager.updateQuestionForDate(currentViewDate)
        
        // Load entry for the current date
        loadEntryForDate(currentViewDate)
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
        let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentViewDate) ?? currentViewDate
        
        // Check if the new date is before the journal start date
        if let startDate = UserDefaults.standard.object(forKey: "journalStartDate") as? Date {
            if newDate >= startDate {
                currentViewDate = newDate
            }
            // If newDate is before startDate, don't navigate (stay on current date)
        } else {
            // If no start date is set, allow navigation
            currentViewDate = newDate
        }
    }
    
    private func nextDay() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: currentViewDate) ?? currentViewDate
        if tomorrow <= Date() {
            currentViewDate = tomorrow
        }
    }
    
    private func getDayNumber(for date: Date) -> Int {
        return questionManager.getDayNumber(for: date)
    }
    
    private func getCycleNumber(for date: Date) -> Int {
        return questionManager.getCycleNumber(for: date)
    }
}
