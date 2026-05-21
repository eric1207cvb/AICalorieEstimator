import Foundation
import SwiftUI
import Combine
import HealthKit
import Vision
import ImageIO
import RevenueCat

struct ImageTextRecognizer {
    static func recognizeText(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLanguages = ["zh-Hant", "en-US", "ja-JP"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            do {
                try handler.perform([request])
                return request.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: ", ")
            } catch {
                return nil
            }
        }.value
    }
}

enum HealthKitUnits {
    static var metabolicEquivalentOfTask: HKUnit {
        let bodyMassHour = HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .hour())
        return HKUnit.kilocalorie().unitDivided(by: bodyMassHour)
    }
}

struct UserProfilePreferenceStore {
    private enum Key {
        static let medicalDietMode = "user_medical_diet_mode"
        static let diabetesStage = "user_diabetes_stage"
        static let ckdStage = "user_ckd_stage"
        static let activityScenario = "user_activity_scenario"
    }

    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(medicalDietMode: MedicalDietMode) {
        defaults.set(medicalDietMode.rawValue, forKey: Key.medicalDietMode)
    }

    func save(diabetesStage: DiabetesStage) {
        defaults.set(diabetesStage.rawValue, forKey: Key.diabetesStage)
    }

    func save(ckdStage: CKDStage) {
        defaults.set(ckdStage.rawValue, forKey: Key.ckdStage)
    }

    func save(activityScenario: ActivityScenario) {
        defaults.set(activityScenario.rawValue, forKey: Key.activityScenario)
    }

    func loadMedicalDietMode(default defaultValue: MedicalDietMode = .standard) -> MedicalDietMode {
        guard let rawValue = defaults.string(forKey: Key.medicalDietMode),
              let mode = MedicalDietMode(rawValue: rawValue) else {
            return defaultValue
        }
        return mode
    }

    func loadDiabetesStage(default defaultValue: DiabetesStage = .type2NonInsulin) -> DiabetesStage {
        guard let rawValue = defaults.string(forKey: Key.diabetesStage),
              let stage = DiabetesStage(rawValue: rawValue) else {
            return defaultValue
        }
        return stage
    }

    func loadCKDStage(default defaultValue: CKDStage = .stage3a) -> CKDStage {
        guard let rawValue = defaults.string(forKey: Key.ckdStage),
              let stage = CKDStage(rawValue: rawValue) else {
            return defaultValue
        }
        return stage
    }

    func loadActivityScenario(default defaultValue: ActivityScenario = .mostlySitting) -> ActivityScenario {
        guard let rawValue = defaults.string(forKey: Key.activityScenario),
              let scenario = ActivityScenario(rawValue: rawValue) else {
            return defaultValue
        }
        return scenario
    }
}

// MARK: - [Client v9.27] ViewModel (With Gender Sync)
@MainActor
class CalorieEstimatorViewModel: NSObject, ObservableObject, PurchasesDelegate {

    // MARK: - UI States
    @Published var viewState: ViewState = .empty
    @Published var selectedImage: Image? = nil
    @Published var serverStatus: ServerStatus = .unknown
    @Published var isAppLoading: Bool = true
    @Published var isCurrentMealLogged: Bool = false
    @Published var currentMealLogEntry: MealLogEntry? = nil

    // MARK: - RevenueCat
    @Published var offerings: Offerings?
    @Published var isProUser: Bool = false
    @Published var isShowingPaywall: Bool = false
    @Published var remainingFreeUsage: Int = 3

    private let usageKey = "user_free_daily_usage_v1"
    private let freeScanLimiter = FreeScanLimiter(dailyLimit: 3)
    private let profilePreferences = UserProfilePreferenceStore()

    #if DEBUG
    @Published var debugBypassPro: Bool = false { didSet { updateUsageCount() } }
    #endif

    // MARK: - User Profile
    @Published var height: Double { didSet { UserDefaults.standard.set(height, forKey: "user_height") } }
    @Published var currentWeight: Double { didSet { UserDefaults.standard.set(currentWeight, forKey: "user_weight") } }
    @Published var targetWeight: Double {
        didSet {
            UserDefaults.standard.set(targetWeight, forKey: "user_target_weight")
            if targetWeight <= 0 {
                goalStartWeight = 0
            } else if currentWeight > 0 && abs(targetWeight - oldValue) > 0.1 {
                goalStartWeight = currentWeight
            }
        }
    }
    @Published var goalStartWeight: Double { didSet { UserDefaults.standard.set(goalStartWeight, forKey: "user_goal_start_weight") } }
    @Published var gender: UserGender = .notSet { didSet { UserDefaults.standard.set(gender.rawValue, forKey: "user_gender") } } // [New]
    @Published var activityScenario: ActivityScenario = .mostlySitting { didSet { profilePreferences.save(activityScenario: activityScenario) } }
    @Published var medicalDietMode: MedicalDietMode = .standard { didSet { profilePreferences.save(medicalDietMode: medicalDietMode) } }
    @Published var diabetesStage: DiabetesStage = .type2NonInsulin { didSet { profilePreferences.save(diabetesStage: diabetesStage) } }
    @Published var ckdStage: CKDStage = .stage3a { didSet { profilePreferences.save(ckdStage: ckdStage) } }

    // MARK: - Health Data
    @Published var stepCount: Int = 0
    @Published var basalEnergy: Double = 0
    @Published var watchHealthSnapshot = WatchHealthSnapshot()
    @Published var healthSyncState: HealthSyncState = .idle
    @Published var weeklyRecords: [DailyRecord] = []

    private let healthStore = HKHealthStore()

    var currentUserProfile: UserProfile {
        UserProfile(
            height: height,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            stepCount: stepCount,
            basalEnergy: basalEnergy,
            gender: gender,
            activeEnergy: watchHealthSnapshot.activeEnergy,
            exerciseMinutes: watchHealthSnapshot.exerciseMinutes,
            standMinutes: watchHealthSnapshot.standMinutes,
            sleepMinutes: watchHealthSnapshot.sleepMinutes,
            restingHeartRate: watchHealthSnapshot.restingHeartRate,
            heartRateVariability: watchHealthSnapshot.heartRateVariability,
            respiratoryRate: watchHealthSnapshot.respiratoryRate,
            oxygenSaturation: watchHealthSnapshot.oxygenSaturation,
            workoutMinutes: watchHealthSnapshot.workoutDurationMinutes,
            activityScenario: activityScenario,
            activityDataSourceKind: watchHealthSnapshot.activitySourceKind,
            medicalDietMode: medicalDietMode,
            diabetesStage: diabetesStage,
            ckdStage: ckdStage
        )
    }

    override init() {
        let preferenceStore = UserProfilePreferenceStore()
        let savedHeight = UserDefaults.standard.double(forKey: "user_height")
        let savedCurrentWeight = UserDefaults.standard.double(forKey: "user_weight")
        let savedTargetWeight = UserDefaults.standard.double(forKey: "user_target_weight")
        let savedGoalStartWeight = UserDefaults.standard.double(forKey: "user_goal_start_weight")

        self.height = savedHeight
        self.currentWeight = savedCurrentWeight
        self.targetWeight = savedTargetWeight
        if savedGoalStartWeight <= 0, savedCurrentWeight > 0, savedTargetWeight > 0, abs(savedCurrentWeight - savedTargetWeight) >= 0.5 {
            self.goalStartWeight = savedCurrentWeight
        } else {
            self.goalStartWeight = savedGoalStartWeight
        }
        // Load gender
        if let savedGender = UserDefaults.standard.string(forKey: "user_gender"), let g = UserGender(rawValue: savedGender) {
            self.gender = g
        }
        self.medicalDietMode = preferenceStore.loadMedicalDietMode()
        self.diabetesStage = preferenceStore.loadDiabetesStage()
        self.ckdStage = preferenceStore.loadCKDStage()
        self.activityScenario = preferenceStore.loadActivityScenario()

        super.init()
        Purchases.shared.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(calendarDayDidChange), name: .NSCalendarDayChanged, object: nil)
        Task { await setupSystem() }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func appDidBecomeActive() {
        checkSubscriptionStatus(forceRefresh: true)
        Task { await healthCheck() }
        syncHealthData()
        loadHistory()
        updateUsageCount()
    }

    @objc private func calendarDayDidChange() {
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

        if isProUser && !bypass {
            await refreshSubscriptionStatus(forceRefresh: true, failClosed: true)
        }

        let usage = loadFreeUsage()
        let hasProAccess = isProUser || bypass
        let shouldConsumeFreeUsage = !hasProAccess
        if !freeScanLimiter.canStartAnalysis(usage: usage, now: Date(), isPro: isProUser, bypass: bypass) {
            self.viewState = .empty
            self.updateUsageCount()
            self.isShowingPaywall = true
            return
        }

        setAnalysisProgress(messageKey: "hint.loading_prepare", detailKey: "progress.detail_prepare", fraction: 0.08, language: language)
        let preparedImage = uiImage.fixOrientation()
        self.selectedImage = Image(uiImage: preparedImage)

        setAnalysisProgress(messageKey: "hint.loading_ocr", detailKey: "progress.detail_ocr", fraction: 0.22, language: language)
        let ocrText = await recognizeText(from: preparedImage)

        setAnalysisProgress(messageKey: "hint.loading_upload", detailKey: "progress.detail_upload", fraction: 0.42, language: language)
        try? await Task.sleep(nanoseconds: 200_000_000)

        setAnalysisProgress(messageKey: "hint.loading_ai", detailKey: "progress.detail_ai", fraction: 0.68, language: language)

        do {
            let rawResponse = try await fetchCaloriesFromImage(for: preparedImage, language: language, detectedText: ocrText, isProMode: hasProAccess)
            setAnalysisProgress(messageKey: "hint.loading_finalize", detailKey: "progress.detail_finalize", fraction: 0.94, language: language)
            if shouldConsumeFreeUsage {
                consumeFreeUsageAfterSuccessfulAnalysis()
            }
            self.isCurrentMealLogged = false
            self.currentMealLogEntry = nil
            self.viewState = .success(rawResponse)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            self.viewState = .error(error.localizedDescription)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func fetchCaloriesFromImage(for image: UIImage, language: AppLanguage, detectedText: String?, isProMode: Bool) async throws -> CloudResponsePayload {
        let resized = image.resizeTo(maxDimension: 1536)
        guard let data = resized.jpegData(compressionQuality: 0.88) else { throw CalorieEstimatorError.imageConversionFailed }
        let profile = currentUserProfile
        let foodSceneContext = FoodSceneAnalysisContext.make(language: language)
        let weightGuidanceContext = WeightGuidanceContext.make(profile: profile, language: language)
        let specialDietContext = SpecialDietRequestContext.make(for: profile, language: language)
        let communicationGuardrailContext = AICommunicationGuardrailContext.make(language: language)
        let responseDetailContext = AIResponseDetailContext.make(isPro: isProMode, language: language)
        let compatibilityDetectedText = LegacyServerCompatibilityPrompt.detectedText(
            ocrText: detectedText,
            foodSceneContext: foodSceneContext,
            weightGuidanceContext: weightGuidanceContext,
            specialDietContext: specialDietContext,
            communicationGuardrailContext: communicationGuardrailContext,
            responseDetailContext: responseDetailContext,
            language: language
        )

        let payload = RequestPayload(
            image: data.base64EncodedString(),
            language: language.aiLanguageCode,
            userProfile: FoodRecognitionProfile(profile: profile),
            detectedText: compatibilityDetectedText,
            mealTime: MealTime.current.rawValue,
            communicationGuardrailContext: communicationGuardrailContext,
            responseDetailContext: responseDetailContext,
            foodSceneContext: foodSceneContext,
            weightGuidanceContext: weightGuidanceContext,
            specialDietContext: specialDietContext
        )

        guard let encoded = try? JSONEncoder().encode(payload) else { throw CalorieEstimatorError.jsonEncodingFailed }

        var request = URLRequest(url: API.baseURL.appendingPathComponent("estimate-calories"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encoded
        request.timeoutInterval = 60

        let (d, r) = try await URLSession.shared.data(for: request)
        guard let response = r as? HTTPURLResponse else { throw CalorieEstimatorError.invalidHTTPResponse }
        guard response.statusCode == 200 else {
            let body = String(data: d, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            throw CalorieEstimatorError.serverRejected(statusCode: response.statusCode, message: body.truncatedForErrorMessage)
        }

        do {
            return try JSONDecoder().decode(CloudResponsePayload.self, from: d).sanitizedForDisplay(language: language)
        } catch {
            throw CalorieEstimatorError.responseDecodingFailed(error.localizedDescription)
        }
    }

    // MARK: - Helpers
    func handleImageSelection(_ uiImage: UIImage) {
        let preparedImage = uiImage.fixOrientation()
        self.selectedImage = Image(uiImage: preparedImage)
        self.viewState = .empty
        self.isCurrentMealLogged = false
        self.currentMealLogEntry = nil
    }

    func recognizeText(from image: UIImage) async -> String? {
        await ImageTextRecognizer.recognizeText(from: image)
    }

    private func setAnalysisProgress(messageKey: String, detailKey: String, fraction: Double, language: AppLanguage) {
        let progress = AnalysisProgress(
            message: TranslationManager.get(messageKey, lang: language),
            detail: TranslationManager.get(detailKey, lang: language),
            fraction: fraction
        )
        withAnimation(.easeInOut(duration: 0.2)) {
            self.viewState = .loading(progress)
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

    func checkSubscriptionStatus(forceRefresh: Bool = false) {
        Task { await refreshSubscriptionStatus(forceRefresh: forceRefresh, failClosed: false) }
    }

    @discardableResult
    func refreshSubscriptionStatus(forceRefresh: Bool = false, failClosed: Bool = false) async -> Bool {
        if forceRefresh {
            Purchases.shared.invalidateCustomerInfoCache()
        }

        do {
            let info = try await Purchases.shared.customerInfo()
            applyCustomerInfo(info)
        } catch {
            if failClosed {
                isProUser = false
            }
            updateUsageCount()
        }

        return isProUser
    }

    func fetchOfferings() { Purchases.shared.getOfferings { offerings, _ in DispatchQueue.main.async { self.offerings = offerings } } }
    func restorePurchases() {
        Purchases.shared.invalidateCustomerInfoCache()
        Purchases.shared.restorePurchases { info, _ in
            DispatchQueue.main.async {
                if let info {
                    self.applyCustomerInfo(info)
                } else {
                    self.isProUser = false
                    self.updateUsageCount()
                }
            }
        }
    }
    func updateUsageCount() {
        let usage = loadFreeUsage()
        #if DEBUG
        let hasUnlimitedAccess = isProUser || debugBypassPro
        #else
        let hasUnlimitedAccess = isProUser
        #endif
        self.remainingFreeUsage = freeScanLimiter.remainingCount(usage: usage, now: Date(), isPro: hasUnlimitedAccess)
    }

    #if DEBUG
    func enableSimulatorPurchaseTestingAccess() {
        debugBypassPro = true
        isShowingPaywall = false
        updateUsageCount()
    }
    #endif

    func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        isProUser = SubscriptionAccessPolicy.hasActiveProEntitlement(customerInfo.entitlements.active.keys)
        updateUsageCount()
        if isProUser { isShowingPaywall = false }
    }

    private func consumeFreeUsageAfterSuccessfulAnalysis() {
        let usage = loadFreeUsage()
        let next = freeScanLimiter.usageAfterSuccessfulAnalysis(usage: usage, now: Date(), isPro: false, bypass: false)
        saveFreeUsage(next)
        updateUsageCount()
    }

    private func loadFreeUsage() -> DailyFreeUsage? {
        KeychainHelper.read(DailyFreeUsage.self, key: usageKey)
    }

    private func saveFreeUsage(_ usage: DailyFreeUsage) {
        KeychainHelper.save(usage, key: usageKey)
    }

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in self.applyCustomerInfo(customerInfo) }
    }

    func loadHistory() { Task { let r = await HistoryManager.shared.getWeeklyRecords(); await MainActor.run { self.weeklyRecords = r } } }

    func logCurrentMeal(payload: CloudResponsePayload, language: AppLanguage) {
        guard !isCurrentMealLogged else { return }
        let calories = payload.averageSafeCalories
        let foodSummary = payload.safeFoodList(language: language)
        self.isCurrentMealLogged = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task {
            let entry = await HistoryManager.shared.addMeal(calories: calories, foodSummary: foodSummary)
            self.currentMealLogEntry = entry
            self.loadHistory()
        }
    }

    func deleteCurrentMealLog() {
        guard let entry = currentMealLogEntry else { return }
        Task {
            let deleted = await HistoryManager.shared.deleteMeal(id: entry.id)
            guard deleted else { return }
            self.currentMealLogEntry = nil
            self.isCurrentMealLogged = false
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            self.loadHistory()
        }
    }

    // MARK: - HealthKit Sync
    func syncHealthData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthSyncState = .unavailable
            return
        }

        healthSyncState = .requesting
        healthStore.requestAuthorization(toShare: nil, read: healthReadTypes) { [weak self] success, error in
            Task { @MainActor in
                guard let self else { return }
                if success {
                    self.healthSyncState = .syncing
                    await self.performHealthQueries()
                } else {
                    self.healthSyncState = .failed(error?.localizedDescription ?? "Health authorization was not granted.")
                }
            }
        }
    }

    private var healthReadTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        [
            HKQuantityType.quantityType(forIdentifier: .height),
            HKQuantityType.quantityType(forIdentifier: .bodyMass),
            HKQuantityType.quantityType(forIdentifier: .stepCount),
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime),
            HKQuantityType.quantityType(forIdentifier: .appleStandTime),
            HKQuantityType.quantityType(forIdentifier: .appleMoveTime),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed),
            HKQuantityType.quantityType(forIdentifier: .heartRate),
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate),
            HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage),
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate),
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation),
            HKQuantityType.quantityType(forIdentifier: .appleSleepingWristTemperature),
            HKQuantityType.quantityType(forIdentifier: .timeInDaylight),
            HKQuantityType.quantityType(forIdentifier: .physicalEffort)
        ].compactMap { $0 }.forEach { types.insert($0) }

        if let sexType = HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex) {
            types.insert(sexType)
        }
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        types.insert(HKObjectType.workoutType())
        return types
    }

    private func performHealthQueries() async {
        syncBiologicalSex()

        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let sleepStart = calendar.date(byAdding: .hour, value: -18, to: todayStart) ?? todayStart

        async let heightMeters = latestQuantity(.height, unit: .meter())
        async let weightKg = latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let steps = cumulativeQuantity(.stepCount, unit: .count(), start: todayStart, end: now)
        async let basal = cumulativeQuantity(.basalEnergyBurned, unit: .kilocalorie(), start: todayStart, end: now)
        async let active = cumulativeQuantity(.activeEnergyBurned, unit: .kilocalorie(), start: todayStart, end: now)
        async let exercise = cumulativeQuantity(.appleExerciseTime, unit: .minute(), start: todayStart, end: now)
        async let stand = cumulativeQuantity(.appleStandTime, unit: .minute(), start: todayStart, end: now)
        async let move = cumulativeQuantity(.appleMoveTime, unit: .minute(), start: todayStart, end: now)
        async let distanceKm = cumulativeQuantity(.distanceWalkingRunning, unit: .meterUnit(with: .kilo), start: todayStart, end: now)
        async let flights = cumulativeQuantity(.flightsClimbed, unit: .count(), start: todayStart, end: now)
        async let avgHeartRate = averageQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: todayStart, end: now)
        async let resting = latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), start: todayStart, end: now)
        async let walkingHR = latestQuantity(.walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute()), start: todayStart, end: now)
        async let hrv = averageQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli), start: todayStart, end: now)
        async let respiratory = averageQuantity(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()), start: todayStart, end: now)
        async let oxygen = averageQuantity(.oxygenSaturation, unit: .percent(), start: todayStart, end: now)
        async let wristTemp = latestQuantity(.appleSleepingWristTemperature, unit: .degreeCelsius(), start: sleepStart, end: now)
        async let daylight = cumulativeQuantity(.timeInDaylight, unit: .minute(), start: todayStart, end: now)
        async let effort = averageQuantity(.physicalEffort, unit: HealthKitUnits.metabolicEquivalentOfTask, start: todayStart, end: now)
        async let sleepMinutes = sleepDurationMinutes(start: sleepStart, end: now)
        async let workoutSummary = workoutSummary(start: todayStart, end: now)
        async let activitySource = latestActivitySourceName(start: sleepStart, end: now)

        let summary = await workoutSummary
        let sourceName = await activitySource ?? ""
        var snapshot = WatchHealthSnapshot(
            steps: Int(await steps),
            activeEnergy: await active,
            basalEnergy: await basal,
            exerciseMinutes: await exercise,
            standMinutes: await stand,
            moveMinutes: await move,
            distanceWalkingRunningKm: await distanceKm,
            flightsClimbed: await flights,
            averageHeartRate: await avgHeartRate,
            restingHeartRate: await resting,
            walkingHeartRateAverage: await walkingHR,
            heartRateVariability: await hrv,
            respiratoryRate: await respiratory,
            oxygenSaturation: await oxygen,
            sleepMinutes: await sleepMinutes,
            wristTemperatureCelsius: await wristTemp,
            timeInDaylightMinutes: await daylight,
            physicalEffortMETs: await effort,
            workoutCount: summary.count,
            workoutDurationMinutes: summary.durationMinutes,
            workoutEnergy: summary.activeEnergy,
            latestWorkoutName: summary.latestName,
            watchSourceName: sourceName.localizedCaseInsensitiveContains("watch") ? sourceName : "",
            activitySourceName: sourceName,
            lastUpdated: now
        )
        snapshot.activitySourceKind = HealthDataSourceKind.classify(sourceName: sourceName, hasSignals: snapshot.hasActivitySignals)

        if snapshot.activeEnergy == 0, snapshot.workoutEnergy > 0 {
            snapshot.activeEnergy = snapshot.workoutEnergy
        }

        let heightValue = await heightMeters
        let weightValue = await weightKg
        if heightValue > 0 { height = heightValue * 100 }
        if weightValue > 0 { currentWeight = weightValue }
        stepCount = snapshot.steps
        basalEnergy = snapshot.basalEnergy
        watchHealthSnapshot = snapshot
        healthSyncState = .synced(now)
    }

    private func syncBiologicalSex() {
        if let bioSex = try? healthStore.biologicalSex() {
            switch bioSex.biologicalSex {
            case .female: gender = .female
            case .male: gender = .male
            default: break
            }
        }
    }

    private func predicate(start: Date?, end: Date?) -> NSPredicate? {
        guard start != nil || end != nil else { return nil }
        return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    }

    private func cumulativeQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate(start: start, end: end),
                options: .cumulativeSum
            ) { _, result, _ in
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            healthStore.execute(query)
        }
    }

    private func averageQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate(start: start, end: end),
                options: .discreteAverage
            ) { _, result, _ in
                continuation.resume(returning: result?.averageQuantity()?.doubleValue(for: unit) ?? 0)
            }
            healthStore.execute(query)
        }
    }

    private func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date? = nil, end: Date? = nil) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate(start: start, end: end), limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func sleepDurationMinutes(start: Date, end: Date) async -> Double {
        guard let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate(start: start, end: end), limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let seconds = (samples as? [HKCategorySample])?.reduce(0.0) { total, sample in
                    asleepValues.contains(sample.value) ? total + sample.endDate.timeIntervalSince(sample.startDate) : total
                } ?? 0
                continuation.resume(returning: seconds / 60)
            }
            healthStore.execute(query)
        }
    }

    private func workoutSummary(start: Date, end: Date) async -> (count: Int, durationMinutes: Double, activeEnergy: Double, latestName: String) {
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate(start: start, end: end), limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                let workouts = samples as? [HKWorkout] ?? []
                let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
                let activeEnergy = workouts.reduce(0.0) { total, workout in
                    guard let activeEnergyType else { return total }
                    return total + (workout.statistics(for: activeEnergyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
                }
                let duration = workouts.reduce(0.0) { $0 + $1.duration } / 60
                continuation.resume(returning: (
                    count: workouts.count,
                    durationMinutes: duration,
                    activeEnergy: activeEnergy,
                    latestName: workouts.first.map { self.workoutName($0.workoutActivityType) } ?? ""
                ))
            }
            healthStore.execute(query)
        }
    }

    private func latestActivitySourceName(start: Date, end: Date) async -> String? {
        for identifier in [HKQuantityTypeIdentifier.activeEnergyBurned, .stepCount, .appleExerciseTime, .heartRate, .respiratoryRate, .oxygenSaturation] {
            if let source = await latestSourceName(identifier, start: start, end: end) {
                return source
            }
        }
        return nil
    }

    private func latestSourceName(_ identifier: HKQuantityTypeIdentifier, start: Date, end: Date) async -> String? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate(start: start, end: end), limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                continuation.resume(returning: samples?.first?.sourceRevision.source.name)
            }
            healthStore.execute(query)
        }
    }

    nonisolated private func workoutName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .traditionalStrengthTraining: return "Strength"
        case .functionalStrengthTraining: return "Functional Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .dance: return "Dance"
        case .mindAndBody: return "Mind & Body"
        default: return "Workout"
        }
    }
}
