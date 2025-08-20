//
//  Question.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import Foundation

struct Question: Codable, Identifiable {
    let id: Int
    let text: String
    let category: String
}

struct QuestionsData: Codable {
    let questions: [Question]
}