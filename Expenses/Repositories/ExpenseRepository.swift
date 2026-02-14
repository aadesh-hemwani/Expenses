import Foundation
import FirebaseFirestore
import Combine

struct MonthlyStats: Identifiable, Codable {
    @DocumentID var id: String? // "yyyy-MM"
    var total: Double
}

class ExpenseRepository: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var currentMonthTotalAmount: Double = 0.0
    @Published var allStats: [MonthlyStats] = []
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var statsListenerRegistration: ListenerRegistration?
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
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
        } catch {
            print("Error adding expense: \(error)")
        }
    }
    
    func deleteExpense(at offsets: IndexSet) {
        offsets.map { expenses[$0] }.forEach { expense in
            delete(expense: expense)
        }
    }
    
    func delete(expense: Expense) {
        guard let expenseID = expense.id else { return }
        db.collection("users").document(userId).collection("expenses").document(expenseID).delete() { error in
            if let error = error {
                print("Error removing document: \(error)")
            }
        }
    }
    
    deinit {
        listenerRegistration?.remove()
        statsListenerRegistration?.remove()
    }
}
