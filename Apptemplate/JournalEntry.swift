//
//  JournalEntry.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var questionId: Int
    var question: String
    var answer: String
    var date: Date
    var dayNumber: Int // Day in the 30-day cycle (1-30)
    var cycleNumber: Int // Which cycle (1st, 2nd, 3rd, etc.)
    
    init(questionId: Int, question: String, answer: String, date: Date = Date(), dayNumber: Int, cycleNumber: Int = 1) {
        self.id = UUID()
        self.questionId = questionId
        self.question = question
        self.answer = answer
        self.date = date
        self.dayNumber = dayNumber
        self.cycleNumber = cycleNumber
    }
}
