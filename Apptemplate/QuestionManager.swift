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
    
    var modelContext: ModelContext?
    
    init() {
        loadQuestions()
        calculateCurrentDay()
    }
    
    func loadQuestions() {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            print("Questions file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let questionsData = try JSONDecoder().decode(QuestionsData.self, from: data)
            self.questions = questionsData.questions
            updateTodaysQuestion()
        } catch {
            print("Error loading questions: \(error)")
        }
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
        guard !questions.isEmpty else { return }
        
        // Day number corresponds to question ID (1-30)
        let questionIndex = currentDayNumber - 1
        if questionIndex < questions.count {
            todaysQuestion = questions[questionIndex]
            
            // If we're past the first cycle, fetch the previous answer
            if currentCycleNumber > 1 {
                fetchPreviousAnswer()
            }
        }
    }
    
    func fetchPreviousAnswer() {
        guard let context = modelContext,
              let questionId = todaysQuestion?.id else { return }
        
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.questionId == questionId && entry.cycleNumber == currentCycleNumber - 1
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try context.fetch(descriptor)
            previousAnswer = entries.first
        } catch {
            print("Error fetching previous answer: \(error)")
        }
    }
    
    func saveEntry(answer: String) {
        guard let context = modelContext,
              let question = todaysQuestion else { return }
        
        let entry = JournalEntry(
            questionId: question.id,
            question: question.text,
            answer: answer,
            date: Date(),
            dayNumber: currentDayNumber,
            cycleNumber: currentCycleNumber
        )
        
        context.insert(entry)
        
        do {
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
}