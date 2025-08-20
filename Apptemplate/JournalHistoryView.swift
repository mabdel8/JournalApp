//
//  JournalHistoryView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI
import SwiftData

struct JournalHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeManager: StoreManager
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    @State private var selectedEntry: JournalEntry?
    @State private var showingEditEntry = false
    @State private var searchText = ""
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return allEntries
        } else {
            return allEntries.filter { entry in
                entry.question.localizedCaseInsensitiveContains(searchText) ||
                entry.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            paperColor
                .ignoresSafeArea()
            
            VStack {
                // Search bar
                searchBar
                
                if filteredEntries.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Journal entries list
                    entriesList
                }
            }
        }
        .navigationTitle("Journal History")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedEntry) { entry in
            EditEntryView(entry: entry)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(accentColor)
                .font(.system(size: 16))
            
            TextField("Search entries...", text: $searchText)
                .font(.custom("Noteworthy-Light", size: 16))
                .foregroundColor(inkColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
        )
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(accentColor.opacity(0.5))
            
            Text("No Journal Entries")
                .font(.custom("Noteworthy-Bold", size: 24))
                .foregroundColor(inkColor)
            
            Text(searchText.isEmpty ? 
                 "Start writing your first journal entry!" : 
                 "No entries match your search.")
                .font(.custom("Noteworthy-Light", size: 16))
                .foregroundColor(inkColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedEntries, id: \.key) { dateGroup in
                    VStack(alignment: .leading, spacing: 12) {
                        // Date header
                        Text(dateGroup.key, style: .date)
                            .font(.custom("Noteworthy-Bold", size: 18))
                            .foregroundColor(accentColor)
                            .padding(.horizontal)
                        
                        // Entries for this date
                        ForEach(dateGroup.value, id: \.id) { entry in
                            EntryCard(entry: entry) {
                                selectedEntry = entry
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
    
    private var groupedEntries: [(key: Date, value: [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
}

struct EntryCard: View {
    let entry: JournalEntry
    let action: () -> Void
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Question
                Text(entry.question)
                    .font(.custom("Noteworthy-Bold", size: 16))
                    .foregroundColor(inkColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Answer preview
                Text(entry.answer)
                    .font(.custom("Noteworthy-Light", size: 14))
                    .foregroundColor(inkColor.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                // Metadata
                HStack {
                    Text("Day \(entry.dayNumber)")
                        .font(.custom("Noteworthy-Light", size: 12))
                        .foregroundColor(accentColor)
                    
                    if entry.cycleNumber > 1 {
                        Text("• Cycle \(entry.cycleNumber)")
                            .font(.custom("Noteworthy-Light", size: 12))
                            .foregroundColor(accentColor)
                    }
                    
                    Spacer()
                    
                    Text(entry.date, format: .dateTime.hour().minute())
                        .font(.custom("Noteworthy-Light", size: 12))
                        .foregroundColor(inkColor.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.6))
                    .shadow(color: inkColor.opacity(0.1), radius: 2, x: 1, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let entry: JournalEntry
    @State private var editedAnswer: String
    @State private var showingDeleteConfirmation = false
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    init(entry: JournalEntry) {
        self.entry = entry
        self._editedAnswer = State(initialValue: entry.answer)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Entry info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                                .font(.custom("Noteworthy-Light", size: 16))
                                .foregroundColor(inkColor.opacity(0.6))
                            
                            HStack {
                                Text("Day \(entry.dayNumber)")
                                    .font(.custom("Noteworthy-Light", size: 14))
                                    .foregroundColor(accentColor)
                                
                                if entry.cycleNumber > 1 {
                                    Text("• Cycle \(entry.cycleNumber)")
                                        .font(.custom("Noteworthy-Light", size: 14))
                                        .foregroundColor(accentColor)
                                }
                            }
                        }
                        
                        // Question
                        Text(entry.question)
                            .font(.custom("Noteworthy-Bold", size: 20))
                            .foregroundColor(inkColor)
                        
                        // Editable answer
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your answer:")
                                .font(.custom("Noteworthy-Light", size: 14))
                                .foregroundColor(inkColor.opacity(0.6))
                            
                            TextEditor(text: $editedAnswer)
                                .font(.custom("Noteworthy-Light", size: 18))
                                .foregroundColor(inkColor)
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(8)
                                .frame(minHeight: 200)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(inkColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        
                        Button("Save") {
                            saveChanges()
                        }
                        .foregroundColor(accentColor)
                        .fontWeight(.medium)
                        .disabled(editedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteEntry()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
            }
        }
    }
    
    private func saveChanges() {
        entry.answer = editedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
    
    private func deleteEntry() {
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
}