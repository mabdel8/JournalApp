//
//  SharedDataManager.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/20/25.
//

import Foundation
import SwiftData

/// Manages data sharing between the main app and widgets using App Groups
class SharedDataManager {
    static let shared = SharedDataManager()
    
    // App Group identifier - this needs to be configured in both app and widget targets
    private let appGroupIdentifier = "group.com.mohamedabdelmagid.JournalApp"
    
    // UserDefaults keys for shared data
    private struct Keys {
        static let journalDates = "shared_journal_dates"
        static let totalEntries = "shared_total_entries"
        static let currentStreak = "shared_current_streak"
        static let lastUpdateDate = "shared_last_update_date"
        static let monthlyEntries = "shared_monthly_entries" // [String: Int] where key is "YYYY-MM"
    }
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private init() {}
    
    // MARK: - Write Methods (Called from Main App)
    
    /// Syncs all journal data to shared container
    func syncJournalData(from context: ModelContext) {
        guard let sharedDefaults = sharedDefaults else {
            print("⚠️ Failed to access shared UserDefaults. Check app group configuration.")
            return
        }
        
        do {
            // Fetch all journal entries
            let descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.date)])
            let entries = try context.fetch(descriptor)
            
            // Extract dates (day of month) for current month
            let calendar = Calendar.current
            let currentMonth = Date()
            let currentMonthEntries = entries.filter { entry in
                calendar.isDate(entry.date, equalTo: currentMonth, toGranularity: .month)
            }
            
            let journalDates = Set(currentMonthEntries.map { calendar.component(.day, from: $0.date) })
            
            // Calculate total entries
            let totalEntries = entries.count
            
            // Calculate current streak
            let currentStreak = calculateCurrentStreak(from: entries)
            
            // Calculate monthly entries count
            let monthlyEntries = calculateMonthlyEntries(from: entries)
            
            // Save to shared defaults
            sharedDefaults.set(Array(journalDates), forKey: Keys.journalDates)
            sharedDefaults.set(totalEntries, forKey: Keys.totalEntries)
            sharedDefaults.set(currentStreak, forKey: Keys.currentStreak)
            sharedDefaults.set(Date(), forKey: Keys.lastUpdateDate)
            sharedDefaults.set(monthlyEntries, forKey: Keys.monthlyEntries)
            
            print("✅ Journal data synced to widget: \(journalDates.count) days, \(totalEntries) total entries, \(currentStreak) streak")
            
        } catch {
            print("❌ Error syncing journal data: \(error)")
        }
    }
    
    /// Quick sync when a single entry is added/updated
    func syncSingleEntry(_ entry: JournalEntry) {
        guard let sharedDefaults = sharedDefaults else { return }
        
        let calendar = Calendar.current
        let currentMonth = Date()
        
        // If the entry is in the current month, add its day to the set
        if calendar.isDate(entry.date, equalTo: currentMonth, toGranularity: .month) {
            var journalDates = Set(sharedDefaults.array(forKey: Keys.journalDates) as? [Int] ?? [])
            let day = calendar.component(.day, from: entry.date)
            journalDates.insert(day)
            sharedDefaults.set(Array(journalDates), forKey: Keys.journalDates)
        }
        
        // Update total entries count
        let currentTotal = sharedDefaults.integer(forKey: Keys.totalEntries)
        sharedDefaults.set(currentTotal + 1, forKey: Keys.totalEntries)
        
        // Update last update date
        sharedDefaults.set(Date(), forKey: Keys.lastUpdateDate)
        
        print("✅ Single entry synced to widget")
    }
    
    // MARK: - Read Methods (Called from Widget)
    
    /// Gets journal data for widget display
    func getWidgetData() -> (journalDates: Set<Int>, totalEntries: Int, currentStreak: Int) {
        guard let sharedDefaults = sharedDefaults else {
            print("⚠️ Failed to access shared UserDefaults in widget")
            return (Set(), 0, 0)
        }
        
        let journalDates = Set(sharedDefaults.array(forKey: Keys.journalDates) as? [Int] ?? [])
        let totalEntries = sharedDefaults.integer(forKey: Keys.totalEntries)
        let currentStreak = sharedDefaults.integer(forKey: Keys.currentStreak)
        
        return (journalDates, totalEntries, currentStreak)
    }
    
    /// Gets the last update date to determine if data is fresh
    func getLastUpdateDate() -> Date? {
        sharedDefaults?.object(forKey: Keys.lastUpdateDate) as? Date
    }
    
    /// Gets monthly entry count for a specific month
    func getMonthlyEntryCount(for date: Date) -> Int {
        guard let sharedDefaults = sharedDefaults else { return 0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthKey = formatter.string(from: date)
        
        let monthlyEntries = sharedDefaults.dictionary(forKey: Keys.monthlyEntries) as? [String: Int] ?? [:]
        return monthlyEntries[monthKey] ?? 0
    }
    
    // MARK: - Helper Methods
    
    private func calculateCurrentStreak(from entries: [JournalEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedEntries = entries.sorted { $0.date > $1.date } // Most recent first
        
        var streak = 0
        var currentDate = today
        
        // Check if there's an entry for today or yesterday to start the streak
        let hasToday = sortedEntries.contains { calendar.isDate($0.date, inSameDayAs: today) }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let hasYesterday = sortedEntries.contains { calendar.isDate($0.date, inSameDayAs: yesterday) }
        
        if hasToday {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: today)!
        } else if hasYesterday {
            streak = 1
            currentDate = calendar.date(byAdding: .day, value: -2, to: today)!
        } else {
            return 0
        }
        
        // Count consecutive days backwards
        while let entry = sortedEntries.first(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return hasToday ? streak : streak
    }
    
    private func calculateMonthlyEntries(from entries: [JournalEntry]) -> [String: Int] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        var monthlyEntries: [String: Int] = [:]
        
        for entry in entries {
            let monthKey = formatter.string(from: entry.date)
            monthlyEntries[monthKey, default: 0] += 1
        }
        
        return monthlyEntries
    }
}

// MARK: - Configuration Helper

extension SharedDataManager {
    /// Call this to verify app group is properly configured
    func verifyAppGroupConfiguration() -> Bool {
        guard let sharedDefaults = sharedDefaults else {
            print("❌ App Group '\(appGroupIdentifier)' is not configured properly")
            print("📝 To fix this:")
            print("   1. In Xcode, select your main app target")
            print("   2. Go to Signing & Capabilities")
            print("   3. Add 'App Groups' capability")
            print("   4. Add app group: \(appGroupIdentifier)")
            print("   5. Repeat for the widget target")
            return false
        }
        
        // Test write/read
        let testKey = "app_group_test"
        let testValue = "test_\(Date().timeIntervalSince1970)"
        
        sharedDefaults.set(testValue, forKey: testKey)
        let readValue = sharedDefaults.string(forKey: testKey)
        sharedDefaults.removeObject(forKey: testKey)
        
        let isWorking = readValue == testValue
        print(isWorking ? "✅ App Group configuration verified" : "❌ App Group read/write test failed")
        return isWorking
    }
}