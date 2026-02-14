import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var repository: ExpenseRepository
    
    // State
    @State private var amountString = "0"
    @State private var selectedDate = Date()
    @State private var note = ""
    @State private var selectedCategory = "Food"
    
    // Pickers
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    
    let categories: [(name: String, icon: String, color: Color)] = [
        ("Food", "fork.knife", .orange),
        ("Transport", "car.fill", .blue),
        ("Shopping", "cart.fill", .purple),
        ("Entertainment", "tv.fill", .pink),
        ("Health", "heart.fill", .red),
        ("Bills", "doc.text.fill", .yellow),
        ("Other", "ellipsis.circle.fill", .gray)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Top Pills (Date & Time)
                HStack(spacing: 10) {
                    Button(action: { showDatePicker.toggle() }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text(formatDate(selectedDate))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    
                    Button(action: { showTimePicker.toggle() }) {
                        HStack {
                            Image(systemName: "clock")
                            Text(formatTime(selectedDate))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // Category Name
                Text(selectedCategory.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(2)
                
                // Amount Display
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("₹")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(.gray)
                    
                    Text(amountString)
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                // Category Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(categories, id: \.name) { cat in
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(selectedCategory == cat.name ? cat.color.opacity(0.2) : Color(.systemGray6))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: cat.icon)
                                        .font(.title2)
                                        .foregroundColor(selectedCategory == cat.name ? cat.color : .gray)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(selectedCategory == cat.name ? cat.color : Color.clear, lineWidth: 2)
                                )
                                
                                Text(cat.name)
                                    .font(.caption)
                                    .foregroundColor(selectedCategory == cat.name ? .primary : .secondary)
                            }
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    selectedCategory = cat.name
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
                
                // Note Input
                TextField("Add note...", text: $note)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                Spacer()
                
                // Numeric Keypad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        Button(action: { appendNumber("\(number)") }) {
                            Text("\(number)")
                                .font(.title)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: { appendNumber(".") }) {
                        Text(".")
                            .font(.title)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { appendNumber("0") }) {
                        Text("0")
                            .font(.title)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { removeLastDigit() }) {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Add Button
                Button(action: saveExpense) {
                    Text("Add Expense")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(amountString == "0" ? Color.gray : Color.black)
                        .cornerRadius(30)
                }
                .disabled(amountString == "0")
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTimePicker) {
            DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .presentationDetents([.height(250)])
        }
        .navigationBarHidden(true)
    }
    
    // Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func appendNumber(_ number: String) {
        if amountString == "0" && number != "." {
            amountString = number
        } else {
            if number == "." && amountString.contains(".") { return }
            if amountString.count < 10 {
                amountString += number
            }
        }
    }
    
    private func removeLastDigit() {
        if amountString.count > 1 {
            amountString.removeLast()
        } else {
            amountString = "0"
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amountString), amountValue > 0 else { return }
        
        // Use 'note' as the title, as per data model mapping
        let titleToUse = note.isEmpty ? selectedCategory : note
        
        let expense = Expense(id: nil, title: titleToUse, amount: amountValue, date: selectedDate, category: selectedCategory)
        repository.addExpense(expense)
        dismiss()
    }
}

#Preview {
    AddExpenseView()
        .environmentObject(ExpenseRepository(userId: "preview_user"))
}
