import Foundation
import FirebaseFirestore
import FirebaseCore
import Combine

struct MonthlyStats: Identifiable, Codable {
    @DocumentID var id: String? // "yyyy-MM"
    var total: Double
}

class ExpenseRepository: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var currentMonthTotalAmount: Double = 0.0
    @Published var allStats: [MonthlyStats] = []
    @Published var errorMessage: String?
    
    private lazy var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var statsListenerRegistration: ListenerRegistration?
    private let userId: String
    
    // Cache: "yyyy-MM" -> [Expense]
    private var monthlyCache: [String: [Expense]] = [:]
    
    init(userId: String) {
        self.userId = userId
        
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || FirebaseApp.app() == nil {
            self.expenses = [
                Expense.example,
                Expense(id: "2", title: "Uber", amount: 250.0, date: Date().addingTimeInterval(-86400), category: "Transport", type: .oneOff),
                Expense(id: "3", title: "Groceries", amount: 1200.0, date: Date().addingTimeInterval(-172800), category: "Shopping", type: .regular)
            ]
            calculateCurrentMonthTotal()
            return
        }
        
        fetchExpenses()
        fetchAllStats()
    }
    
    func fetchExpenses() {
        listenerRegistration = db.collection("users").document(userId).collection("expenses")
            .order(by: "date", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                }
                
                self.expenses = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Expense.self)
                } ?? []
                
                // Recalculate total whenever expenses change
                self.calculateCurrentMonthTotal()
            }
    }
    
    func calculateCurrentMonthTotal() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthExpenses = expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate(expense.date, equalTo: now, toGranularity: .year)
        }
        
        
        self.currentMonthTotalAmount = currentMonthExpenses.reduce(0) { $0 + $1.amount }
        self.calculateMonthOverMonthChange()
        
        // Update Widget
        WidgetDataManager.shared.save(expenses: expenses)
    }
    
    func fetchAllStats() {
        print("Fetching stats for user: \(userId)")
        db.collection("users").document(userId).collection("stats")
            //.order(by: FieldPath.documentID(), descending: true) // Temporarily remove ordering
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting stats: \(error)")
                    return
                }
                
                print("Stats documents count: \(querySnapshot?.documents.count ?? 0)")
                querySnapshot?.documents.forEach { print("Stats doc: \($0.documentID) -> \($0.data())") }
                
                self.allStats = querySnapshot?.documents.map { document in
                    let data = document.data()
                    var total: Double = 0.0
                    
                    if let t = data["total"] as? Double {
                        total = t
                    } else if let t = data["total"] as? Int {
                        total = Double(t)
                    } else if let tString = data["total"] as? String, let t = Double(tString) {
                         total = t
                    }
                    
                    // Default to 0 if missing to verify document existence
                    return MonthlyStats(id: document.documentID, total: total)
                } ?? []
                
                // Sort manually after fetching
                self.allStats.sort { ($0.id ?? "") > ($1.id ?? "") }
            }
    }
    
    func addExpense(_ expense: Expense) {
        do {
            let _ = try db.collection("users").document(userId).collection("expenses").addDocument(from: expense)
            invalidateCache(for: expense.date)
        } catch {
            print("Error adding expense: \(error)")
            self.errorMessage = "Failed to add expense: \(error.localizedDescription)"
        }
        }
    
    func update(expense: Expense) {
        guard let expenseID = expense.id else { return }
        
        do {
            try db.collection("users").document(userId).collection("expenses").document(expenseID).setData(from: expense)
            invalidateCache(for: expense.date)
        } catch {
            print("Error updating expense: \(error)")
            self.errorMessage = "Failed to update expense: \(error.localizedDescription)"
        }
    }
    
    func deleteExpense(at offsets: IndexSet) {
        offsets.map { expenses[$0] }.forEach { expense in
            delete(expense: expense)
        }
    }
    
    func delete(expense: Expense) {
        guard let expenseID = expense.id else { return }
        db.collection("users").document(userId).collection("expenses").document(expenseID).delete() { [weak self] error in
            if let error = error {
                print("Error removing document: \(error)")
                self?.errorMessage = "Failed to delete expense: \(error.localizedDescription)"
            } else {
                self?.invalidateCache(for: expense.date)
            }
        }
    }
    
    private func invalidateCache(for date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthID = formatter.string(from: date)
        monthlyCache.removeValue(forKey: monthID)
    }
    
    func fetchExpenses(forMonth monthID: String, completion: @escaping ([Expense]) -> Void) {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || FirebaseApp.app() == nil {
            print("Preview Mode: Returning mock data for \(monthID)")
            // Return some mock data for preview
            let mockExpenses = (0..<5).map { i in
                Expense(id: "\(i)", title: "Expense \(i)", amount: Double(i * 100 + 50), date: Date(), category: ["Food", "Transport"].randomElement() ?? "Food", type: .oneOff)
            }
            completion(mockExpenses)
            return
        }
        
        // Check cache first
        if let cachedExpenses = monthlyCache[monthID] {
            print("Fetching from cache for \(monthID)")
            completion(cachedExpenses)
            return
        }
        
        print("Fetching from remote for \(monthID)")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: monthID) else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: startOfMonth) else {
            completion([])
            return
        }
        
        db.collection("users").document(userId).collection("expenses")
            .whereField("date", isGreaterThanOrEqualTo: startOfMonth)
            .whereField("date", isLessThanOrEqualTo: endOfMonth)
            .order(by: "date", descending: true)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents for month: \(error)")
                    self.errorMessage = "Failed to load expenses: \(error.localizedDescription)"
                    completion([])
                    return
                }
                
                let expenses = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Expense.self)
                } ?? []
                
                // Update cache
                self.monthlyCache[monthID] = expenses
                completion(expenses)
            }
    }
    
    deinit {
        listenerRegistration?.remove()
        statsListenerRegistration?.remove()
    }
    @Published var monthOverMonthPercentage: Double?
    
    // ... (existing properties)

    // ... (inside fetchExpenses/calculateCurrentMonthTotal or new method)
    func calculateMonthOverMonthChange() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || FirebaseApp.app() == nil {
            self.monthOverMonthPercentage = 15.0 // Mock data
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.day, from: now)
        
        // Get last month's ID
        guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let lastMonthID = formatter.string(from: lastMonthDate)
        
        // Fetch last month's expenses (using existing fetch logic or cache)
        fetchExpenses(forMonth: lastMonthID) { [weak self] lastMonthExpenses in
            guard let self = self else { return }
            
            // Filter for expenses up to the same day
            let partialLastMonthExpenses = lastMonthExpenses.filter { expense in
                let day = calendar.component(.day, from: expense.date)
                return day <= currentDay
            }
            
            let lastMonthPartialTotal = partialLastMonthExpenses.reduce(0) { $0 + $1.amount }
            
            if lastMonthPartialTotal > 0 {
                let diff = self.currentMonthTotalAmount - lastMonthPartialTotal
                self.monthOverMonthPercentage = (diff / lastMonthPartialTotal) * 100
            } else {
                self.monthOverMonthPercentage = nil // Can't compare with 0
            }
        }
    }
}
