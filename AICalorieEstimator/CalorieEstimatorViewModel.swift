import Foundation
import SwiftUI
import Combine
import HealthKit
import Vision
import RevenueCat

// MARK: - [Client v9.27] ViewModel (With Gender Sync)
@MainActor
class CalorieEstimatorViewModel: NSObject, ObservableObject, PurchasesDelegate {
    
    // MARK: - UI States
    @Published var viewState: ViewState = .empty
    @Published var selectedImage: Image? = nil
    @Published var serverStatus: ServerStatus = .unknown
    @Published var isAppLoading: Bool = true
    @Published var isCurrentMealLogged: Bool = false
    
    // MARK: - RevenueCat
    @Published var offerings: Offerings?
    @Published var isProUser: Bool = false
    @Published var isShowingPaywall: Bool = false
    @Published var remainingFreeUsage: Int = 5
    
    private let maxFreeUsageCount = 5
    private let usageKey = "user_free_usage_count_v1"
    
    #if DEBUG
    var debugBypassPro: Bool = false { didSet { updateUsageCount() } }
    #endif
    
    // MARK: - User Profile
    @Published var height: Double { didSet { UserDefaults.standard.set(height, forKey: "user_height") } }
    @Published var currentWeight: Double { didSet { UserDefaults.standard.set(currentWeight, forKey: "user_weight") } }
    @Published var targetWeight: Double { didSet { UserDefaults.standard.set(targetWeight, forKey: "user_target_weight") } }
    @Published var gender: UserGender = .notSet { didSet { UserDefaults.standard.set(gender.rawValue, forKey: "user_gender") } } // [New]
    
    // MARK: - Health Data
    @Published var stepCount: Int = 0
    @Published var basalEnergy: Double = 0
    @Published var weeklyRecords: [DailyRecord] = []
    
    private let healthStore = HKHealthStore()
    
    override init() {
        self.height = UserDefaults.standard.double(forKey: "user_height")
        self.currentWeight = UserDefaults.standard.double(forKey: "user_weight")
        self.targetWeight = UserDefaults.standard.double(forKey: "user_target_weight")
        // Load gender
        if let savedGender = UserDefaults.standard.string(forKey: "user_gender"), let g = UserGender(rawValue: savedGender) {
            self.gender = g
        }
        
        super.init()
        Purchases.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
        Task { await setupSystem() }
    }
    
    @objc func appDidBecomeActive() {
        checkSubscriptionStatus()
        Task { await healthCheck() }
        syncHealthData()
        loadHistory()
        updateUsageCount()
    }
    
    func setupSystem() async {
        self.isAppLoading = true
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.healthCheck() }
            group.addTask { await MainActor.run { self.checkSubscriptionStatus() } }
            group.addTask { await MainActor.run { self.fetchOfferings() } }
            group.addTask { await MainActor.run { self.syncHealthData() } }
            group.addTask { await MainActor.run { self.loadHistory() } }
        }
        updateUsageCount()
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        withAnimation(.easeInOut(duration: 0.6)) { self.isAppLoading = false }
    }
    
    // MARK: - Core Logic
    func analyzeImage(uiImage: UIImage, language: AppLanguage) async {
        if serverStatus == .offline {
            await healthCheck()
            if serverStatus == .offline { self.viewState = .error("Server is currently offline."); return }
        }
        
        #if DEBUG
        let bypass = debugBypassPro
        #else
        let bypass = false
        #endif
        
        if !isProUser && !bypass {
            let used = KeychainHelper.read(key: usageKey)
            if used < maxFreeUsageCount {
                KeychainHelper.save(count: used + 1, key: usageKey)
                updateUsageCount()
            } else {
                self.viewState = .empty; self.updateUsageCount(); self.isShowingPaywall = true; return
            }
        }
        
        self.viewState = .loading(TranslationManager.get("hint.loading_ocr", lang: language))
        let ocrText = await recognizeText(from: uiImage)
        
        self.viewState = .loading(TranslationManager.get("hint.loading_upload", lang: language))
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        self.viewState = .loading(TranslationManager.get("hint.loading_ai", lang: language))
        
        do {
            let rawResponse = try await fetchCaloriesFromImage(for: uiImage, language: language.rawValue, detectedText: ocrText)
            self.isCurrentMealLogged = false
            self.viewState = .success(rawResponse)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            self.viewState = .error(error.localizedDescription)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    private func fetchCaloriesFromImage(for image: UIImage, language: String, detectedText: String?) async throws -> CloudResponsePayload {
        let resized = image.resizeTo(maxDimension: 1024)
        guard let data = resized.jpegData(compressionQuality: 0.9) else { throw CalorieEstimatorError.imageConversionFailed }
        
        // [New] Pass gender to profile
        let profile = UserProfile(height: height, currentWeight: currentWeight, targetWeight: targetWeight, stepCount: stepCount, basalEnergy: basalEnergy, gender: gender)
        
        let payload = RequestPayload(
            image: data.base64EncodedString(),
            language: language,
            userProfile: profile,
            detectedText: detectedText,
            mealTime: MealTime.current.rawValue
        )
        
        guard let encoded = try? JSONEncoder().encode(payload) else { throw CalorieEstimatorError.jsonEncodingFailed }
        
        var request = URLRequest(url: API.baseURL.appendingPathComponent("estimate-calories"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encoded
        request.timeoutInterval = 60
        
        let (d, r) = try await URLSession.shared.data(for: request)
        guard (r as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        
        return try JSONDecoder().decode(CloudResponsePayload.self, from: d)
    }
    
    // MARK: - Helpers
    func handleImageSelection(_ uiImage: UIImage) { self.selectedImage = Image(uiImage: uiImage); self.viewState = .empty; self.isCurrentMealLogged = false }
    
    func recognizeText(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                let txt = (request.results as? [VNRecognizedTextObservation])?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: ", ")
                continuation.resume(returning: txt)
            }
            request.recognitionLanguages = ["zh-Hant", "en-US", "ja"]
            request.recognitionLevel = .accurate
            try? VNImageRequestHandler(cgImage: cgImage).perform([request])
        }
    }
    
    func healthCheck() async {
        DispatchQueue.main.async { self.serverStatus = .checking }
        do {
            let (_, res) = try await URLSession.shared.data(for: URLRequest(url: API.baseURL.appendingPathComponent("health")))
            DispatchQueue.main.async { self.serverStatus = (res as? HTTPURLResponse)?.statusCode == 200 ? .online : .offline }
        } catch {
            DispatchQueue.main.async { self.serverStatus = .offline }
        }
    }
    
    func checkSubscriptionStatus() { Purchases.shared.getCustomerInfo { info, _ in DispatchQueue.main.async { self.isProUser = info?.entitlements.active.keys.contains("pro") ?? false; self.updateUsageCount() } } }
    func fetchOfferings() { Purchases.shared.getOfferings { offerings, _ in DispatchQueue.main.async { self.offerings = offerings } } }
    func restorePurchases() { Purchases.shared.restorePurchases { info, _ in if let info = info { DispatchQueue.main.async { self.isProUser = info.entitlements.active.keys.contains("pro"); self.updateUsageCount() } } } }
    func updateUsageCount() { if isProUser { self.remainingFreeUsage = 999 } else { let used = KeychainHelper.read(key: usageKey); self.remainingFreeUsage = max(0, maxFreeUsageCount - used) } }
    
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        let isPro = customerInfo.entitlements.active.keys.contains("pro")
        Task { @MainActor in self.isProUser = isPro; self.updateUsageCount(); if isPro { self.isShowingPaywall = false } }
    }
    
    func loadHistory() { Task { let r = await HistoryManager.shared.getWeeklyRecords(); await MainActor.run { self.weeklyRecords = r } } }
    
    func logCurrentMeal(calories: Int) {
        guard !isCurrentMealLogged else { return }
        self.isCurrentMealLogged = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { await HistoryManager.shared.addCalories(amount: calories); self.loadHistory() }
    }
    
    // MARK: - HealthKit Sync
    func syncHealthData() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        // [New] Request biological sex
        let types: Set = [
            HKQuantityType.quantityType(forIdentifier: .height)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex)!
        ]
        healthStore.requestAuthorization(toShare: nil, read: types) { s, _ in if s { self.performHealthQueries() } }
    }
    
    nonisolated private func performHealthQueries() {
        let store = HKHealthStore()
        
        // [New] Fetch Biological Sex
        if let bioSex = try? store.biologicalSex() {
            Task { @MainActor in
                switch bioSex.biologicalSex {
                case .female: self.gender = .female
                case .male: self.gender = .male
                default: break // Keep existing manual setting if undefined
                }
            }
        }
        
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        func safeRead(type: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping @MainActor (Double) -> Void) {
            guard let sampleType = HKQuantityType.quantityType(forIdentifier: type) else { return }
            let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample { let val = sample.quantity.doubleValue(for: unit); Task { @MainActor in completion(val) } }
            }
            store.execute(query)
        }
        safeRead(type: .height, unit: .meter()) { val in Task { @MainActor [self] in self.height = val * 100 } }
        safeRead(type: .bodyMass, unit: .gramUnit(with: .kilo)) { val in Task { @MainActor [self] in self.currentWeight = val } }
        safeRead(type: .basalEnergyBurned, unit: .kilocalorie()) { val in Task { @MainActor [self] in self.basalEnergy = val } }
        
        let now = Date(); let start = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        store.execute(HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, r, _ in
            let steps = Int(r?.sumQuantity()?.doubleValue(for: .count()) ?? 0); Task { @MainActor [self] in self.stepCount = steps }
        })
    }
}
