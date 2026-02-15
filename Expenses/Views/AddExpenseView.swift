import SwiftUI
import CoreHaptics

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var repository: ExpenseRepository
    @Binding var sheetDetent: PresentationDetent
    var expenseToEdit: Expense?
    
    // State
    @State private var amountString = ""
    @State private var selectedDate = Date()
    @State private var note = ""
    @State private var selectedCategory = "Food"
    @State private var selectedType: Expense.ExpenseType = .regular
    @State private var isEditing: Bool = true
    
    enum Field: Hashable {
        case amount
        case note
    }
    @FocusState private var focusedField: Field?
    
    // Init with default binding for previews
    init(sheetDetent: Binding<PresentationDetent> = .constant(.medium), expenseToEdit: Expense? = nil) {
        _sheetDetent = sheetDetent
        self.expenseToEdit = expenseToEdit
        
        _isEditing = State(initialValue: expenseToEdit == nil)
        
        if let expense = expenseToEdit {
            _amountString = State(initialValue: String(format: "%.0f", expense.amount)) // Remove decimals if .00? Or just use description
            _selectedDate = State(initialValue: expense.date)
            _note = State(initialValue: expense.title)
            _selectedCategory = State(initialValue: expense.category)
            _selectedType = State(initialValue: expense.type)
        }
    }
    
    // Grid Columns
    let columns = [
        GridItem(.adaptive(minimum: 70), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // ... (Section 1 & 2 unchanged)
                // Section 1: Large Centered Amount
                Section {
                    VStack(spacing: 0) {
                        Text("Amount")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "indianrupeesign")
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .foregroundStyle(.tertiary)
                            
                            if isEditing {
                                TextField("0", text: $amountString)
                                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
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
                                        
                                        // Haptic Feedback for typing
                                        if oldValue != amountString {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                        }
                                    }
                                    .onChange(of: focusedField) { oldValue, newValue in
                                        if newValue == .amount {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                sheetDetent = .large
                                            }
                                        }
                                    }
                            } else {
                                Text(amountString.isEmpty ? "0" : (Double(amountString)?.formatted(.number.precision(.fractionLength(0...2))) ?? amountString))
                                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .scaleEffect(amountString.isEmpty ? 1.0 : 1.05)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: amountString)
                        .offset(x: -15) // Balance visual center for currency symbol
                    
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                }
                .disabled(!isEditing)
                
                // Section 2: Note
                Section {
                    HStack {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                        
                        TextField("Add a note", text: $note)
                            .focused($focusedField, equals: .note)
                    }
                } header: {
                    Text("Note")
                }
                .disabled(!isEditing)

                // Section 3: Category
                Section {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 30) {
                                ForEach(Expense.allCategories, id: \.name) { cat in
                                    CategoryPill(
                                        name: cat.name,
                                        icon: cat.icon,
                                        color: cat.color,
                                        isSelected: selectedCategory == cat.name
                                    ) {
                                        // Haptic Feedback
                                        if selectedCategory != cat.name {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                        }
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            selectedCategory = cat.name
                                            proxy.scrollTo(cat.name, anchor: .center)
                                        }
                                    }
                                    .id(cat.name) // Important for ScrollViewReader
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                        .onAppear {
                            // Scroll to selected category on load
                            withAnimation {
                                proxy.scrollTo(selectedCategory, anchor: .center)
                            }
                        }
                        .onChange(of: selectedCategory) { newValue in
                            withAnimation {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets()) // Full width to edges
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Category")
                }
                .disabled(!isEditing)
                
                // Section 4: Type & Date
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(Expense.ExpenseType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Details")
                }
                .disabled(!isEditing)
            }
            // .disabled(!isEditing) // Removed from here to allow scrolling
            .navigationTitle(expenseToEdit == nil ? "New Expense" : (isEditing ? "Edit Expense" : "Expense Details"))
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Close") {
                        if isEditing && expenseToEdit != nil {
                            withAnimation {
                                resetState()
                            }
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button(expenseToEdit != nil ? "Update" : "Save") {
                            saveExpense()
                        }
                        .disabled(Double(amountString) == nil || Double(amountString) == 0)
                        .bold()
                    } else {
                        Button("Edit") {
                            withAnimation {
                                isEditing = true
                                focusedField = .amount
                            }
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                if isEditing {
                    focusedField = .amount
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    // Helpers
    private func saveExpense() {
        guard let amountValue = Double(amountString), amountValue > 0 else { return }
        
        let titleToUse = note.isEmpty ? selectedCategory : note
        
        // Success Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        if let existingExpense = expenseToEdit {
             var updatedExpense = existingExpense
             updatedExpense.title = titleToUse
             updatedExpense.amount = amountValue
             updatedExpense.date = selectedDate
             updatedExpense.category = selectedCategory
             updatedExpense.type = selectedType
             
             repository.update(expense: updatedExpense)
        } else {
             let expense = Expense(id: nil, title: titleToUse, amount: amountValue, date: selectedDate, category: selectedCategory, type: selectedType)
             repository.addExpense(expense)
        }
        
        dismiss()
    }
    
    private func resetState() {
        guard let expense = expenseToEdit else { return }
        amountString = String(format: "%.0f", expense.amount)
        selectedDate = expense.date
        note = expense.title
        selectedCategory = expense.category
        selectedType = expense.type
        isEditing = false
        focusedField = nil
    }
}

#Preview {
    AddExpenseView()
        .environmentObject(ExpenseRepository(userId: "preview_user"))
}

// Extracted View for independent animation state
struct CategoryPill: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    // Local state to track animation trigger purely based on selection becoming true
    @State private var animateTrigger = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? color : Color.clear)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : color.opacity(0.4))
                        .symbolEffect(.bounce, value: animateTrigger)
                }
                
                Text(name)
                    .font(.system(size: 10))
                    .fontWeight(.regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onChange(of: isSelected) { oldValue, newValue in
            if newValue {
                animateTrigger.toggle()
            }
        }
    }
}
