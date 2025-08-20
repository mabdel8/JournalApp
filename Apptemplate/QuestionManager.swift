//
//  QuestionManager.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import Foundation
import SwiftData

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
    
    var modelContext: ModelContext?
    
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
    }
    
    func loadQuestions() {
        loadEditedQuestions()
        updateTodaysQuestion()
    }
    
    func calculateCurrentDay() {
        let now = Date()
        let calendar = Calendar.current
        
        // Get or set the start date
        if let startDate = userDefaults.object(forKey: startDateKey) as? Date {
            let days = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
            
            // Calculate which 30-day cycle we're in
            currentCycleNumber = (days / 30) + 1
            currentDayNumber = (days % 30) + 1
        } else {
            // First time using the app
            userDefaults.set(now, forKey: startDateKey)
            currentDayNumber = 1
            currentCycleNumber = 1
        }
        
        updateTodaysQuestion()
    }
    
    func updateTodaysQuestion() {
        let orderedQuestionsList = orderedQuestions
        guard orderedQuestionsList.count == 30 else { return }
        
        // Day number corresponds to question index (1-30)
        let questionIndex = (currentDayNumber - 1) % 30
        todaysQuestion = orderedQuestionsList[questionIndex]
        
        // Always try to fetch previous answers for testing
        // In production, you'd only do this if currentCycleNumber > 1
        fetchPreviousAnswer()
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
        
        // Always try to fetch previous answers for testing
        // In production, you'd only do this if cycleNumber > 1
        fetchPreviousAnswer(for: date)
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
    
    // MARK: - Test Data (Remove this in production)
    
    func createTestDataForPreviousAnswers() {
        guard let context = modelContext else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // CRITICAL FIX: Set journal start date to 75 days ago so all test dates fall AFTER start date
        // This ensures proper question ID calculation instead of all entries defaulting to question 1
        let journalStartDate = calendar.date(byAdding: .day, value: -75, to: now)!
        userDefaults.set(journalStartDate, forKey: startDateKey)
        
        // Pool of varied, realistic answers for different question types
        let answerPool = [
            "I felt most grateful for my morning coffee ritual. That quiet moment before the world wakes up centers me completely.",
            "The biggest challenge I overcame was speaking up in a difficult conversation. I'm proud I found my voice.",
            "I smiled when I saw a stranger help an elderly person with groceries. Kindness is everywhere if we look.",
            "Today I learned that taking breaks actually makes me more productive. Rest isn't laziness, it's necessary.",
            "I'm grateful for rainy days like today. They force me to slow down and appreciate being cozy indoors.",
            "The most meaningful conversation was with my neighbor about their garden. Simple connections matter most.",
            "I felt proudest when I completed my first 5K run. Three months ago, I couldn't run around the block.",
            "Today taught me that patience really is a virtue. Traffic can't control my inner peace anymore.",
            "I discovered a hidden coffee shop that feels like a secret haven. The best places are often right under our noses.",
            "The kindness I showed myself was forgiving my mistakes. Self-compassion is harder than it sounds.",
            "I felt most connected during dinner with family. No phones, just real conversation and laughter.",
            "Today I smiled realizing how much I've grown since last year. Progress isn't always obvious day by day.",
            "The challenge I overcame was admitting I was wrong and apologizing sincerely. Pride is hard to swallow.",
            "I learned that saying no to some things means saying yes to what really matters to me.",
            "I'm grateful for unexpected phone calls from old friends. Some bonds never fade, no matter the distance.",
            "Today I felt proud helping a coworker solve a problem they'd been struggling with for weeks.",
            "The most meaningful moment was watching the sunset and realizing how rarely I stop to notice beauty around me.",
            "I discovered I actually enjoy cooking when I'm not rushing. Mindful preparation becomes meditation.",
            "The kindness I received from a complete stranger at the store restored my faith in human goodness.",
            "Today I felt most connected sitting in comfortable silence with my pet. Sometimes presence is enough.",
            "I smiled remembering how different my answer to this question was in previous cycles. Growth is real.",
            "The challenge I overcame was my perfectionism. Done is so much better than perfect and never finished.",
            "Today I learned that vulnerability is actually a superpower, not a weakness like I always thought.",
            "I'm grateful for second chances and the opportunity to do better than I did yesterday.",
            "The proudest moment was standing up for someone who couldn't advocate for themselves. Courage matters.",
            "I felt grateful for my health today after hearing about a friend's diagnosis. We take so much for granted.",
            "The biggest learning was that listening is more powerful than having the right answer all the time.",
            "I smiled when I caught myself humming while doing mundane chores. Joy can be found anywhere.",
            "Today's challenge was letting go of control and trusting the process. Some things work out on their own.",
            "I discovered that my dog is an excellent judge of character. Animals know things we miss.",
            "The meaningful connection happened with a cashier who remembered my usual order. Small gestures matter.",
            "I felt proud of choosing to rest instead of pushing through exhaustion. Self-care isn't selfish.",
            "Today I learned that asking for help is a sign of wisdom, not weakness or failure.",
            "I'm grateful for books that transport me to different worlds when reality feels too heavy.",
            "The kindness I showed was buying coffee for the person behind me. Spreading joy is contagious.",
            "Today I felt connected to my younger self while looking through old photos. That dreamer is still here.",
            "I smiled when I realized my plants are thriving because I finally learned their individual needs.",
            "The challenge was setting boundaries without feeling guilty. Protecting my energy helps everyone.",
            "I discovered that slow mornings are worth waking up earlier for. Rushing sets a frantic tone.",
            "Today's meaningful moment was my grandmother sharing stories about her youth. History lives in our elders."
        ]
        
        var testEntries: [(questionId: Int, date: Date, answer: String)] = []
        
        // Generate realistic test data over past 70 days with proper question distribution
        for daysAgo in 1...70 {
            // Skip some days randomly (30% chance to skip) to create realistic gaps
            if Int.random(in: 1...10) <= 3 { continue }
            
            if let testDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                // Calculate correct question ID based on days since journal start
                let daysSinceStart = calendar.dateComponents([.day], from: journalStartDate, to: testDate).day ?? 0
                let questionId = (daysSinceStart % 30) + 1
                
                // Select random answer from pool
                let randomAnswer = answerPool.randomElement()!
                
                testEntries.append((questionId: questionId, date: testDate, answer: randomAnswer))
            }
        }
        
        for (questionId, testDate, answer) in testEntries {
            if let question = orderedQuestions.first(where: { $0.id == questionId }) {
                let dayNumber = getDayNumber(for: testDate)
                let cycleNumber = getCycleNumber(for: testDate)
                
                let testEntry = JournalEntry(
                    questionId: questionId,
                    question: question.text,
                    answer: answer,
                    date: testDate,
                    dayNumber: dayNumber,
                    cycleNumber: cycleNumber
                )
                context.insert(testEntry)
            }
        }
        
        do {
            try context.save()
            print("Test data created for timeline feature")
        } catch {
            print("Error creating test data: \(error)")
        }
    }
    
    func clearTestData() {
        guard let context = modelContext else { return }
        
        do {
            // Delete all journal entries (for testing purposes)
            let allEntries = try context.fetch(FetchDescriptor<JournalEntry>())
            for entry in allEntries {
                context.delete(entry)
            }
            try context.save()
            print("Test data cleared")
        } catch {
            print("Error clearing test data: \(error)")
        }
    }
}