//
//  AICalorieEstimatorTests.swift
//  AICalorieEstimatorTests
//
//  Created by 薛宜安 on 2025/11/13.
//

import Testing
import Foundation
import HealthKit
@testable import AICalorieEstimator

struct AICalorieEstimatorTests {

    @Test func numericBodyInputFiltersTextInputMethodsAndKeepsDigits() async throws {
        #expect(NumericInputSanitizer.sanitizedDecimalString("ㄅㄆ170cm", maximumFractionDigits: 1) == "170")
        #expect(NumericInputSanitizer.sanitizedDecimalString("７２．５kg", maximumFractionDigits: 1) == "72.5")
        #expect(NumericInputSanitizer.sanitizedDecimalString("68,25", maximumFractionDigits: 1) == "68.2")
        #expect(NumericInputSanitizer.sanitizedDecimalString("ㄓㄨˋㄧㄣ", maximumFractionDigits: 1).isEmpty)
        #expect(NumericInputSanitizer.displayString(for: 0, maximumFractionDigits: 1).isEmpty)
        #expect(NumericInputSanitizer.displayString(for: 70, maximumFractionDigits: 1) == "70")
    }

    @MainActor
    @Test func weeklyChartWeekdayLabelsFollowAppLanguage() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 18, hour: 12).date!

        #expect(WeeklyProgressCard.weekdayLabel(for: monday, language: .traditionalChinese, calendar: calendar) == "一")
        #expect(WeeklyProgressCard.weekdayLabel(for: monday, language: .unitedStates, calendar: calendar) == "Mon")
        #expect(WeeklyProgressCard.weekdayLabel(for: monday, language: .japan, calendar: calendar) == "月")
    }

    @MainActor
    @Test func physicalEffortUsesParseableMETUnit() async throws {
        let unit = HealthKitUnits.metabolicEquivalentOfTask
        let quantity = HKQuantity(unit: unit, doubleValue: 3.5)

        #expect(unit.unitString.contains("kcal"))
        #expect(abs(quantity.doubleValue(for: unit) - 3.5) < 0.001)
    }

    @MainActor
    @Test func dailyCalorieLimitUsesProfileAndGoal() async throws {
        let weightLossProfile = UserProfile(
            height: 170,
            currentWeight: 80,
            targetWeight: 70,
            stepCount: 2_000,
            basalEnergy: 1_500,
            gender: .male
        )
        #expect(weightLossProfile.dailyCalorieLimit == 1_500)
        #expect(weightLossProfile.estimatedMaintenanceCalories == 1_800)
        #expect(weightLossProfile.goalCalorieAdjustment == -500)

        let weightGainProfile = UserProfile(
            height: 165,
            currentWeight: 60,
            targetWeight: 65,
            stepCount: 9_000,
            basalEnergy: 1_400,
            gender: .female
        )
        #expect(weightGainProfile.dailyCalorieLimit == 2_470)
        #expect(weightGainProfile.estimatedMaintenanceCalories == 2_170)
        #expect(weightGainProfile.goalCalorieAdjustment == 300)

        let unsetWeightProfile = UserProfile(
            height: 0,
            currentWeight: 0,
            targetWeight: 0,
            gender: .female
        )
        #expect(unsetWeightProfile.dailyCalorieLimit == 1_500)
    }

    @MainActor
    @Test func weightGoalProgressUsesRealStartCurrentAndTargetWeights() async throws {
        #expect(WeightGoalProgress.progress(startWeight: 80, currentWeight: 75, targetWeight: 70) == 0.5)
        #expect(WeightGoalProgress.progress(startWeight: 60, currentWeight: 63, targetWeight: 66) == 0.5)
        #expect(WeightGoalProgress.progress(startWeight: 80, currentWeight: 82, targetWeight: 70) == 0)
    }

    @MainActor
    @Test func healthCoachAvoidsExtremeTemplateAdviceForSpecialModes() async throws {
        let diabetesProfile = UserProfile(
            height: 170,
            currentWeight: 80,
            targetWeight: 70,
            stepCount: 2_500,
            basalEnergy: 1_500,
            gender: .male,
            medicalDietMode: .diabetes
        )
        let diabetesInsight = HealthCoach.generateInsight(profile: diabetesProfile, todayCalories: 2_200, lang: .unitedStates)

        #expect(diabetesInsight.advice.contains("skipping") || diabetesInsight.advice.contains("fasting"))
        #expect(!diabetesInsight.advice.contains("HIIT"))
        #expect(!diabetesInsight.advice.contains("only"))

        let ckdProfile = UserProfile(
            height: 170,
            currentWeight: 60,
            targetWeight: 66,
            stepCount: 7_000,
            basalEnergy: 1_400,
            gender: .female,
            medicalDietMode: .chronicKidneyDisease,
            ckdStage: .stage4
        )
        let ckdInsight = HealthCoach.generateInsight(profile: ckdProfile, todayCalories: 1_200, lang: .unitedStates)

        #expect(ckdInsight.advice.contains("renal dietitian"))
        #expect(!ckdInsight.advice.lowercased().contains("prioritize protein"))
    }

    @MainActor
    @Test func dailyCalorieLimitUsesWatchActiveEnergyWhenAvailable() async throws {
        let activeWatchProfile = UserProfile(
            height: 180,
            currentWeight: 80,
            targetWeight: 80,
            stepCount: 1_500,
            basalEnergy: 1_600,
            gender: .male,
            activeEnergy: 700,
            exerciseMinutes: 45,
            standMinutes: 90
        )

        #expect(activeWatchProfile.dailyCalorieLimit == 2_300)
    }

    @MainActor
    @Test func activityScenarioSupportsWeightLossWithoutWearable() async throws {
        let mostlySitting = UserProfile(
            height: 170,
            currentWeight: 80,
            targetWeight: 70,
            basalEnergy: 1_600,
            activityScenario: .mostlySitting
        )
        let onFeet = UserProfile(
            height: 170,
            currentWeight: 80,
            targetWeight: 70,
            basalEnergy: 1_600,
            activityScenario: .onFeet
        )

        #expect(!mostlySitting.usesSyncedActivityData)
        #expect(mostlySitting.estimatedMaintenanceCalories == 1_920)
        #expect(onFeet.estimatedMaintenanceCalories == 2_400)
        #expect(onFeet.dailyCalorieLimit > mostlySitting.dailyCalorieLimit)
    }

    @MainActor
    @Test func weightGoalPresetAutofillsTargetsFromCurrentWeight() async throws {
        #expect(WeightGoalPreset.trackFirst.targetWeight(from: 80) == 80)
        #expect(WeightGoalPreset.gentleLoss.targetWeight(from: 80) == 77.6)
        #expect(WeightGoalPreset.steadyLoss.targetWeight(from: 80) == 76)
        #expect(WeightGoalPreset.focusedLoss.targetWeight(from: 80) == 72)
        #expect(WeightGoalPreset.steadyLoss.targetWeight(from: 0) == 0)
    }

    @MainActor
    @Test func healthDataSourceClassifiesAppleWatchAndOtherAuthorizedDevices() async throws {
        #expect(HealthDataSourceKind.classify(sourceName: "Apple Watch", hasSignals: true) == .appleWatch)
        #expect(HealthDataSourceKind.classify(sourceName: "Garmin Connect", hasSignals: true) == .healthConnectedDevice)
        #expect(HealthDataSourceKind.classify(sourceName: "iPhone", hasSignals: true) == .phoneOrHealthApp)
        #expect(HealthDataSourceKind.classify(sourceName: "", hasSignals: false) == .none)
    }

    @MainActor
    @Test func freeScanLimiterResetsDailyAndOnlyConsumesOnSuccess() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let limiter = FreeScanLimiter(dailyLimit: 3, calendar: calendar)
        let dayOne = try #require(DateComponents(calendar: calendar, year: 2026, month: 5, day: 18, hour: 23, minute: 59).date)
        let dayTwo = try #require(DateComponents(calendar: calendar, year: 2026, month: 5, day: 19, hour: 0, minute: 0).date)
        let usage = DailyFreeUsage(dateKey: "2026-05-18", usedCount: 2)

        #expect(limiter.canStartAnalysis(usage: usage, now: dayOne, isPro: false, bypass: false))
        #expect(limiter.remainingCount(usage: usage, now: dayOne, isPro: false) == 1)

        let successfulUsage = limiter.usageAfterSuccessfulAnalysis(usage: usage, now: dayOne, isPro: false, bypass: false)
        #expect(successfulUsage.usedCount == 3)
        #expect(!limiter.canStartAnalysis(usage: successfulUsage, now: dayOne, isPro: false, bypass: false))
        #expect(limiter.canStartAnalysis(usage: successfulUsage, now: dayOne, isPro: true, bypass: false))
        #expect(limiter.canStartAnalysis(usage: successfulUsage, now: dayOne, isPro: false, bypass: true))

        #expect(limiter.usageAfterFailedAnalysis(usage: usage, now: dayOne).usedCount == 2)
        #expect(limiter.remainingCount(usage: successfulUsage, now: dayTwo, isPro: false) == 3)
        #expect(limiter.canStartAnalysis(usage: successfulUsage, now: dayTwo, isPro: false, bypass: false))
    }

    @MainActor
    @Test func freeScanLimiterReturnsToDailyLimitAfterProEnds() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let limiter = FreeScanLimiter(dailyLimit: 3, calendar: calendar)
        let today = try #require(DateComponents(calendar: calendar, year: 2026, month: 5, day: 19, hour: 12).date)
        let tomorrow = try #require(DateComponents(calendar: calendar, year: 2026, month: 5, day: 20, hour: 0).date)
        let exhaustedUsage = DailyFreeUsage(dateKey: "2026-05-19", usedCount: 3)

        #expect(limiter.canStartAnalysis(usage: exhaustedUsage, now: today, isPro: true, bypass: false))
        #expect(limiter.remainingCount(usage: exhaustedUsage, now: today, isPro: true) == 999)

        #expect(!limiter.canStartAnalysis(usage: exhaustedUsage, now: today, isPro: false, bypass: false))
        #expect(limiter.remainingCount(usage: exhaustedUsage, now: today, isPro: false) == 0)
        #expect(limiter.canStartAnalysis(usage: exhaustedUsage, now: tomorrow, isPro: false, bypass: false))
        #expect(limiter.remainingCount(usage: exhaustedUsage, now: tomorrow, isPro: false) == 3)
    }

    @MainActor
    @Test func subscriptionAccessRequiresActiveProEntitlementIdentifier() async throws {
        #expect(SubscriptionAccessPolicy.hasActiveProEntitlement(["pro"]))
        #expect(!SubscriptionAccessPolicy.hasActiveProEntitlement(["premium"]))
        #expect(!SubscriptionAccessPolicy.hasActiveProEntitlement([]))
    }

    @MainActor
    @Test func historyManagerAggregatesAndPadsWeeklyRecords() async throws {
        let suiteName = "HistoryManagerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let fixedDate = try #require(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 18,
            hour: 12
        ).date)

        let manager = HistoryManager(
            defaults: defaults,
            key: "test_history",
            calendar: calendar,
            now: { fixedDate }
        )

        await manager.addCalories(amount: 300)
        await manager.addCalories(amount: 250)

        let records = await manager.getWeeklyRecords()
        #expect(records.count == 7)
        #expect(records.first?.dateString == "2026-05-12")
        #expect(records.first?.totalCalories == 0)
        #expect(records.last?.dateString == "2026-05-18")
        #expect(records.last?.totalCalories == 550)
    }

    @MainActor
    @Test func historyManagerRetainsThreeYearsButWeeklyChartStaysSevenDays() async throws {
        let suiteName = "HistoryManagerRetentionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let fixedDate = try #require(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 18,
            hour: 12
        ).date)
        let testHistoryKey = "test_history_retention"
        let testMealKey = "test_meal_retention"
        let retainedBoundaryDate = try #require(DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2023, month: 5, day: 18, hour: 12).date)
        let expiredDate = try #require(DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2023, month: 5, day: 17, hour: 12).date)

        let seededHistory = [
            DailyRecord(dateString: "2023-05-17", totalCalories: 900),
            DailyRecord(dateString: "2023-05-18", totalCalories: 300),
            DailyRecord(dateString: "2026-05-17", totalCalories: 450)
        ]
        defaults.set(try JSONEncoder().encode(seededHistory), forKey: testHistoryKey)

        let seededMeals = [
            MealLogEntry(id: UUID(), dateString: "2023-05-17", calories: 900, foodSummary: "Expired meal", createdAt: expiredDate),
            MealLogEntry(id: UUID(), dateString: "2023-05-18", calories: 300, foodSummary: "Boundary meal", createdAt: retainedBoundaryDate)
        ]
        defaults.set(try JSONEncoder().encode(seededMeals), forKey: testMealKey)

        let manager = HistoryManager(
            defaults: defaults,
            key: testHistoryKey,
            mealKey: testMealKey,
            calendar: calendar,
            now: { fixedDate }
        )

        await manager.addCalories(amount: 250)
        _ = await manager.addMeal(calories: 520, foodSummary: "Today meal")

        let storedHistoryData = try #require(defaults.data(forKey: testHistoryKey))
        let storedHistory = try JSONDecoder().decode([DailyRecord].self, from: storedHistoryData)
        let storedDates = Set(storedHistory.map(\.dateString))
        #expect(storedDates.contains("2023-05-18"))
        #expect(storedDates.contains("2026-05-17"))
        #expect(storedDates.contains("2026-05-18"))
        #expect(!storedDates.contains("2023-05-17"))

        let weeklyRecords = await manager.getWeeklyRecords()
        #expect(weeklyRecords.count == 7)
        #expect(weeklyRecords.first?.dateString == "2026-05-12")
        #expect(weeklyRecords.last?.dateString == "2026-05-18")

        let recentMeals = await manager.getRecentMeals()
        #expect(recentMeals.contains { $0.foodSummary == "Boundary meal" })
        #expect(recentMeals.contains { $0.foodSummary == "Today meal" })
        #expect(!recentMeals.contains { $0.foodSummary == "Expired meal" })
    }

    @MainActor
    @Test func historyManagerDeletesOnlyTheMistakenMealLog() async throws {
        let suiteName = "HistoryManagerDeleteTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let fixedDate = try #require(DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 5,
            day: 18,
            hour: 12
        ).date)

        let manager = HistoryManager(
            defaults: defaults,
            key: "test_history",
            mealKey: "test_meals",
            calendar: calendar,
            now: { fixedDate }
        )

        let correctMeal = await manager.addMeal(calories: 420, foodSummary: "Chicken rice")
        let mistakenMeal = await manager.addMeal(calories: 900, foodSummary: "Shared table spread")
        let recordsAfterLogging = await manager.getWeeklyRecords()
        #expect(recordsAfterLogging.last?.totalCalories == 1_320)

        let deleted = await manager.deleteMeal(id: mistakenMeal.id)
        let recordsAfterDelete = await manager.getWeeklyRecords()
        let recentMealsAfterDelete = await manager.getRecentMeals()
        let secondDelete = await manager.deleteMeal(id: mistakenMeal.id)
        #expect(deleted)
        #expect(recordsAfterDelete.last?.totalCalories == 420)
        #expect(recentMealsAfterDelete.map(\.id) == [correctMeal.id])
        #expect(!secondDelete)
    }

    @MainActor
    @Test func watchHealthSnapshotDetectsUsefulSignals() async throws {
        var emptySnapshot = WatchHealthSnapshot()
        #expect(!emptySnapshot.hasWatchSignals)

        emptySnapshot.restingHeartRate = 62
        #expect(emptySnapshot.hasWatchSignals)

        let workoutSnapshot = WatchHealthSnapshot(workoutCount: 1, latestWorkoutName: "Running", watchSourceName: "Apple Watch")
        #expect(workoutSnapshot.hasWatchSignals)
    }

    @MainActor
    @Test func appLanguageIncludesChineseAndPublicMarketRegions() async throws {
        #expect(AppLanguage.allCases == [.traditionalChinese, .unitedStates, .japan])
        #expect(AppLanguage.fromStored("en") == .unitedStates)
        #expect(AppLanguage.fromStored("en-GB") == .unitedStates)
        #expect(AppLanguage.fromStored("ja") == .japan)
        #expect(AppLanguage.fromStored("zh-Hant") == .traditionalChinese)
        #expect(AppLanguage.fromStored("zh-TW") == .traditionalChinese)
        #expect(AppLanguage.traditionalChinese.displayName == "台灣 · 繁體中文")
        #expect(AppLanguage.traditionalChinese.compactDisplayName == "繁中")
        #expect(AppLanguage.unitedStates.compactDisplayName == "EN")
        #expect(AppLanguage.japan.aiLanguageCode == "ja-JP")
    }

    @MainActor
    @Test func languagePreferenceUsesSystemUntilUserSwitches() async throws {
        let systemChinese = AppLanguage.initialSelection(savedRawValue: "", hasUserSelectedPreference: false, systemPreferred: .traditionalChinese)
        #expect(systemChinese.language == .traditionalChinese)
        #expect(!systemChinese.shouldPersistAsUserPreference)

        let userSavedJapanese = AppLanguage.initialSelection(savedRawValue: "ja-JP", hasUserSelectedPreference: true, systemPreferred: .traditionalChinese)
        #expect(userSavedJapanese.language == .japan)
        #expect(userSavedJapanese.shouldPersistAsUserPreference)

        let legacyDifferentFromSystem = AppLanguage.initialSelection(savedRawValue: "zh-Hant", hasUserSelectedPreference: false, systemPreferred: .unitedStates)
        #expect(legacyDifferentFromSystem.language == .traditionalChinese)
        #expect(legacyDifferentFromSystem.shouldPersistAsUserPreference)

        let autoSavedSameAsSystem = AppLanguage.initialSelection(savedRawValue: "en-US", hasUserSelectedPreference: false, systemPreferred: .unitedStates)
        #expect(autoSavedSameAsSystem.language == .unitedStates)
        #expect(!autoSavedSameAsSystem.shouldPersistAsUserPreference)
    }

    @MainActor
    @Test func medicalDietPreferencePersistsSpecialModesAndStages() async throws {
        let suiteName = "medicalDietPreferencePersistsSpecialModesAndStages-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserProfilePreferenceStore(defaults: defaults)

        #expect(store.loadMedicalDietMode() == .standard)
        #expect(store.loadDiabetesStage() == .type2NonInsulin)
        #expect(store.loadCKDStage() == .stage3a)

        store.save(medicalDietMode: .diabetes)
        store.save(diabetesStage: .insulinOrHypoglycemiaRisk)
        #expect(store.loadMedicalDietMode() == .diabetes)
        #expect(store.loadDiabetesStage() == .insulinOrHypoglycemiaRisk)

        store.save(medicalDietMode: .chronicKidneyDisease)
        store.save(ckdStage: .stage4)
        #expect(store.loadMedicalDietMode() == .chronicKidneyDisease)
        #expect(store.loadCKDStage() == .stage4)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    @Test func translationManagerAppliesMarketOverrides() async throws {
        #expect(TranslationManager.get("ring.target_title", lang: .unitedStates) == "Daily Budget")
        #expect(TranslationManager.get("button.select_album", lang: .unitedStates) == "Photos")
        #expect(TranslationManager.get("paywall.restore", lang: .japan) == "購入を復元")
    }

    @MainActor
    @Test func paywallCopyAvoidsMixedProLabelsInChineseAndJapanese() async throws {
        let keys = [
            "status.pro_active",
            "status.upgrade_pro",
            "alert.no_credits",
            "paywall.title",
            "paywall.subtitle",
            "paywall.choose_plan_desc",
            "paywall.restore.no_active",
            "paywall.purchase.not_active",
            "subscription.pro_fallback",
            "paywall.plan.monthly",
            "paywall.plan.annual"
        ]
        let chineseCopy = keys.map { TranslationManager.get($0, lang: .traditionalChinese) }.joined(separator: " ")
        let japaneseCopy = keys.map { TranslationManager.get($0, lang: .japan) }.joined(separator: " ")

        #expect(!chineseCopy.contains("Pro"))
        #expect(!japaneseCopy.contains("Pro"))
        #expect(TranslationManager.get("paywall.plan.monthly", lang: .traditionalChinese) == "每月方案")
        #expect(TranslationManager.get("paywall.plan.monthly", lang: .japan) == "月額プラン")
        #expect(TranslationManager.get("paywall.plan.monthly", lang: .unitedStates) == "Monthly Plan")
    }

    @MainActor
    @Test func medicalNutritionAdvisorReturnsNoAdviceForStandardMode() async throws {
        let payload = CloudResponsePayload(
            foodList: "Grilled chicken salad",
            totalCaloriesMin: 350,
            totalCaloriesMax: 450,
            reasoning: "Balanced meal",
            macros: Macronutrients(protein: 32, carbs: 18, fat: 16),
            healthTip: nil
        )
        let profile = UserProfile(height: 170, currentWeight: 70, targetWeight: 70)

        #expect(MedicalNutritionAdvisor.advice(for: payload, profile: profile, lang: .unitedStates) == nil)
    }

    @MainActor
    @Test func healthTipFilterRemovesMedicalTreatmentAndDosageClaims() async throws {
        #expect(MedicalSafetyFilter.safeHealthTip("Choose water and add vegetables to the meal.") != nil)
        #expect(MedicalSafetyFilter.safeHealthTip("Increase insulin dose by 2 units for this meal.") == nil)
        #expect(MedicalSafetyFilter.safeHealthTip("この食事ではインスリン用量を調整してください。") == nil)
        #expect(MedicalSafetyFilter.safeHealthTip("這餐建議調整胰島素劑量。") == nil)
    }

    @MainActor
    @Test func aiOutputGuardHidesMisleadingHallucinatedLanguageAcrossMarkets() async throws {
        #expect(MedicalSafetyFilter.safeHealthTip("This meal will cure diabetes and is guaranteed safe.", language: .unitedStates) == nil)
        #expect(MedicalSafetyFilter.safeHealthTip("This meal is detox and fat-burning.", language: .unitedStates) == nil)
        #expect(MedicalSafetyFilter.safeHealthTip("這餐可以逆轉糖尿病，放心吃到飽。", language: .traditionalChinese) == nil)
        #expect(MedicalSafetyFilter.safeHealthTip("この食事で腎機能が改善し、必ず安定します。", language: .japan) == nil)
        #expect(MedicalSafetyFilter.safeHealthTip("From what is visible, consider a smaller rice portion and add vegetables.", language: .unitedStates) != nil)
    }

    @MainActor
    @Test func cloudResponseSanitizerRemovesUnsafeUserFacingText() async throws {
        let payload = CloudResponsePayload(
            foodList: "rice bowl",
            totalCaloriesMin: 820,
            totalCaloriesMax: 760,
            reasoning: "This definitely includes hidden butter and will stabilize blood sugar.",
            macros: Macronutrients(protein: 18, carbs: 92, fat: 24),
            healthTip: "Guaranteed fat-burning detox.",
            itemEstimates: [
                FoodEstimateItem(name: "junk food", portionDescription: "eat as much as you want", caloriesMin: 400, caloriesMax: 300, confidence: 0.4)
            ]
        )

        let sanitized = payload.sanitizedForDisplay(language: .unitedStates)

        #expect(sanitized.totalCaloriesMin == 760)
        #expect(sanitized.totalCaloriesMax == 820)
        #expect(sanitized.reasoning.isEmpty)
        #expect(sanitized.healthTip == nil)
        #expect(sanitized.itemEstimates[0].name == "Unknown Food")
        #expect(sanitized.itemEstimates[0].portionDescription == nil)
        #expect(sanitized.itemEstimates[0].caloriesMin == 300)
        #expect(sanitized.itemEstimates[0].caloriesMax == 400)
    }

    @MainActor
    @Test func cloudResponsePayloadDecodesLegacyAndLooseServerShapes() async throws {
        let data = try #require("""
        {
          "foods": ["rice", "salmon", "miso soup"],
          "calories": "640",
          "analysis": "Detected a mixed meal.",
          "items": [
            {"name": "rice", "portionDescription": "one bowl", "portionBasis": "standard rice bowl visible in image", "servingCount": 1, "caloriesMin": 220, "caloriesMax": 300, "confidence": 0.82},
            {"foodName": "salmon", "portion": "one fillet", "calories": 260, "confidence": "0.76"}
          ],
          "protein": 31,
          "carbohydrates": 72,
          "fat": 18,
          "healthTip": "Add vegetables and drink water."
        }
        """.data(using: .utf8))

        let payload = try JSONDecoder().decode(CloudResponsePayload.self, from: data)

        #expect(payload.foodList == "rice, salmon, miso soup")
        #expect(payload.totalCaloriesMin == 640)
        #expect(payload.totalCaloriesMax == 640)
        #expect(payload.reasoning == "Detected a mixed meal.")
        #expect(payload.macros == Macronutrients(protein: 31, carbs: 72, fat: 18))
        #expect(payload.itemEstimates.count == 2)
        #expect(payload.itemEstimates[0].portionDescription == "one bowl")
        #expect(payload.itemEstimates[0].portionBasis == "standard rice bowl visible in image")
        #expect(payload.itemEstimates[0].servingCount == 1)
        #expect(payload.itemEstimates[1].caloriesMin == 260)
    }

    @MainActor
    @Test func specialDietRequestContextOnlyAppearsForSpecialModes() async throws {
        let standardProfile = UserProfile(height: 170, currentWeight: 70, targetWeight: 70)
        #expect(SpecialDietRequestContext.make(for: standardProfile, language: .unitedStates) == nil)

        let ckdProfile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 70,
            medicalDietMode: .chronicKidneyDisease,
            ckdStage: .stage4
        )
        let context = try #require(SpecialDietRequestContext.make(for: ckdProfile, language: .unitedStates))

        #expect(context.mode == .chronicKidneyDisease)
        #expect(context.ckdStage == .stage4)
        #expect(context.diabetesStage == nil)
        #expect(context.instruction.lowercased().contains("first identify the food"))
        #expect(context.prohibitedUses.contains("insulin dosing"))
        #expect(context.prohibitedUses.contains("disease staging from the image"))
        #expect(context.prohibitedUses.contains("blood glucose measurement from the image or device sensors"))

        let diabetesProfile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 70,
            medicalDietMode: .diabetes,
            diabetesStage: .insulinOrHypoglycemiaRisk
        )
        let diabetesContext = try #require(SpecialDietRequestContext.make(for: diabetesProfile, language: .unitedStates))
        #expect(diabetesContext.mode == .diabetes)
        #expect(diabetesContext.diabetesStage == .insulinOrHypoglycemiaRisk)
        #expect(diabetesContext.ckdStage == nil)
        #expect(diabetesContext.instruction.lowercased().contains("user-selected context"))
    }

    @MainActor
    @Test func communicationGuardrailsAreLocalizedForPublicMarkets() async throws {
        let us = AICommunicationGuardrailContext.make(language: .unitedStates)
        let jp = AICommunicationGuardrailContext.make(language: .japan)

        #expect(us.languageCode == "en-US")
        #expect(us.instruction.contains("US English"))
        #expect(jp.languageCode == "ja-JP")
        #expect(jp.instruction.contains("日本語"))
        #expect(jp.prohibitedLanguage.contains { $0.contains("デトックス") })
    }

    @MainActor
    @Test func proResponseDetailContextIsCompleteButAntiFiller() async throws {
        let pro = AIResponseDetailContext.make(isPro: true, language: .unitedStates)
        let free = AIResponseDetailContext.make(isPro: false, language: .unitedStates)
        let japanesePro = AIResponseDetailContext.make(isPro: true, language: .japan)

        #expect(pro.tier == "pro")
        #expect(pro.requiredReasoningElements.contains { $0.contains("portion cues") })
        #expect(pro.requiredReasoningElements.contains { $0.contains("remaining uncertainty") })
        #expect(pro.antiFillerRules.contains { $0.contains("generic nutrition") })
        #expect(pro.healthTipLength == "1 to 2 sentences")
        #expect(free.tier == "standard")
        #expect(free.requiredReasoningElements.count < pro.requiredReasoningElements.count)
        #expect(japanesePro.instruction.contains("Proモード"))
    }

    @MainActor
    @Test func requestPayloadSeparatesFoodRecognitionProfileFromSpecialDietContext() async throws {
        let profile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 68,
            activeEnergy: 420,
            activityScenario: .lightWalking,
            activityDataSourceKind: .healthConnectedDevice,
            medicalDietMode: .diabetes,
            diabetesStage: .prediabetes
        )
        let payload = RequestPayload(
            image: "base64",
            language: AppLanguage.unitedStates.aiLanguageCode,
            userProfile: FoodRecognitionProfile(profile: profile),
            detectedText: "nutrition label",
            mealTime: MealTime.lunch.rawValue,
            communicationGuardrailContext: AICommunicationGuardrailContext.make(language: .unitedStates),
            responseDetailContext: AIResponseDetailContext.make(isPro: true, language: .unitedStates),
            foodSceneContext: FoodSceneAnalysisContext.make(language: .unitedStates),
            weightGuidanceContext: WeightGuidanceContext.make(profile: profile, language: .unitedStates),
            specialDietContext: SpecialDietRequestContext.make(for: profile, language: .unitedStates)
        )
        let json = try #require(String(data: JSONEncoder().encode(payload), encoding: .utf8))

        #expect(json.contains("\"foodSceneContext\""))
        #expect(json.contains("\"communicationGuardrailContext\""))
        #expect(json.contains("guaranteed safe"))
        #expect(json.contains("\"responseDetailContext\""))
        #expect(json.contains("\"tier\":\"pro\""))
        #expect(json.contains("portion cues"))
        #expect(json.contains("\"weightGuidanceContext\""))
        #expect(json.contains("\"goalDirection\":\"lose\""))
        #expect(json.contains("\"activityScenario\":\"lightWalking\""))
        #expect(json.contains("\"activityDataSourceKind\":\"healthConnectedDevice\""))
        #expect(json.contains("shared table spread"))
        #expect(json.contains("one full meal"))
        #expect(json.contains("\"specialDietContext\""))
        #expect(json.contains("\"mode\":\"diabetes\""))
        #expect(json.contains("\"diabetesStage\":\"prediabetes\""))
        #expect(!json.contains("\"medicalDietMode\""))
        #expect(!json.contains("\"ckdStage\""))
    }

    @MainActor
    @Test func legacyServerCompatibilityPromptPreservesOCRAndAddsCompositeInstructions() async throws {
        let profile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 68,
            medicalDietMode: .diabetes,
            diabetesStage: .gestational
        )
        let prompt = LegacyServerCompatibilityPrompt.detectedText(
            ocrText: "Nutrition label: rice bowl 450 kcal",
            foodSceneContext: FoodSceneAnalysisContext.make(language: .unitedStates),
            weightGuidanceContext: WeightGuidanceContext.make(profile: profile, language: .unitedStates),
            specialDietContext: SpecialDietRequestContext.make(for: profile, language: .unitedStates),
            communicationGuardrailContext: AICommunicationGuardrailContext.make(language: .unitedStates),
            responseDetailContext: AIResponseDetailContext.make(isPro: true, language: .unitedStates),
            language: .unitedStates
        )

        #expect(prompt.contains("OCR_TEXT"))
        #expect(prompt.contains("Nutrition label: rice bowl 450 kcal"))
        #expect(prompt.contains("CLIENT_COMPATIBILITY_INSTRUCTIONS"))
        #expect(prompt.contains("AI_COMMUNICATION_GUARDRAILS"))
        #expect(prompt.contains("Do not fill gaps with a story"))
        #expect(prompt.contains("AI_RESPONSE_DETAIL_COMPATIBILITY"))
        #expect(prompt.contains("No filler"))
        #expect(prompt.contains("portion cues"))
        #expect(prompt.contains("portionBasis"))
        #expect(prompt.contains("servingCount"))
        #expect(prompt.contains("shared table spread"))
        #expect(prompt.contains("items array"))
        #expect(prompt.contains("WEIGHT_GUIDANCE_COMPATIBILITY"))
        #expect(prompt.contains("not a generic template"))
        #expect(prompt.contains("SPECIAL_DIET_COMPATIBILITY"))
        #expect(prompt.contains("mode: diabetes, gestational"))
        #expect(prompt.contains("higher-carb foods"))
        #expect(prompt.contains("highly processed snacks"))
        #expect(prompt.contains("portion-aware reminder"))
        #expect(prompt.contains("oats"))
        #expect(prompt.contains("Do not infer it from the image"))
        #expect(prompt.contains("Prohibited: diagnosis"))
    }

    @MainActor
    @Test func legacyServerCompatibilityPromptWorksWithoutOCR() async throws {
        let prompt = LegacyServerCompatibilityPrompt.detectedText(
            ocrText: nil,
            foodSceneContext: FoodSceneAnalysisContext.make(language: .japan),
            weightGuidanceContext: nil,
            specialDietContext: nil,
            language: .japan
        )

        #expect(!prompt.contains("OCR_TEXT"))
        #expect(prompt.contains("CLIENT_COMPATIBILITY_INSTRUCTIONS"))
        #expect(prompt.contains("items"))
    }

    @MainActor
    @Test func foodSceneAnalysisContextCoversComplexCompositePhotos() async throws {
        let context = FoodSceneAnalysisContext.make(language: .unitedStates)

        #expect(context.supportedSceneTypes.contains("single food item"))
        #expect(context.supportedSceneTypes.contains("shared table spread"))
        #expect(context.supportedSceneTypes.contains("pile, bag, bowl, platter, or mixed-food heap"))
        #expect(context.instruction.contains("item by item"))
        #expect(context.portionPolicy.lowercased().contains("total visible food"))
        #expect(context.responseContract.contains("items array"))
    }

    @MainActor
    @Test func mealLoggingClassifierConfirmsNonMealFoodScenes() async throws {
        let singleMeal = CloudResponsePayload(
            foodList: "Chicken rice meal with vegetables",
            totalCaloriesMin: 620,
            totalCaloriesMax: 760,
            reasoning: "One plate meal with rice, protein, and vegetables",
            macros: nil,
            healthTip: nil,
            itemEstimates: [
                FoodEstimateItem(name: "rice", portionDescription: "one bowl", caloriesMin: 220, caloriesMax: 300, confidence: 0.82),
                FoodEstimateItem(name: "chicken", portionDescription: "one serving", caloriesMin: 250, caloriesMax: 320, confidence: 0.78)
            ]
        )
        #expect(!singleMeal.mealLogAssessment.requiresConfirmation)

        let bananaBunch = CloudResponsePayload(
            foodList: "一串香蕉",
            totalCaloriesMin: 520,
            totalCaloriesMax: 700,
            reasoning: "A bunch of bananas, not a prepared meal portion",
            macros: nil,
            healthTip: nil,
            itemEstimates: [
                FoodEstimateItem(name: "bananas", portionDescription: "one bunch, about 6 bananas", caloriesMin: 520, caloriesMax: 700, confidence: 0.86)
            ]
        )
        #expect(bananaBunch.mealLogAssessment == .confirm(.bulkQuantity))

        let sharedTable = CloudResponsePayload(
            foodList: "一桌菜，含炒飯、炸物、湯品與多盤配菜",
            totalCaloriesMin: 2_800,
            totalCaloriesMax: 4_200,
            reasoning: "Shared table spread with many dishes for multiple people",
            macros: nil,
            healthTip: nil,
            itemEstimates: []
        )
        #expect(sharedTable.mealLogAssessment == .confirm(.sharedSpread))
    }

    @MainActor
    @Test func diabetesAdvisorFlagsHighCarbSweetMeal() async throws {
        let payload = CloudResponsePayload(
            foodList: "Cake with sweet tea",
            totalCaloriesMin: 650,
            totalCaloriesMax: 780,
            reasoning: "Dessert and sweet drink with high carbohydrate load",
            macros: Macronutrients(protein: 8, carbs: 88, fat: 24),
            healthTip: nil
        )
        let profile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 70,
            medicalDietMode: .diabetes,
            diabetesStage: .insulinOrHypoglycemiaRisk
        )
        let advice = try #require(MedicalNutritionAdvisor.advice(for: payload, profile: profile, lang: .unitedStates))

        #expect(advice.riskLevel == .caution)
        #expect(advice.title.contains("Insulin"))
        #expect(advice.summary.lowercased().contains("do not use this app to adjust doses"))
        #expect(advice.focusItems.contains { $0.lowercased().contains("does not calculate insulin") })
        #expect(advice.sources.contains { $0.url.absoluteString.contains("cdc.gov") || $0.url.absoluteString.contains("diabetes.org") })
        #expect(advice.sources.allSatisfy { !$0.reference.isEmpty })
        #expect(advice.guardrails.contains { $0.lowercased().contains("does not diagnose") })
        #expect(advice.guardrails.contains { $0.lowercased().contains("does not measure glucose") })
    }

    @MainActor
    @Test func specialDietFoodAlertFlagsDiabetesFoodsWithLocalizedReminder() async throws {
        let payload = CloudResponsePayload(
            foodList: "白飯、蛋糕和奶茶",
            totalCaloriesMin: 720,
            totalCaloriesMax: 900,
            reasoning: "High carb meal with dessert and sweet drink",
            macros: Macronutrients(protein: 16, carbs: 108, fat: 26),
            healthTip: nil
        )
        let profile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 68,
            medicalDietMode: .diabetes,
            diabetesStage: .type2NonInsulin
        )
        let alert = try #require(SpecialDietFoodAlert.make(for: payload, profile: profile))

        #expect(alert.mode == .diabetes)
        #expect(alert.concerns == [.highSugarOrCarb])
        #expect(alert.title(lang: .traditionalChinese).contains("醣量"))
        #expect(alert.message(lang: .traditionalChinese).contains("份量"))
        #expect(alert.message(lang: .japan).contains("糖質"))
        #expect(alert.message(lang: .unitedStates).contains("portion-aware"))
    }

    @MainActor
    @Test func diabetesAdvisorFlagsHighlyProcessedCarbSnacks() async throws {
        let payload = CloudResponsePayload(
            foodList: "Potato chips",
            totalCaloriesMin: 150,
            totalCaloriesMax: 220,
            reasoning: "Highly processed starch snack with salty seasoning",
            macros: Macronutrients(protein: 2, carbs: 15, fat: 10),
            healthTip: nil,
            itemEstimates: [
                FoodEstimateItem(
                    name: "Potato chips",
                    portionDescription: "one small visible snack bag",
                    caloriesMin: 150,
                    caloriesMax: 220,
                    confidence: 0.74,
                    portionBasis: "package-style snack bag and visible chips",
                    servingCount: 1
                )
            ]
        )
        let profile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 68,
            medicalDietMode: .diabetes,
            diabetesStage: .prediabetes
        )
        let advice = try #require(MedicalNutritionAdvisor.advice(for: payload, profile: profile, lang: .unitedStates))
        let alert = try #require(SpecialDietFoodAlert.make(for: payload, profile: profile))

        #expect(advice.riskLevel == .caution)
        #expect(advice.summary.lowercased().contains("processed starch"))
        #expect(advice.focusItems.contains { $0.lowercased().contains("serving looks small") })
        #expect(advice.focusItems.contains { $0.contains("Potato chips") && $0.lowercased().contains("whole bag") })
        #expect(!advice.summary.lowercased().contains("balanced nutrition"))
        #expect(alert.concerns.contains(.refinedOrProcessedCarb))
    }

    @MainActor
    @Test func ckdAdvisorUsesAdvancedStageRiskSignals() async throws {
        let payload = CloudResponsePayload(
            foodList: "Instant ramen with banana and processed cheese",
            totalCaloriesMin: 520,
            totalCaloriesMax: 680,
            reasoning: "Instant soup, high sodium, potassium fruit, phosphorus additives",
            macros: Macronutrients(protein: 28, carbs: 72, fat: 18),
            healthTip: nil
        )
        let profile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 70,
            medicalDietMode: .chronicKidneyDisease,
            ckdStage: .stage4
        )
        let advice = try #require(MedicalNutritionAdvisor.advice(for: payload, profile: profile, lang: .unitedStates))

        #expect(advice.riskLevel == .alert)
        #expect(advice.focusItems.contains { $0.lowercased().contains("potassium") })
        #expect(advice.focusItems.contains { $0.lowercased().contains("phosphorus") })
        #expect(advice.sources.contains { $0.url.absoluteString.contains("kidney") || $0.url.absoluteString.contains("kdigo") })
        #expect(advice.sources.allSatisfy { !$0.reference.isEmpty })
    }

    @MainActor
    @Test func specialDietFoodAlertFlagsCKDHighPotassiumAndPhosphorusFoods() async throws {
        let payload = CloudResponsePayload(
            foodList: "香蕉、起司、加工香腸",
            totalCaloriesMin: 480,
            totalCaloriesMax: 680,
            reasoning: "Banana, cheese, and processed sausage may be potassium, phosphorus, and sodium concerns",
            macros: Macronutrients(protein: 30, carbs: 48, fat: 24),
            healthTip: nil
        )
        let profile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 68,
            medicalDietMode: .chronicKidneyDisease,
            ckdStage: .stage4
        )
        let alert = try #require(SpecialDietFoodAlert.make(for: payload, profile: profile))

        #expect(alert.mode == .chronicKidneyDisease)
        #expect(alert.riskLevel == .alert)
        #expect(alert.concerns.contains(.highPotassium))
        #expect(alert.concerns.contains(.highPhosphorus))
        #expect(alert.concerns.contains(.highSodium))
        #expect(alert.concerns.contains(.highProtein))
        #expect(alert.message(lang: .traditionalChinese).contains("攝取請適量"))
        #expect(alert.message(lang: .japan).contains("量に注意"))
        #expect(alert.message(lang: .unitedStates).contains("portion-aware"))
    }

    @MainActor
    @Test func ckdAdvisorFlagsProcessedSnacksAndOatsWithMineralWarnings() async throws {
        let payload = CloudResponsePayload(
            foodList: "洋芋片和燕麥片",
            totalCaloriesMin: 360,
            totalCaloriesMax: 520,
            reasoning: "Potato chips are a packaged processed starch snack, and oats can contribute phosphorus and potassium",
            macros: Macronutrients(protein: 8, carbs: 52, fat: 18),
            healthTip: nil,
            itemEstimates: [
                FoodEstimateItem(
                    name: "洋芋片",
                    portionDescription: "一小包可見份量",
                    caloriesMin: 150,
                    caloriesMax: 220,
                    confidence: 0.72,
                    portionBasis: "包裝零食與可見片數",
                    servingCount: 1
                ),
                FoodEstimateItem(
                    name: "燕麥片",
                    portionDescription: "約半碗",
                    caloriesMin: 210,
                    caloriesMax: 300,
                    confidence: 0.68,
                    portionBasis: "碗內可見體積",
                    servingCount: 1
                )
            ]
        )
        let profile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 68,
            medicalDietMode: .chronicKidneyDisease,
            ckdStage: .stage4
        )
        let advice = try #require(MedicalNutritionAdvisor.advice(for: payload, profile: profile, lang: .traditionalChinese))
        let alert = try #require(SpecialDietFoodAlert.make(for: payload, profile: profile))
        let focusText = advice.focusItems.joined(separator: " ")

        #expect(advice.riskLevel == .alert)
        #expect(focusText.contains("高度加工澱粉"))
        #expect(focusText.contains("燕麥"))
        #expect(focusText.contains("一小包"))
        #expect(focusText.contains("實際比例"))
        #expect(focusText.contains("磷"))
        #expect(alert.concerns.contains(.highSodium))
        #expect(alert.concerns.contains(.highPotassium))
        #expect(alert.concerns.contains(.highPhosphorus))
        #expect(advice.sources.contains { $0.url.absoluteString.contains("fdc.nal.usda.gov") })
    }

    @MainActor
    @Test func specialDietFoodAlertDoesNotAppearInStandardMode() async throws {
        let payload = CloudResponsePayload(
            foodList: "banana, cola, cake",
            totalCaloriesMin: 400,
            totalCaloriesMax: 560,
            reasoning: "High potassium, phosphorus, and sugar signals",
            macros: Macronutrients(protein: 10, carbs: 88, fat: 12),
            healthTip: nil
        )
        let profile = UserProfile(height: 170, currentWeight: 70, targetWeight: 68)

        #expect(SpecialDietFoodAlert.make(for: payload, profile: profile) == nil)
    }

    @MainActor
    @Test func ckdAdvisorProvidesStageSpecificPositiveGuidanceWithoutMedicalClaims() async throws {
        let payload = CloudResponsePayload(
            foodList: "Grilled fish, rice, vegetables",
            totalCaloriesMin: 430,
            totalCaloriesMax: 560,
            reasoning: "Home meal with visible rice, vegetables, and fish",
            macros: Macronutrients(protein: 22, carbs: 58, fat: 12),
            healthTip: nil
        )

        for stage in CKDStage.allCases {
            let profile = UserProfile(
                height: 170,
                currentWeight: 70,
                targetWeight: 70,
                medicalDietMode: .chronicKidneyDisease,
                ckdStage: stage
            )
            let advice = try #require(MedicalNutritionAdvisor.advice(for: payload, profile: profile, lang: .unitedStates))
            let text = ([advice.summary] + advice.focusItems + advice.guardrails).joined(separator: " ").lowercased()

            #expect(advice.title.contains(stage.label(lang: .unitedStates)))
            #expect(text.contains("sodium"))
            #expect(text.contains("does not diagnose"))
            #expect(text.contains("does not measure glucose"))
            #expect(!text.contains("prescribe"))
            #expect(!text.contains("dose"))
            #expect(advice.sources.allSatisfy { !$0.reference.isEmpty })
        }
    }

    @MainActor
    @Test func medicalAdvisorUsesMarketSpecificAuthoritativeSources() async throws {
        let payload = CloudResponsePayload(
            foodList: "ラーメンと加工肉",
            totalCaloriesMin: 520,
            totalCaloriesMax: 680,
            reasoning: "ラーメン、スープ、加工肉",
            macros: Macronutrients(protein: 26, carbs: 62, fat: 18),
            healthTip: nil
        )
        let japaneseProfile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 70,
            medicalDietMode: .chronicKidneyDisease,
            ckdStage: .stage4
        )
        let japaneseAdvice = try #require(MedicalNutritionAdvisor.advice(for: payload, profile: japaneseProfile, lang: .japan))

        #expect(japaneseAdvice.sources.contains { $0.url.absoluteString.contains("jsn.or.jp") || $0.url.absoluteString.contains("j-ka.or.jp") })
        #expect(japaneseAdvice.guardrails.contains { $0.contains("診断") })
        #expect(japaneseAdvice.sources.allSatisfy { !$0.reference.isEmpty })

        let taiwanProfile = UserProfile(
            height: 170,
            currentWeight: 70,
            targetWeight: 70,
            medicalDietMode: .diabetes
        )
        let taiwanAdvice = try #require(MedicalNutritionAdvisor.advice(for: payload, profile: taiwanProfile, lang: .traditionalChinese))

        #expect(taiwanAdvice.sources.contains { $0.url.absoluteString.contains("hpa.gov.tw") || $0.url.absoluteString.contains("diabetes.org.tw") })
        #expect(taiwanAdvice.sources.allSatisfy { !$0.reference.isEmpty })
    }

    @MainActor
    @Test func medicalSourcesPrioritizeLocalAuthoritiesBeforeInternationalSupport() async throws {
        func localizedSourcesAppearBeforeSupplemental(_ sources: [MedicalAuthoritySource]) -> Bool {
            var sawSupplemental = false
            for source in sources {
                if source.priority == .supplemental {
                    sawSupplemental = true
                }
                if sawSupplemental && source.priority == .localizedPrimary {
                    return false
                }
            }
            return true
        }

        let payload = CloudResponsePayload(
            foodList: "Rice, vegetables, grilled fish",
            totalCaloriesMin: 430,
            totalCaloriesMax: 560,
            reasoning: "Balanced meal with starch, vegetables, and protein",
            macros: Macronutrients(protein: 22, carbs: 58, fat: 12),
            healthTip: nil
        )

        let taiwanAdvice = try #require(MedicalNutritionAdvisor.advice(
            for: payload,
            profile: UserProfile(height: 170, currentWeight: 70, targetWeight: 70, medicalDietMode: .diabetes, diabetesStage: .prediabetes),
            lang: .traditionalChinese
        ))
        #expect(taiwanAdvice.sources.first?.priority == .localizedPrimary)
        #expect(taiwanAdvice.sources.first?.url.absoluteString.contains("hpa.gov.tw") == true)
        #expect(taiwanAdvice.sources.contains { $0.priority == .supplemental && $0.url.absoluteString.contains("diabetes.org") })
        #expect(localizedSourcesAppearBeforeSupplemental(taiwanAdvice.sources))

        let japanAdvice = try #require(MedicalNutritionAdvisor.advice(
            for: payload,
            profile: UserProfile(height: 170, currentWeight: 70, targetWeight: 70, medicalDietMode: .chronicKidneyDisease, ckdStage: .stage3b),
            lang: .japan
        ))
        #expect(japanAdvice.sources.first?.priority == .localizedPrimary)
        #expect(japanAdvice.sources.first?.url.absoluteString.contains("jsn.or.jp") == true)
        #expect(japanAdvice.sources.contains { $0.priority == .supplemental && $0.url.absoluteString.contains("kdigo") })
        #expect(localizedSourcesAppearBeforeSupplemental(japanAdvice.sources))

        let englishAdvice = try #require(MedicalNutritionAdvisor.advice(
            for: payload,
            profile: UserProfile(height: 170, currentWeight: 70, targetWeight: 70, medicalDietMode: .diabetes),
            lang: .unitedStates
        ))
        #expect(englishAdvice.sources.first?.priority == .localizedPrimary)
        #expect(englishAdvice.sources.contains { $0.priority == .localizedPrimary && $0.url.absoluteString.contains("nice.org.uk") })
        #expect(englishAdvice.sources.contains { $0.priority == .supplemental && ($0.url.absoluteString.contains("hpa.gov.tw") || $0.url.absoluteString.contains("dmic.jihs.go.jp")) })
        #expect(localizedSourcesAppearBeforeSupplemental(englishAdvice.sources))
    }

}
