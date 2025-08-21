//
//  calendarwidget.swift
//  calendarwidget
//
//  Created by Mohamed Abdelmagid on 8/20/25.
//

import WidgetKit
import SwiftUI

// MARK: - Data Models
struct JournalCalendarEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let journalDates: Set<Int> // Days of month with journal entries
    let currentMonth: Date
    let totalEntries: Int
    let currentStreak: Int
}

// MARK: - Timeline Provider
struct JournalCalendarProvider: AppIntentTimelineProvider {
    
    // Journal app theme colors
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    func placeholder(in context: Context) -> JournalCalendarEntry {
        JournalCalendarEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            journalDates: Set([1, 5, 10, 15, 20]),
            currentMonth: Date(),
            totalEntries: 5,
            currentStreak: 3
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> JournalCalendarEntry {
        let journalData = fetchJournalData()
        return JournalCalendarEntry(
            date: Date(),
            configuration: configuration,
            journalDates: journalData.journalDates,
            currentMonth: Date(),
            totalEntries: journalData.totalEntries,
            currentStreak: journalData.currentStreak
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<JournalCalendarEntry> {
        var entries: [JournalCalendarEntry] = []
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Update widget at the start of each day
        let startOfDay = calendar.startOfDay(for: currentDate)
        let journalData = fetchJournalData()
        
        // Create entries for next 7 days (widget will update daily)
        for dayOffset in 0..<7 {
            if let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay) {
                let entry = JournalCalendarEntry(
                    date: entryDate,
                    configuration: configuration,
                    journalDates: journalData.journalDates,
                    currentMonth: currentDate,
                    totalEntries: journalData.totalEntries,
                    currentStreak: journalData.currentStreak
                )
                entries.append(entry)
            }
        }
        
        // Update daily at midnight
        let nextUpdate = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? currentDate
        return Timeline(entries: entries, policy: .after(nextUpdate))
    }
    
    private func fetchJournalData() -> (journalDates: Set<Int>, totalEntries: Int, currentStreak: Int) {
        // Try to fetch real journal data from shared app group container
        if let sharedDefaults = UserDefaults(suiteName: "group.com.mohamedabdelmagid.JournalApp") {
            let journalDates = Set(sharedDefaults.array(forKey: "shared_journal_dates") as? [Int] ?? [])
            let totalEntries = sharedDefaults.integer(forKey: "shared_total_entries")
            let currentStreak = sharedDefaults.integer(forKey: "shared_current_streak")
            let lastUpdateDate = sharedDefaults.object(forKey: "shared_last_update_date") as? Date
            
            // If we have a last update date, that means the app has synced data at least once
            if let lastUpdate = lastUpdateDate {
                print("✅ Using real journal data: \(journalDates.count) days, \(totalEntries) total entries, \(currentStreak) streak (last update: \(lastUpdate))")
                return (journalDates, totalEntries, currentStreak)
            }
        }
        
        // Return empty data when no sync has happened yet (new user or app group not configured)
        print("⚠️ No shared journal data found, showing empty state")
        return (journalDates: Set<Int>(), totalEntries: 0, currentStreak: 0)
    }
}

// MARK: - Widget View
struct JournalCalendarWidgetView: View {
    var entry: JournalCalendarProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    // Journal app theme colors
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .systemLarge:
            largeWidgetView
        default:
            mediumWidgetView
        }
    }
    
    // MARK: - Small Widget
    private var smallWidgetView: some View {
        VStack(spacing: 8) {
            Spacer()
            
            // Large streak display
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                Text("\(entry.currentStreak)")
                    .font(.custom("Noteworthy-Bold", size: 36))
                    .foregroundColor(inkColor)
                
                Text("day streak")
                    .font(.custom("Noteworthy-Light", size: 12))
                    .foregroundColor(inkColor.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(12)
        .background(paperColor)
    }
    
    // MARK: - Medium Widget
    private var mediumWidgetView: some View {
        VStack(spacing: 12) {
            // Current week header
            Text("This Week")
                .font(.custom("Noteworthy-Bold", size: 16))
                .foregroundColor(inkColor)
            
            // Current week calendar only
            currentWeekView
        }
        .padding(16)
        .background(paperColor)
    }
    
    // MARK: - Large Widget
    private var largeWidgetView: some View {
        VStack(spacing: 12) {
            // Month header
            Text(entry.currentMonth, format: .dateTime.month(.wide).year())
                .font(.custom("Noteworthy-Bold", size: 20))
                .foregroundColor(inkColor)
            
            // Full month calendar only
            fullMonthCalendarView
        }
        .padding(16)
        .background(paperColor)
    }
    
    // MARK: - Helper Views
    private var currentWeekView: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(String(day.prefix(1)))
                        .font(.custom("Noteworthy-Light", size: 12))
                        .foregroundColor(inkColor.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Current week days
            HStack(spacing: 0) {
                ForEach(getCurrentWeekDays(), id: \.self) { day in
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isToday(day) ? accentColor.opacity(0.2) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isToday(day) ? accentColor : Color.clear, lineWidth: 1)
                                )
                            
                            Text("\(Calendar.current.component(.day, from: day))")
                                .font(.custom("Noteworthy-Light", size: 16))
                                .foregroundColor(inkColor)
                        }
                        .frame(height: 32)
                        
                        if hasJournalEntry(for: day) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private var weekView: some View {
        HStack(spacing: 4) {
            ForEach(getCurrentWeekDays(), id: \.self) { day in
                VStack(spacing: 2) {
                    Text(dayOfWeekLabel(for: day))
                        .font(.system(size: 9))
                        .foregroundColor(inkColor.opacity(0.5))
                    
                    ZStack {
                        Circle()
                            .fill(isToday(day) ? accentColor.opacity(0.2) : Color.clear)
                            .overlay(
                                Circle()
                                    .stroke(isToday(day) ? accentColor : Color.clear, lineWidth: 1)
                            )
                        
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(inkColor)
                        
                        if hasJournalEntry(for: day) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 4, height: 4)
                                .offset(y: 8)
                        }
                    }
                    .frame(width: 22, height: 22)
                }
            }
        }
    }
    
    
    private var fullMonthCalendarView: some View {
        VStack(spacing: 6) {
            // Weekday headers
            HStack(spacing: 12) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.custom("Noteworthy-Light", size: 12))
                        .foregroundColor(inkColor.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Full calendar grid
            let days = getDaysInMonth()
            let rows = (days.count + 6) / 7
            
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        if index < days.count, let day = days[index] {
                            dayCell(for: day, size: 28)
                        } else {
                            Color.clear
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            }
        }
    }
    
    private func dayCell(for date: Date, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isToday(date) ? accentColor.opacity(0.2) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isToday(date) ? accentColor : Color.clear, lineWidth: 1)
                )
            
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.custom("Noteworthy-Light", size: size * 0.6))
                    .foregroundColor(inkColor)
                
                if hasJournalEntry(for: date) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: size * 0.2, height: size * 0.2)
                }
            }
        }
        .frame(width: size, height: size)
    }
    
    
    // MARK: - Helper Functions
    private func getCurrentWeekDays() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        
        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) else {
            return []
        }
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStart)
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: entry.currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        let numberOfDays = calendar.range(of: .day, in: .month, for: entry.currentMonth)?.count ?? 0
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasJournalEntry(for date: Date) -> Bool {
        let day = Calendar.current.component(.day, from: date)
        return entry.journalDates.contains(day)
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private func dayOfWeekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
    
}

struct calendarwidget: Widget {
    let kind: String = "calendarwidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: JournalCalendarProvider()) { entry in
            JournalCalendarWidgetView(entry: entry)
                .containerBackground(Color(red: 0.98, green: 0.96, blue: 0.91), for: .widget)
        }
        .configurationDisplayName("Journal Calendar")
        .description("View your journal entries and streak at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    calendarwidget()
} timeline: {
    JournalCalendarEntry(date: .now, configuration: .smiley, journalDates: Set([1, 5, 10, 15, 20]), currentMonth: .now, totalEntries: 12, currentStreak: 5)
    JournalCalendarEntry(date: .now, configuration: .starEyes, journalDates: Set([2, 7, 14, 21, 28]), currentMonth: .now, totalEntries: 8, currentStreak: 3)
}
