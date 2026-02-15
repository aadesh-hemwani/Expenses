import SwiftUI
import CoreHaptics

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var repository: ExpenseRepository
    @Binding var sheetDetent: PresentationDetent
    
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
    
    // Init with default binding for previews
    init(sheetDetent: Binding<PresentationDetent> = .constant(.medium)) {
        _sheetDetent = sheetDetent
    }
    
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
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("₹")
                                .font(.system(size: 52, weight: .semibold, design: .rounded))
                                .foregroundStyle(.tertiary)
                            
                            TextField("0", text: $amountString)
                                .font(.system(size: 52, weight: .semibold, design: .rounded))
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
                        }
                        .scaleEffect(amountString.isEmpty ? 1.0 : 1.05)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: amountString)
                        
                        Text("Enter amount")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }
                
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
                
                // Section 3: Category
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.name) { cat in
                                CategoryPill(
                                    name: cat.name,
                                    icon: cat.icon,
                                    isSelected: selectedCategory == cat.name
                                ) {
                                    // Haptic Feedback
                                    if selectedCategory != cat.name {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                    }
                                    
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        selectedCategory = cat.name
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets()) // Full width needed for horizontal scroll
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Category")
                        .padding(.leading, 20) // Re-align header since insets are cleared
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
        
        // Success Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let expense = Expense(id: nil, title: titleToUse, amount: amountValue, date: selectedDate, category: selectedCategory)
        repository.addExpense(expense)
        
        dismiss()
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
    let isSelected: Bool
    let action: () -> Void
    
    // Local state to track animation trigger purely based on selection becoming true
    @State private var animateTrigger = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .symbolEffect(.bounce, value: animateTrigger)
                Text(name)
            }
            .font(.system(size: 15, weight: .medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? AnyShapeStyle(Theme.getAccentColor()) : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? Theme.getAccentColor().opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onChange(of: isSelected) { oldValue, newValue in
            if newValue {
                animateTrigger.toggle()
            }
        }
    }
}
