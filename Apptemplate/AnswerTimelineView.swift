//
//  AnswerTimelineView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/20/25.
//

import SwiftUI
import SwiftData

struct AnswerTimelineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeManager: StoreManager
    let question: Question
    
    @State private var entries: [JournalEntry] = []
    @State private var expandedEntries: Set<UUID> = []
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                if entries.isEmpty {
                    emptyStateView
                } else {
                    timelineView
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadEntries()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(accentColor.opacity(0.5))
            
            Text("No Answers Yet")
                .font(.custom("Noteworthy-Bold", size: 24))
                .foregroundColor(inkColor)
            
            Text("Start journaling to see your answers appear here over time.")
                .font(.custom("Noteworthy-Light", size: 16))
                .foregroundColor(inkColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var timelineView: some View {
        VStack(spacing: 0) {
            // Question header
            questionHeader
            
            // Timeline entries
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(entries, id: \.id) { entry in
                        TimelineEntryView(
                            entry: entry,
                            isExpanded: expandedEntries.contains(entry.id),
                            onToggleExpansion: {
                                toggleExpansion(for: entry.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Day \(question.id)")
                    .font(.custom("Noteworthy-Bold", size: 18))
                    .foregroundColor(accentColor)
                
                Spacer()
                
                Text("\(entries.count) answer\(entries.count == 1 ? "" : "s")")
                    .font(.custom("Noteworthy-Light", size: 14))
                    .foregroundColor(inkColor.opacity(0.6))
            }
            
            Text(question.text)
                .font(.custom("Noteworthy-Light", size: 18))
                .foregroundColor(inkColor)
                .multilineTextAlignment(.leading)
            
            Text(question.category.capitalized)
                .font(.custom("Noteworthy-Light", size: 12))
                .foregroundColor(accentColor.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(accentColor.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.7))
                .shadow(color: inkColor.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private func loadEntries() {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.questionId == question.id
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            entries = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading entries for question: \(error)")
            entries = []
        }
    }
    
    private func toggleExpansion(for entryId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedEntries.contains(entryId) {
                expandedEntries.remove(entryId)
            } else {
                expandedEntries.insert(entryId)
            }
        }
    }
}

struct TimelineEntryView: View {
    let entry: JournalEntry
    let isExpanded: Bool
    let onToggleExpansion: () -> Void
    
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    private let characterLimit = 150
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 12)
            
            // Entry content
            VStack(alignment: .leading, spacing: 12) {
                // Header with date and cycle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                            .font(.custom("Noteworthy-Bold", size: 16))
                            .foregroundColor(inkColor)
                        
                        Text(entry.date, format: .dateTime.hour().minute())
                            .font(.custom("Noteworthy-Light", size: 12))
                            .foregroundColor(inkColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Cycle badge
                    HStack(spacing: 4) {
                        Image(systemName: "repeat.circle")
                            .font(.system(size: 10))
                        Text("Cycle \(entry.cycleNumber)")
                            .font(.custom("Noteworthy-Light", size: 11))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.7))
                    .cornerRadius(8)
                }
                
                // Answer text
                VStack(alignment: .leading, spacing: 8) {
                    let shouldTruncate = entry.answer.count > characterLimit && !isExpanded
                    
                    Text(shouldTruncate ? String(entry.answer.prefix(characterLimit)) + "..." : entry.answer)
                        .font(.custom("Noteworthy-Light", size: 16))
                        .foregroundColor(inkColor.opacity(0.8))
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                    
                    // Expand/collapse button
                    if entry.answer.count > characterLimit {
                        Button(action: onToggleExpansion) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "See less" : "See more")
                                    .font(.custom("Noteworthy-Light", size: 14))
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Time ago indicator
                HStack {
                    Spacer()
                    Text(timeAgoString(from: entry.date))
                        .font(.custom("Noteworthy-Light", size: 11))
                        .foregroundColor(inkColor.opacity(0.5))
                        .italic()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
                .shadow(color: inkColor.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}