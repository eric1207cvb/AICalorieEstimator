import Foundation

struct DailyRecord: Codable, Identifiable {
    var id: String { dateString }
    let dateString: String
    var totalCalories: Int
    
    var date: Date {
        HistoryManager.dateFormatter.date(from: dateString) ?? Date()
    }
}

// [Fix] 改為 actor 以確保線程安全 (Thread Safety)
actor HistoryManager {
    static let shared = HistoryManager()
    private let key = "user_diet_history_v1"
    
    // [Fix] 靜態 Formatter，提升效能
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian) // 固定曆法避免 Bug
        return formatter
    }()
    
    // 因為是 actor，外部呼叫時需要用 'await'
    func addCalories(amount: Int) {
        var history = loadHistory()
        let today = Date()
        let dateString = HistoryManager.dateFormatter.string(from: today)
        
        if let index = history.firstIndex(where: { $0.dateString == dateString }) {
            history[index].totalCalories += amount
        } else {
            history.append(DailyRecord(dateString: dateString, totalCalories: amount))
        }
        
        // 排序並只保留最近 7 天
        let sorted = history.sorted { $0.dateString > $1.dateString }
        let recent = Array(sorted.prefix(7))
        
        save(recent)
    }
    
    func getWeeklyRecords() -> [DailyRecord] {
        let history = loadHistory()
        var result: [DailyRecord] = []
        let calendar = Calendar.current
        
        // 補齊過去 7 天的數據 (包含今天)
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dateString = HistoryManager.dateFormatter.string(from: date)
                if let record = history.first(where: { $0.dateString == dateString }) {
                    result.append(record)
                } else {
                    result.append(DailyRecord(dateString: dateString, totalCalories: 0))
                }
            }
        }
        return result.reversed()
    }
    
    private func loadHistory() -> [DailyRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let history = try? JSONDecoder().decode([DailyRecord].self, from: data) else {
            return []
        }
        return history
    }
    
    private func save(_ history: [DailyRecord]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
