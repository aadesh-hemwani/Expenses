import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var repository: ExpenseRepository
    
    // State
    @State private var amountString = ""
    @State private var selectedDate = Date()
    @State private var note = ""
    @State private var selectedCategory = "Food"
    @FocusState private var isAmountFocused: Bool
    
    let categories: [(name: String, icon: String, color: Color)] = [
        ("Food", "fork.knife", .orange),
        ("Transport", "car.fill", .blue),
        ("Shopping", "cart.fill", .purple),
        ("Entertainment", "tv.fill", .pink),
        ("Health", "heart.fill", .red),
        ("Bills", "doc.text.fill", .yellow),
        ("Misc", "ellipsis.circle.fill", .gray)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // AMOUNT SECTION
                Section {
                    HStack(spacing: 4) {
                        Spacer()
                        Text("₹")
                            // Increased size
                            .font(.system(size: 64, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        TextField("0", text: $amountString)
                            // Increased size
                            .font(.system(size: 64, weight: .semibold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .focused($isAmountFocused)
                            .multilineTextAlignment(.leading)
                            .fixedSize()
                            // Restrict to numbers and one decimal point
                            .onChange(of: amountString) { oldValue, newValue in
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    amountString = filtered
                                }
                                // Ensure only one decimal point
                                if let firstIndex = amountString.firstIndex(of: "."),
                                   let secondIndex = amountString[amountString.index(after: firstIndex)...].firstIndex(of: ".") {
                                    amountString = String(amountString[..<secondIndex])
                                }
                            }
                        Spacer()
                    }
                    .padding(.vertical, 0) // No vertical padding
                    .listRowInsets(EdgeInsets()) // Remove row spacing
                    .listRowBackground(Color.clear)
                }

                // NOTE SECTION
                Section {
                    TextField("Add a note", text: $note)
                } header: {
                    Text("Note")
                }
                
                // CATEGORY SECTION
                Section {
                    ForEach(categories, id: \.name) { cat in
                        Button {
                            withAnimation {
                                selectedCategory = cat.name
                            }
                        } label: {
                            HStack {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 29, height: 29)
                                    .background(cat.color)
                                    .cornerRadius(6)
                                Text(cat.name)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if selectedCategory == cat.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Category")
                }
                
                // DATE & TIME SECTION
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    DatePicker("Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Date & Time")
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(Double(amountString) == nil || Double(amountString) == 0)
                    .bold()
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isAmountFocused = false
                    }
                }
            }
            .onAppear {
                isAmountFocused = true
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // Helpers
    private func saveExpense() {
        guard let amountValue = Double(amountString), amountValue > 0 else { return }
        
        // Use 'note' as the title, as per data model mapping
        let titleToUse = note.isEmpty ? selectedCategory : note
        
        // Ensure date components are preserved/combined correctly if needed, 
        // though typically DatePicker handles this well enough for simple use cases.
        
        let expense = Expense(id: nil, title: titleToUse, amount: amountValue, date: selectedDate, category: selectedCategory)
        repository.addExpense(expense)
        dismiss()
    }
}

#Preview {
    AddExpenseView()
        .environmentObject(ExpenseRepository(userId: "preview_user"))
}
