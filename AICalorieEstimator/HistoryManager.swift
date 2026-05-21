import Foundation

struct DailyRecord: Codable, Identifiable {
    var id: String { dateString }
    let dateString: String
    var totalCalories: Int

    var date: Date {
        HistoryManager.dateFormatter.date(from: dateString) ?? Date()
    }
}

struct MealLogEntry: Codable, Equatable, Identifiable {
    let id: UUID
    let dateString: String
    let calories: Int
    let foodSummary: String
    let createdAt: Date

    var date: Date {
        HistoryManager.dateFormatter.date(from: dateString) ?? createdAt
    }
}

// [Fix] 改為 actor 以確保線程安全 (Thread Safety)
actor HistoryManager {
    static let shared = HistoryManager()
    static let historyRetentionYears = 3
    private let defaults: UserDefaults
    private let key: String
    private let mealKey: String
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        defaults: UserDefaults = .standard,
        key: String = "user_diet_history_v1",
        mealKey: String = "user_meal_entries_v1",
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.key = key
        self.mealKey = mealKey
        self.calendar = calendar
        self.now = now
    }

    // [Fix] 靜態 Formatter，提升效能
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian) // 固定曆法避免 Bug
        return formatter
    }()

    // 因為是 actor，外部呼叫時需要用 'await'
    func addCalories(amount: Int) {
        addCalories(amount: amount, on: now())
    }

    func addMeal(calories: Int, foodSummary: String) -> MealLogEntry {
        let amount = max(0, calories)
        let createdAt = now()
        let dateString = HistoryManager.dateFormatter.string(from: createdAt)
        let entry = MealLogEntry(
            id: UUID(),
            dateString: dateString,
            calories: amount,
            foodSummary: foodSummary,
            createdAt: createdAt
        )

        var meals = pruneMealEntries(loadMealEntries())
        meals.append(entry)
        saveMealEntries(pruneMealEntries(meals))
        addCalories(amount: amount, on: createdAt)
        return entry
    }

    func deleteMeal(id: UUID) -> Bool {
        var meals = loadMealEntries()
        guard let index = meals.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let entry = meals.remove(at: index)
        saveMealEntries(meals)
        subtractCalories(amount: entry.calories, dateString: entry.dateString)
        return true
    }

    func getRecentMeals(limit: Int = 50) -> [MealLogEntry] {
        Array(pruneMealEntries(loadMealEntries()).sorted { $0.createdAt > $1.createdAt }.prefix(max(0, limit)))
    }

    private func addCalories(amount: Int, on date: Date) {
        var history = pruneDailyRecords(loadHistory())
        let amount = max(0, amount)
        let dateString = HistoryManager.dateFormatter.string(from: date)

        if let index = history.firstIndex(where: { $0.dateString == dateString }) {
            history[index].totalCalories += amount
        } else {
            history.append(DailyRecord(dateString: dateString, totalCalories: amount))
        }

        save(pruneDailyRecords(history))
    }

    private func subtractCalories(amount: Int, dateString: String) {
        var history = loadHistory()
        guard let index = history.firstIndex(where: { $0.dateString == dateString }) else {
            return
        }

        history[index].totalCalories = max(0, history[index].totalCalories - max(0, amount))
        if history[index].totalCalories == 0 {
            history.remove(at: index)
        }
        save(history)
    }

    func getWeeklyRecords() -> [DailyRecord] {
        let history = pruneDailyRecords(loadHistory())
        var result: [DailyRecord] = []

        // 補齊過去 7 天的數據 (包含今天)
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now()) {
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
        guard let data = defaults.data(forKey: key),
              let history = try? JSONDecoder().decode([DailyRecord].self, from: data) else {
            return []
        }
        return history
    }

    private func save(_ history: [DailyRecord]) {
        let retainedHistory = pruneDailyRecords(history)
        if let data = try? JSONEncoder().encode(retainedHistory) {
            defaults.set(data, forKey: key)
        }
    }

    private func loadMealEntries() -> [MealLogEntry] {
        guard let data = defaults.data(forKey: mealKey),
              let entries = try? JSONDecoder().decode([MealLogEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func saveMealEntries(_ entries: [MealLogEntry]) {
        let retainedEntries = pruneMealEntries(entries)
        if let data = try? JSONEncoder().encode(retainedEntries) {
            defaults.set(data, forKey: mealKey)
        }
    }

    private func pruneDailyRecords(_ records: [DailyRecord]) -> [DailyRecord] {
        records
            .filter { record in
                guard let date = date(from: record.dateString) else {
                    return false
                }
                return date >= retentionStartDate
            }
            .sorted { $0.dateString > $1.dateString }
    }

    private func pruneMealEntries(_ entries: [MealLogEntry]) -> [MealLogEntry] {
        entries
            .filter { $0.createdAt >= retentionStartDate }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var retentionStartDate: Date {
        let today = calendar.startOfDay(for: now())
        return calendar.date(byAdding: .year, value: -Self.historyRetentionYears, to: today) ?? today
    }

    private func date(from dateString: String) -> Date? {
        let parts = dateString.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return calendar.date(from: components)
    }
}
