//
//  QuestionManager.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import Foundation
import SwiftData
import UIKit

@MainActor
class QuestionManager: ObservableObject {
    @Published var questions: [Question] = []
    @Published var todaysQuestion: Question?
    @Published var previousAnswer: JournalEntry?
    @Published var currentDayNumber: Int = 1
    @Published var currentCycleNumber: Int = 1
    
    private let userDefaults = UserDefaults.standard
    private let startDateKey = "journalStartDate"
    private let lastJournalDateKey = "lastJournalDate"
    private let customQuestionsKey = "customQuestions"
    private let questionOrderKey = "questionOrder"
    private let lastCalculatedDateKey = "lastCalculatedDate"
    
    var modelContext: ModelContext? {
        didSet {
            // Sync existing data to shared container when model context becomes available
            if let context = modelContext {
                SharedDataManager.shared.syncJournalData(from: context)
            }
        }
    }
    
    // Get the 30 questions (default order or custom order)
    var orderedQuestions: [Question] {
        let questionOrder = userDefaults.array(forKey: questionOrderKey) as? [Int] ?? Array(1...30)
        
        // Only use the first 30 questions, ordered as specified
        let sortedQuestions = questionOrder.prefix(30).compactMap { id in
            questions.first { $0.id == id }
        }
        
        // Fill any missing slots with default questions
        var result = Array(sortedQuestions)
        while result.count < 30 {
            if let missingQuestion = questions.first(where: { question in
                !result.contains { $0.id == question.id }
            }) {
                result.append(missingQuestion)
            } else {
                break
            }
        }
        
        return Array(result.prefix(30)) // Ensure exactly 30 questions
    }
    
    init() {
        loadQuestions()
        calculateCurrentDay()
        setupDateChangeNotification()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadQuestions() {
        loadEditedQuestions()
        updateTodaysQuestion()
    }
    
    func calculateCurrentDay() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we need to recalculate (day has changed or first time)
        let today = calendar.startOfDay(for: now)
        let lastCalculatedDate = userDefaults.object(forKey: lastCalculatedDateKey) as? Date
        let lastCalculatedDay = lastCalculatedDate.map { calendar.startOfDay(for: $0) }
        
        // Only recalculate if the day has actually changed or it's the first time
        if lastCalculatedDay != today || lastCalculatedDate == nil {
            if lastCalculatedDate == nil {
                print("🆕 First calculation")
            } else {
                print("📅 Day changed - recalculating")
            }
            
            // Get or set the start date
            if let startDate = userDefaults.object(forKey: startDateKey) as? Date {
                let days = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
                
                // Calculate which 30-day cycle we're in
                currentCycleNumber = (days / 30) + 1
                currentDayNumber = (days % 30) + 1
                
                print("📊 Days since start: \(days), Cycle: \(currentCycleNumber), Day: \(currentDayNumber)")
            } else {
                // First time using the app
                userDefaults.set(now, forKey: startDateKey)
                currentDayNumber = 1
                currentCycleNumber = 1
                print("🆕 First time setup - Day 1, Cycle 1")
            }
            
            // Save the last calculated date
            userDefaults.set(now, forKey: lastCalculatedDateKey)
            
            updateTodaysQuestion()
            
            // Also update the previous answer for the new day
            fetchPreviousAnswer()
        } else {
            print("📅 Same day - no recalculation needed")
        }
    }
    
    func updateTodaysQuestion() {
        let orderedQuestionsList = orderedQuestions
        guard orderedQuestionsList.count == 30 else { return }
        
        // Day number corresponds to question index (1-30)
        let questionIndex = (currentDayNumber - 1) % 30
        todaysQuestion = orderedQuestionsList[questionIndex]
        
        // Fetch previous answer if we're in cycle 2 or later
        if currentCycleNumber > 1 {
            fetchPreviousAnswer()
        }
    }
    
    func updateQuestionForDate(_ date: Date) {
        let dayNumber = getDayNumber(for: date)
        let cycleNumber = getCycleNumber(for: date)
        
        let orderedQuestionsList = orderedQuestions
        guard orderedQuestionsList.count == 30 else { 
            todaysQuestion = nil
            return 
        }
        
        // Ensure valid day number (should be 1-30)
        let safeDayNumber = max(1, min(30, dayNumber))
        let questionIndex = (safeDayNumber - 1) % 30
        
        // Ensure question index is within bounds
        guard questionIndex >= 0 && questionIndex < orderedQuestionsList.count else {
            todaysQuestion = nil
            return
        }
        
        todaysQuestion = orderedQuestionsList[questionIndex]
        
        // Set current numbers for the viewed date
        currentDayNumber = dayNumber
        currentCycleNumber = cycleNumber
        
        // Fetch previous answer if we're in cycle 2 or later
        if cycleNumber > 1 {
            fetchPreviousAnswer(for: date)
        }
    }
    
    func getDayNumber(for date: Date) -> Int {
        let calendar = Calendar.current
        if let startDate = userDefaults.object(forKey: startDateKey) as? Date {
            let days = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            // Ensure we don't go before the start date (negative days)
            if days < 0 {
                return 1 // Default to day 1 if before start date
            }
            return (days % 30) + 1
        }
        return 1
    }
    
    func getCycleNumber(for date: Date) -> Int {
        let calendar = Calendar.current
        if let startDate = userDefaults.object(forKey: startDateKey) as? Date {
            let days = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
            // Ensure we don't go before the start date (negative days)
            if days < 0 {
                return 1 // Default to cycle 1 if before start date
            }
            return (days / 30) + 1
        }
        return 1
    }
    
    func fetchPreviousAnswer() {
        // Use current view date from the app, fallback to today
        fetchPreviousAnswer(for: Date())
    }
    
    func fetchPreviousAnswer(for date: Date) {
        guard let context = modelContext,
              let questionId = todaysQuestion?.id else { 
            previousAnswer = nil
            return 
        }
        
        let calendar = Calendar.current
        let startOfViewDate = calendar.startOfDay(for: date)
        
        // Find previous answers for this question before the current view date
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.questionId == questionId
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try context.fetch(descriptor)
            // Get the most recent previous answer before the current view date
            previousAnswer = entries.first { entry in
                calendar.startOfDay(for: entry.date) < startOfViewDate
            }
        } catch {
            print("Error fetching previous answer: \(error)")
            previousAnswer = nil
        }
    }
    
    func saveEntry(answer: String) {
        guard let context = modelContext,
              let question = todaysQuestion else { return }
        
        // Check if an entry already exists for today's question
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.questionId == question.id &&
                entry.date >= startOfDay &&
                entry.date < endOfDay
            }
        )
        
        do {
            let existingEntries = try context.fetch(descriptor)
            
            if let existingEntry = existingEntries.first {
                // Update existing entry
                existingEntry.answer = answer
                existingEntry.date = Date() // Update the timestamp
            } else {
                // Create new entry
                let newEntry = JournalEntry(
                    questionId: question.id,
                    question: question.text,
                    answer: answer,
                    date: Date(),
                    dayNumber: currentDayNumber,
                    cycleNumber: currentCycleNumber
                )
                context.insert(newEntry)
            }
            
            try context.save()
            userDefaults.set(Date(), forKey: lastJournalDateKey)
            
            // Sync data to shared container for widget
            SharedDataManager.shared.syncJournalData(from: context)
        } catch {
            print("Error saving entry: \(error)")
        }
    }
    
    func hasJournaledToday() -> Bool {
        guard let lastDate = userDefaults.object(forKey: lastJournalDateKey) as? Date else {
            return false
        }
        
        return Calendar.current.isDateInToday(lastDate)
    }
    
    func getEntriesForMonth(date: Date) -> [JournalEntry] {
        guard let context = modelContext else { return [] }
        
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= startOfMonth && entry.date < endOfMonth
            },
            sortBy: [SortDescriptor(\.date)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching entries for month: \(error)")
            return []
        }
    }
    
    func getStreak() -> Int {
        guard let context = modelContext else { return 0 }
        
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try context.fetch(descriptor)
            return calculateStreak(from: entries)
        } catch {
            print("Error calculating streak: \(error)")
            return 0
        }
    }
    
    func getPreviousJournaledDate(before date: Date) -> Date? {
        guard let context = modelContext else { return nil }
        
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date < startOfDate
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try context.fetch(descriptor)
            return entries.first?.date
        } catch {
            print("Error finding previous journaled date: \(error)")
            return nil
        }
    }
    
    func getNextJournaledDate(after date: Date) -> Date? {
        guard let context = modelContext else { return nil }
        
        let calendar = Calendar.current
        let endOfDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.date >= endOfDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            let entries = try context.fetch(descriptor)
            return entries.first?.date
        } catch {
            print("Error finding next journaled date: \(error)")
            return nil
        }
    }
    
    private func calculateStreak(from entries: [JournalEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        for entry in entries {
            if calendar.isDate(entry.date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if calendar.isDate(entry.date, inSameDayAs: checkDate) {
                continue
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Question Management (30 Questions Only)
    
    func updateQuestionText(questionId: Int, newText: String) {
        // Update the question text in our questions array
        if let index = questions.firstIndex(where: { $0.id == questionId }) {
            questions[index] = Question(id: questionId, text: newText, category: questions[index].category)
            
            // Save updated questions to UserDefaults
            saveQuestionsToUserDefaults()
            updateTodaysQuestion()
        }
    }
    
    private func saveQuestionsToUserDefaults() {
        do {
            let questionsData = try JSONEncoder().encode(questions)
            userDefaults.set(questionsData, forKey: "editedQuestions")
        } catch {
            print("Error saving questions: \(error)")
        }
    }
    
    private func loadEditedQuestions() {
        if let questionsData = userDefaults.data(forKey: "editedQuestions") {
            do {
                questions = try JSONDecoder().decode([Question].self, from: questionsData)
            } catch {
                print("Error loading edited questions: \(error)")
                // Fall back to loading from JSON file
                loadQuestionsFromFile()
            }
        } else {
            loadQuestionsFromFile()
        }
    }
    
    private func loadQuestionsFromFile() {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            print("Questions file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let questionsData = try JSONDecoder().decode(QuestionsData.self, from: data)
            self.questions = questionsData.questions
        } catch {
            print("Error loading questions from file: \(error)")
        }
    }
    
    func moveQuestion(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < questions.count && destinationIndex < questions.count else { return }
        
        // Move the actual question in the array
        let questionToMove = questions.remove(at: sourceIndex)
        questions.insert(questionToMove, at: destinationIndex)
        
        // Update IDs to maintain 1-30 order
        for (index, _) in questions.enumerated() {
            questions[index] = Question(id: index + 1, text: questions[index].text, category: questions[index].category)
        }
        
        saveQuestionsToUserDefaults()
        updateTodaysQuestion()
    }
    
    func resetToDefaultOrder() {
        userDefaults.removeObject(forKey: questionOrderKey)
        userDefaults.removeObject(forKey: "editedQuestions")
        loadQuestionsFromFile()
        updateTodaysQuestion()
    }
    
    // MARK: - Date Change Detection
    
    private func setupDateChangeNotification() {
        // Listen for day change notifications (midnight transitions)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
        
        // Listen for app becoming active (foreground transitions)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func dayChanged() {
        print("🌅 Day changed notification received - recalculating")
        Task { @MainActor in
            calculateCurrentDay()
        }
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 App became active - checking if day changed")
        Task { @MainActor in
            calculateCurrentDay()
        }
    }
    
}