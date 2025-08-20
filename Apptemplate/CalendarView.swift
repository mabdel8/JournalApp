//
//  CalendarView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeManager: StoreManager
    @StateObject private var questionManager = QuestionManager()
    @State private var selectedMonth = Date()
    @State private var journalEntries: [JournalEntry] = []
    @State private var selectedEntry: JournalEntry?
    @State private var showingEntryDetail = false
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        ZStack {
            paperColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Streak counter (Premium feature)
                    if storeManager.isSubscribed {
                        streakView
                    }
                    
                    // Month navigation
                    monthNavigationView
                    
                    // Calendar grid
                    calendarGridView
                    
                    // Stats section
                    statsView
                }
                .padding()
            }
        }
        .navigationTitle("Journal Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
        }
        .onAppear {
            questionManager.modelContext = modelContext
            loadEntriesForMonth()
        }
        .onChange(of: selectedMonth) { _, _ in
            loadEntriesForMonth()
        }
    }
    
    private var streakView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 15) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(questionManager.getStreak())")
                        .font(.custom("Noteworthy-Bold", size: 32))
                        .foregroundColor(inkColor)
                    
                    Text("day streak")
                        .font(.custom("Noteworthy-Light", size: 14))
                        .foregroundColor(inkColor.opacity(0.6))
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }
    
    private var monthNavigationView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            Text(selectedMonth, format: .dateTime.month(.wide).year())
                .font(.custom("Noteworthy-Bold", size: 20))
                .foregroundColor(inkColor)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(accentColor)
            }
        }
        .padding(.horizontal)
    }
    
    private var calendarGridView: some View {
        VStack(spacing: 10) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.custom("Noteworthy-Bold", size: 14))
                        .foregroundColor(inkColor.opacity(0.6))
                }
            }
            
            // Calendar days
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayView(
                            date: date,
                            hasEntry: hasEntry(for: date),
                            isToday: calendar.isDateInToday(date),
                            entry: getEntry(for: date)
                        ) {
                            if let entry = getEntry(for: date) {
                                selectedEntry = entry
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.5))
        )
    }
    
    private var statsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("This Month")
                .font(.custom("Noteworthy-Bold", size: 18))
                .foregroundColor(inkColor)
            
            HStack(spacing: 30) {
                StatItem(
                    icon: "book.fill",
                    value: "\(journalEntries.count)",
                    label: "Entries"
                )
                
                StatItem(
                    icon: "percent",
                    value: "\(Int((Double(journalEntries.count) / Double(getDaysPassedInMonth())) * 100))%",
                    label: "Completion"
                )
                
                if storeManager.isSubscribed {
                    StatItem(
                        icon: "star.fill",
                        value: "\(getLongestStreakInMonth())",
                        label: "Best Streak"
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.05))
        )
    }
    
    private func previousMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    
    private func nextMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        let numberOfDays = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 0
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining days to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasEntry(for date: Date) -> Bool {
        journalEntries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    private func getEntry(for date: Date) -> JournalEntry? {
        journalEntries.first { entry in
            calendar.isDate(entry.date, inSameDayAs: date)
        }
    }
    
    private func loadEntriesForMonth() {
        journalEntries = questionManager.getEntriesForMonth(date: selectedMonth)
    }
    
    private func getDaysPassedInMonth() -> Int {
        let now = Date()
        
        if calendar.isDate(selectedMonth, equalTo: now, toGranularity: .month) {
            return calendar.component(.day, from: now)
        } else if selectedMonth < now {
            return calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        } else {
            return 1
        }
    }
    
    private func getLongestStreakInMonth() -> Int {
        guard !journalEntries.isEmpty else { return 0 }
        
        let sortedEntries = journalEntries.sorted { $0.date < $1.date }
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedEntries.count {
            let prevDate = sortedEntries[i-1].date
            let currentDate = sortedEntries[i].date
            
            if let daysDiff = calendar.dateComponents([.day], from: prevDate, to: currentDate).day,
               daysDiff == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
}

struct DayView: View {
    let date: Date
    let hasEntry: Bool
    let isToday: Bool
    let entry: JournalEntry?
    let action: () -> Void
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? accentColor.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isToday ? accentColor : Color.clear, lineWidth: 2)
                    )
                
                VStack(spacing: 4) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.custom("Noteworthy-Light", size: 16))
                        .foregroundColor(inkColor)
                    
                    if hasEntry {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(entry == nil)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accentColor)
            
            Text(value)
                .font(.custom("Noteworthy-Bold", size: 20))
                .foregroundColor(inkColor)
            
            Text(label)
                .font(.custom("Noteworthy-Light", size: 12))
                .foregroundColor(inkColor.opacity(0.6))
        }
    }
}

struct EntryDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(entry.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                            .font(.custom("Noteworthy-Light", size: 16))
                            .foregroundColor(inkColor.opacity(0.6))
                        
                        Text(entry.question)
                            .font(.custom("Noteworthy-Bold", size: 20))
                            .foregroundColor(inkColor)
                        
                        Text(entry.answer)
                            .font(.custom("Noteworthy-Light", size: 18))
                            .foregroundColor(inkColor)
                            .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}