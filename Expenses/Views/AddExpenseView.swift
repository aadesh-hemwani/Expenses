import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var repository: ExpenseRepository
    
    // State
    @State private var amountString = ""
    @State private var selectedDate = Date()
    @State private var note = ""
    @State private var selectedCategory = "Food"
    
    enum Field: Hashable {
        case amount
        case note
    }
    @FocusState private var focusedField: Field?
    
    // Monochromatic SF Symbols for native feel
    // Monochromatic SF Symbols for native feel
    let categories: [(name: String, icon: String, color: Color)] = [
        ("Food", "fork.knife", Theme.CategoryColors.food),
        ("Transport", "car", Theme.CategoryColors.transport),
        ("Shopping", "cart", Theme.CategoryColors.shopping),
        ("Entertainment", "tv", Theme.CategoryColors.entertainment),
        ("Health", "heart", Theme.CategoryColors.health),
        ("Bills", "creditcard", Theme.CategoryColors.bills),
        ("Misc", "square.grid.2x2", Theme.CategoryColors.misc)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Large Centered Amount
                Section {
                    HStack(spacing: 4) {
                        Spacer()
                        Text("₹")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        
                        TextField("0", text: $amountString)
                            .font(.system(size: 52, weight: .semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                            .fixedSize()
                            .onChange(of: amountString) { oldValue, newValue in
                                // Filter valid characters
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
                    .padding(.vertical, 1)
                    .listRowBackground(Color.clear)
                }
                
                // Section 2: Note
                Section {
                    TextField("Add note", text: $note)
                        .focused($focusedField, equals: .note)
                } header: {
                    Text("Note")
                }
                
                // Section 3: Category
                Section {
                    ForEach(categories, id: \.name) { cat in
                        Button {
                            withAnimation {
                                selectedCategory = cat.name
                            }
                        } label: {
                            HStack {
                                Image(systemName: cat.icon)
                                    .symbolRenderingMode(.monochrome)
                                    .foregroundStyle(cat.color) // Specific color per category
                                
                                Text(cat.name)
                                    .foregroundStyle(Color.primary)
                                
                                Spacer()
                                
                                if selectedCategory == cat.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.getAccentColor())
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .tint(Color.primary)
                    }
                } header: {
                    Text("Category")
                }
                
                // Section 4: Date
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
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
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                focusedField = .amount
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    // Helpers
    private func saveExpense() {
        guard let amountValue = Double(amountString), amountValue > 0 else { return }
        
        let titleToUse = note.isEmpty ? selectedCategory : note
        
        let expense = Expense(id: nil, title: titleToUse, amount: amountValue, date: selectedDate, category: selectedCategory)
        repository.addExpense(expense)
        
        // Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        dismiss()
    }
}

#Preview {
    AddExpenseView()
        .environmentObject(ExpenseRepository(userId: "preview_user"))
}
