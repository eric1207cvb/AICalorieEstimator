import SwiftUI
import PhotosUI
import RevenueCat
import Charts
import HealthKit
import StoreKit
import UIKit

// MARK: - [Client v9.34] Main View (Final UI: Horizontal Gender Row)
struct ContentView: View {
    @Binding var selectedLanguage: AppLanguage
    @StateObject private var viewModel = CalorieEstimatorViewModel()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedUIImage: UIImage? = nil
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var isShowingCamera = false
    @State private var cameraUnavailableAlert: Bool = false
    @State private var showManageSubscriptions: Bool = false
    @State private var isShowingSubscriptionInfo: Bool = false
    @State private var isEditingProfile = false
    @State private var didAutoExpandProfile = false
    @State private var pendingMealLogPayload: CloudResponsePayload? = nil
    @State private var isShowingMealLogConfirmation = false
    @State private var isShowingDeleteMealLogConfirmation = false

    var todayCaloriesIntake: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return viewModel.weeklyRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.totalCalories ?? 0
    }

    private var hasUnlimitedAnalysisAccess: Bool {
        #if DEBUG
        return viewModel.isProUser || viewModel.debugBypassPro
        #else
        return viewModel.isProUser
        #endif
    }

    var canAnalyze: Bool {
        return hasUnlimitedAnalysisAccess || viewModel.remainingFreeUsage > 0
    }

    private var profileNeedsSetup: Bool {
        viewModel.height <= 0 || viewModel.currentWeight <= 0 || viewModel.targetWeight <= 0 || viewModel.gender == .notSet
    }

    private var shouldUseSingleColumnLayout: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    private var phonePhotoHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 340 : 280
    }

    private var tabletPhotoHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 380 : 340
    }

    var body: some View {
        ZStack {
            if !viewModel.isAppLoading {
                NavigationStack {
                    ScrollView { mainContent }
                        .navigationTitle(TranslationManager.get("app.title", lang: selectedLanguage))
                        .background(Color(UIColor.systemGroupedBackground))
                        .toolbar {
                            ToolbarItemGroup(placement: .topBarTrailing) {
                                LanguageSwitcherButton(selectedLanguage: $selectedLanguage)
                                Menu {
                                    Button { showManageSubscriptions = true } label: { Label(TranslationManager.get("menu.manage_subscription", lang: selectedLanguage), systemImage: "creditcard") }
                                    Button { viewModel.restorePurchases() } label: { Label(TranslationManager.get("menu.restore_purchases", lang: selectedLanguage), systemImage: "arrow.clockwise") }
                                    #if DEBUG
                                    Toggle("Dev: Bypass Pro", isOn: $viewModel.debugBypassPro)
                                    #endif
                                } label: { Image(systemName: "gearshape").foregroundStyle(.primary) }
                            }
                        }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }

            if viewModel.isAppLoading {
                LoadingSplashView(language: selectedLanguage)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    .zIndex(1)
            }
        }
        .id(selectedLanguage)
        .environment(\.locale, Locale(identifier: selectedLanguage.localeIdentifier))
        .onAppear(perform: autoExpandProfileEditorIfNeeded)
        .onChange(of: viewModel.isAppLoading) { _, _ in
            autoExpandProfileEditorIfNeeded()
        }
        .sheet(isPresented: $isShowingCamera) { CameraPickerView(selectedImage: $selectedUIImage) }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                    self.selectedUIImage = uiImage.fixOrientation()
                }
            }
        }
        .onChange(of: selectedUIImage) { _, newImage in
            if let uiImage = newImage {
                if canAnalyze {
                    viewModel.handleImageSelection(uiImage)
                    Task { await viewModel.analyzeImage(uiImage: uiImage, language: selectedLanguage) }
                } else {
                    selectedUIImage = nil
                    viewModel.isShowingPaywall = true
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingPaywall) {
            if let offering = viewModel.offerings?.current {
                PaywallView(
                    offering: offering,
                    language: selectedLanguage,
                    onCustomerInfoUpdated: { customerInfo in
                        viewModel.applyCustomerInfo(customerInfo)
                    },
                    onDebugSimulatorUnlock: {
                        #if DEBUG
                        viewModel.enableSimulatorPurchaseTestingAccess()
                        #endif
                    }
                )
            }
            else {
                VStack(spacing: 16) {
                    ProgressView()
                        .onAppear { viewModel.fetchOfferings() }

                    #if DEBUG && targetEnvironment(simulator)
                    Button {
                        viewModel.enableSimulatorPurchaseTestingAccess()
                    } label: {
                        Label(TranslationManager.get("paywall.simulator_unlock", lang: selectedLanguage), systemImage: "testtube.2")
                    }
                    .buttonStyle(.bordered)

                    Text(TranslationManager.get("paywall.simulator_unlock_note", lang: selectedLanguage))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    #endif
                }
                .padding()
            }
        }
        .sheet(isPresented: $isShowingSubscriptionInfo) { SubscriptionInfoView(offerings: viewModel.offerings, language: selectedLanguage) }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .onChange(of: showManageSubscriptions) { _, isShowing in
            if !isShowing {
                viewModel.checkSubscriptionStatus(forceRefresh: true)
            }
        }
        .alert(TranslationManager.get("alert.error_title", lang: selectedLanguage), isPresented: $cameraUnavailableAlert) {
            Button(TranslationManager.get("alert.ok", lang: selectedLanguage)) {}
        } message: {
            Text(TranslationManager.get("alert.camera_required", lang: selectedLanguage))
        }
        .alert(TranslationManager.get("meal_log.confirm_title", lang: selectedLanguage), isPresented: $isShowingMealLogConfirmation, presenting: pendingMealLogPayload) { payload in
            Button(TranslationManager.get("meal_log.confirm_log", lang: selectedLanguage)) {
                viewModel.logCurrentMeal(payload: payload, language: selectedLanguage)
                pendingMealLogPayload = nil
            }
            Button(TranslationManager.get("meal_log.cancel", lang: selectedLanguage), role: .cancel) {
                pendingMealLogPayload = nil
            }
        } message: { payload in
            Text(payload.mealLogAssessment.confirmationMessage(calories: payload.averageSafeCalories, language: selectedLanguage))
        }
        .alert(TranslationManager.get("meal_log.delete_title", lang: selectedLanguage), isPresented: $isShowingDeleteMealLogConfirmation) {
            Button(TranslationManager.get("meal_log.delete_confirm", lang: selectedLanguage), role: .destructive) {
                viewModel.deleteCurrentMealLog()
            }
            Button(TranslationManager.get("meal_log.cancel", lang: selectedLanguage), role: .cancel) {}
        } message: {
            Text(TranslationManager.get("meal_log.delete_message", lang: selectedLanguage))
        }
    }

    var mainContent: some View {
        let profile = viewModel.currentUserProfile
        let limit = profile.dailyCalorieLimit

        return Group {
            if shouldUseSingleColumnLayout {
                phoneMainContent(profile: profile, limit: limit)
            } else {
                ViewThatFits(in: .horizontal) {
                    tabletMainContent(profile: profile, limit: limit)
                    phoneMainContent(profile: profile, limit: limit)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func tabletMainContent(profile: UserProfile, limit: Int) -> some View {
        HStack(alignment: .top, spacing: 24) {
            overviewColumn(profile: profile, limit: limit)
                .frame(minWidth: 360, maxWidth: 520)

            analysisColumn(profile: profile)
                .frame(minWidth: 360, maxWidth: 520)
        }
        .frame(maxWidth: 1100)
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    private func phoneMainContent(profile: UserProfile, limit: Int) -> some View {
        VStack(spacing: 20) {
            statusSection
                .padding(.horizontal)
                .padding(.top, 10)

            profileSection
                .padding(.horizontal)

            CalorieRingView(intake: todayCaloriesIntake, limit: limit, language: selectedLanguage)
                .padding(.horizontal)

            SmartCoachView(profile: profile, todayCalories: todayCaloriesIntake, language: selectedLanguage)
                .padding(.horizontal)

            watchSection
                .padding(.horizontal)

            weeklySection(limit: limit)
                .padding(.horizontal)

            photoAnalysisSection(profile: profile, height: phonePhotoHeight)
                .padding(.horizontal)

            resultArea(profile: profile)
                .padding(.horizontal)

            footerSection
                .padding(.bottom)
        }
        .padding(.vertical)
    }

    private func overviewColumn(profile: UserProfile, limit: Int) -> some View {
        VStack(spacing: 18) {
            statusSection
            profileSection
            CalorieRingView(intake: todayCaloriesIntake, limit: limit, language: selectedLanguage)
            SmartCoachView(profile: profile, todayCalories: todayCaloriesIntake, language: selectedLanguage)
            watchSection
            weeklySection(limit: limit)
            footerSection
        }
    }

    private func analysisColumn(profile: UserProfile) -> some View {
        VStack(spacing: 18) {
            photoAnalysisSection(profile: profile, height: tabletPhotoHeight)
            resultArea(profile: profile)
        }
    }

    private func specialDietAlert(for profile: UserProfile) -> SpecialDietFoodAlert? {
        guard case .success(let payload) = viewModel.viewState else { return nil }
        return SpecialDietFoodAlert.make(for: payload, profile: profile)
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            SubscriptionStatusBanner(
                isPro: hasUnlimitedAnalysisAccess,
                remainingCount: viewModel.remainingFreeUsage,
                language: selectedLanguage,
                onUpgrade: { viewModel.isShowingPaywall = true }
            )
            Button(action: { Task { await viewModel.healthCheck() } }) {
                ServerStatusIndicator(status: viewModel.serverStatus, language: selectedLanguage)
            }
            .buttonStyle(.plain)
        }
    }

    private var watchSection: some View {
        WatchHealthDashboardView(
            snapshot: viewModel.watchHealthSnapshot,
            syncState: viewModel.healthSyncState,
            language: selectedLanguage,
            onSync: { viewModel.syncHealthData() }
        )
    }

    private func photoAnalysisSection(profile: UserProfile, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(TranslationManager.get("photo.section_title", lang: selectedLanguage), systemImage: "camera.viewfinder")
                .font(.headline)
                .foregroundStyle(.primary)

            ImageSelectionView(
                image: viewModel.selectedImage,
                language: selectedLanguage,
                height: height,
                specialDietAlert: specialDietAlert(for: profile)
            )

            actionButtons
        }
    }

    private var profileSection: some View {
        HealthDashboardView(
            height: $viewModel.height,
            weight: $viewModel.currentWeight,
            target: $viewModel.targetWeight,
            gender: $viewModel.gender,
            activityScenario: $viewModel.activityScenario,
            medicalDietMode: $viewModel.medicalDietMode,
            diabetesStage: $viewModel.diabetesStage,
            ckdStage: $viewModel.ckdStage,
            goalStartWeight: viewModel.goalStartWeight,
            stepCount: viewModel.stepCount,
            basalEnergy: viewModel.basalEnergy,
            activeEnergy: viewModel.watchHealthSnapshot.activeEnergy,
            todayCalories: todayCaloriesIntake,
            language: selectedLanguage,
            isExpanded: $isEditingProfile,
            onSync: { viewModel.syncHealthData() }
        )
    }

    @ViewBuilder
    private func weeklySection(limit: Int) -> some View {
        if !viewModel.weeklyRecords.isEmpty {
            WeeklyProgressCard(records: viewModel.weeklyRecords, dailyLimit: limit, language: selectedLanguage)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 10) {
                takePhotoControl
                albumControl
            }
        } else {
            HStack(spacing: 12) {
                takePhotoControl
                albumControl
            }
        }
    }

    private var takePhotoControl: some View {
        Button {
            if canAnalyze {
                Task { await ensureCameraAuthorized() ? (isShowingCamera = true) : (cameraUnavailableAlert = true) }
            } else {
                viewModel.isShowingPaywall = true
            }
        } label: {
            CaptureControlLabel(
                title: TranslationManager.get("button.take_photo", lang: selectedLanguage),
                icon: "camera.fill",
                tint: .green,
                isPrimary: true
            )
        }
        .buttonStyle(.plain)
        .opacity(canAnalyze ? 1.0 : 0.6)
    }

    private var albumControl: some View {
        ZStack {
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                CaptureControlLabel(
                    title: TranslationManager.get("button.select_album", lang: selectedLanguage),
                    icon: "photo.on.rectangle.angled",
                    tint: .blue,
                    isPrimary: false
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAnalyze)

            if !canAnalyze {
                Button {
                    viewModel.isShowingPaywall = true
                } label: {
                    CaptureControlLabel(
                        title: TranslationManager.get("button.select_album", lang: selectedLanguage),
                        icon: "photo.on.rectangle.angled",
                        tint: .blue,
                        isPrimary: false
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(canAnalyze ? 1.0 : 0.6)
    }

    @ViewBuilder
    private func resultArea(profile: UserProfile) -> some View {
        VStack {
            switch viewModel.viewState {
            case .empty:
                EmptyView()
            case .loading(let progress):
                VStack(spacing: 16) {
                    SkeletonView().frame(height: 200).cornerRadius(12)
                    AnalysisProgressView(progress: progress)
                }
                .padding()
            case .success(let payload):
                VStack(spacing: 16) {
                    ResultView(data: payload, profile: profile, language: selectedLanguage)
                    Button(action: {
                        handleMealLogTap(payload)
                    }) {
                        HStack {
                            Image(systemName: viewModel.isCurrentMealLogged ? "checkmark.circle.fill" : "fork.knife")
                            Text(TranslationManager.get(viewModel.isCurrentMealLogged ? "button.logged" : "button.add_to_log", lang: selectedLanguage))
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isCurrentMealLogged ? Color.gray : Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isCurrentMealLogged)
                    .padding(.horizontal)

                    if viewModel.currentMealLogEntry != nil {
                        Button(role: .destructive) {
                            isShowingDeleteMealLogConfirmation = true
                        } label: {
                            Label(TranslationManager.get("button.delete_log", lang: selectedLanguage), systemImage: "trash")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)
                    }
                }
            case .error(let msg):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(msg)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    private func handleMealLogTap(_ payload: CloudResponsePayload) {
        if payload.mealLogAssessment.requiresConfirmation {
            pendingMealLogPayload = payload
            isShowingMealLogConfirmation = true
        } else {
            viewModel.logCurrentMeal(payload: payload, language: selectedLanguage)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            DataSourcesButton(language: selectedLanguage)
                .padding(.horizontal)
            Button(action: { isShowingSubscriptionInfo = true }) {
                Text(TranslationManager.get("footer.privacy_terms", lang: selectedLanguage))
                    .font(.caption)
                    .underline()
                    .foregroundStyle(.secondary)
            }
            DisclaimerButton(renderAsCard: false, language: selectedLanguage)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    func ensureCameraAuthorized() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized { return true }
        if status == .notDetermined { return await AVCaptureDevice.requestAccess(for: .video) }
        return false
    }

    private func autoExpandProfileEditorIfNeeded() {
        guard !didAutoExpandProfile, !viewModel.isAppLoading, profileNeedsSetup else { return }
        didAutoExpandProfile = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isEditingProfile = true
        }
    }
}

struct LanguageSwitcherButton: View {
    @Binding var selectedLanguage: AppLanguage

    var body: some View {
        Menu {
            Section(TranslationManager.get("language.menu", lang: selectedLanguage)) {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        selectedLanguage = language
                    } label: {
                        Label(
                            language.displayName,
                            systemImage: selectedLanguage == language ? "checkmark.circle.fill" : "circle"
                        )
                    }
                }
            }
        } label: {
            Label {
                Text(selectedLanguage.compactDisplayName)
                    .font(.caption.weight(.semibold))
            } icon: {
                Image(systemName: "globe")
            }
        }
        .accessibilityLabel(TranslationManager.get("language.menu", lang: selectedLanguage))
    }
}

// MARK: - [Fix] HealthDashboardView: Horizontal Gender Row

struct HealthDashboardView: View {
    @Binding var height: Double
    @Binding var weight: Double
    @Binding var target: Double
    @Binding var gender: UserGender
    @Binding var activityScenario: ActivityScenario
    @Binding var medicalDietMode: MedicalDietMode
    @Binding var diabetesStage: DiabetesStage
    @Binding var ckdStage: CKDStage
    var goalStartWeight: Double
    var stepCount: Int
    var basalEnergy: Double
    var activeEnergy: Double
    var todayCalories: Int
    var language: AppLanguage
    @Binding var isExpanded: Bool
    var onSync: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var profile: UserProfile { UserProfile(height: height, currentWeight: weight, targetWeight: target, stepCount: stepCount, basalEnergy: basalEnergy, gender: gender, activeEnergy: activeEnergy, activityScenario: activityScenario, medicalDietMode: medicalDietMode, diabetesStage: diabetesStage, ckdStage: ckdStage) }

    // UI Helper for numeric inputs
    private func inputContainer<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            content()
                .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 56 : 44)
                .padding(.horizontal, 12)
                .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 8 : 0)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
        }
    }

    private func menuRow<Content: View>(title: String, icon: String, value: String, @ViewBuilder content: () -> Content) -> some View {
        Menu {
            content()
        } label: {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
        }
    }

    private func medicalModeIcon(_ mode: MedicalDietMode) -> String {
        switch mode {
        case .standard: return "fork.knife.circle.fill"
        case .diabetes: return "drop.fill"
        case .chronicKidneyDisease: return "cross.case.fill"
        }
    }

    private func medicalModeTint(_ mode: MedicalDietMode) -> Color {
        switch mode {
        case .standard: return .green
        case .diabetes: return .orange
        case .chronicKidneyDisease: return .blue
        }
    }

    private func medicalModeButton(_ mode: MedicalDietMode) -> some View {
        let isSelected = medicalDietMode == mode
        let tint = medicalModeTint(mode)

        return Button {
            medicalDietMode = mode
        } label: {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : medicalModeIcon(mode))
                    .font(.headline)
                Text(mode.label(lang: language))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 88 : 70)
            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 8 : 0)
            .foregroundStyle(isSelected ? tint : .secondary)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? tint.opacity(0.14) : Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? tint.opacity(0.7) : Color.gray.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var medicalModeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(TranslationManager.get("profile.medical_mode", lang: language), systemImage: "cross.case.fill")
                .font(.subheadline)
                .foregroundStyle(.primary)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    ForEach(MedicalDietMode.allCases) { mode in
                        medicalModeButton(mode)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(MedicalDietMode.allCases) { mode in
                        medicalModeButton(mode)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func sectionHeader(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var basicProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: TranslationManager.get("profile.basic_section", lang: language),
                subtitle: TranslationManager.get("profile.basic_hint", lang: language),
                icon: "person.text.rectangle",
                tint: .blue
            )
            measurementInputs
            quickGoalPresetSelector
            genderMenu
            activityScenarioSelector
        }
    }

    private var measurementInputs: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 12)], spacing: 12) {
            inputContainer(label: TranslationManager.get("profile.height", lang: language)) {
                NumericMeasurementField(value: $height, unit: "cm")
            }
            inputContainer(label: TranslationManager.get("profile.weight", lang: language)) {
                NumericMeasurementField(value: $weight, unit: "kg")
            }
            inputContainer(label: TranslationManager.get("health.weight_goal", lang: language)) {
                NumericMeasurementField(value: $target, unit: "kg")
            }
        }
    }

    private var genderMenu: some View {
        Menu {
            ForEach(UserGender.allCases, id: \.self) { g in
                Button(action: { gender = g }) {
                    if gender == g { Label(g.label(lang: language), systemImage: "checkmark") }
                    else { Text(g.label(lang: language)) }
                }
            }
        } label: {
            HStack {
                Label(TranslationManager.get("profile.gender", lang: language), systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(gender.label(lang: language))
                    .font(.body)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
        }
    }

    private var quickGoalPresetSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: TranslationManager.get("profile.quick_goal", lang: language),
                subtitle: TranslationManager.get("profile.quick_goal_hint", lang: language),
                icon: "target",
                tint: .orange
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 10)], spacing: 10) {
                ForEach(WeightGoalPreset.allCases) { preset in
                    weightGoalPresetButton(preset)
                }
            }

            if weight <= 0 {
                Text(TranslationManager.get("profile.weight_first_hint", lang: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func weightGoalPresetButton(_ preset: WeightGoalPreset) -> some View {
        let proposedTarget = preset.targetWeight(from: weight)
        let isSelected = weight > 0 && abs(target - proposedTarget) < 0.05

        return Button {
            guard proposedTarget > 0 else { return }
            target = proposedTarget
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                    Text(preset.label(lang: language))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .minimumScaleFactor(0.75)
                }
                Text(weight > 0 ? "\(String(format: "%.1f", proposedTarget)) kg" : preset.detail(lang: language))
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .orange : .secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 92 : 70, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .orange : .primary)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.orange.opacity(0.13) : Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange.opacity(0.65) : Color.gray.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(weight <= 0)
        .opacity(weight <= 0 ? 0.65 : 1)
    }

    private var activityScenarioSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 10)], spacing: 10) {
                ForEach(ActivityScenario.allCases) { scenario in
                    activityScenarioButton(scenario)
                }
            }
        }
    }

    private func activityScenarioButton(_ scenario: ActivityScenario) -> some View {
        let isSelected = activityScenario == scenario

        return Button {
            activityScenario = scenario
        } label: {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : scenario.iconName)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .green : .secondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.label(lang: language))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .minimumScaleFactor(0.78)
                    Text(scenario.detail(lang: language))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 98 : 76, alignment: .topLeading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.green.opacity(0.12) : Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.green.opacity(0.65) : Color.gray.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var estimateSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                HealthStatItem(title: "BMI", value: profile.bmi, icon: "scalemass.fill", color: .purple)
                HealthStatItem(title: TranslationManager.get("health.maintenance_calories", lang: language), value: "\(profile.estimatedMaintenanceCalories)", icon: "gauge.with.dots.needle.67percent", color: .orange)
                HealthStatItem(title: TranslationManager.get("health.daily_target", lang: language), value: "\(profile.dailyCalorieLimit)", icon: "flame.fill", color: .pink)
            }
            goalProgressSection
        }
    }

    @ViewBuilder
    private var goalProgressSection: some View {
        if target > 0, weight > 0, abs(target - weight) >= 0.1 {
            let progress = WeightGoalProgress.progress(startWeight: goalStartWeight, currentWeight: weight, targetWeight: target)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(TranslationManager.get("health.goal_progress", lang: language)): \(Int((progress * 100).rounded()))%")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(target < weight ? .green : .blue)
                    Spacer()
                    Text(TranslationManager.get("health.to_target", lang: language, args: [abs(target - weight)]))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Image(systemName: target < weight ? "arrow.down.right" : "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2)).frame(height: 8)
                        Capsule().fill(target < weight ? Color.green : Color.blue)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.top, 2)
        }
    }

    private var healthSyncSection: some View {
        Button(action: onSync) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(TranslationManager.get("profile.sync_health", lang: language))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(TranslationManager.get("profile.sync_health_hint", lang: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.blue.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var specialDietSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            medicalModeSelector

            if medicalDietMode == .diabetes {
                menuRow(
                    title: TranslationManager.get("profile.diabetes_stage", lang: language),
                    icon: "drop.fill",
                    value: diabetesStage.label(lang: language)
                ) {
                    ForEach(DiabetesStage.allCases) { stage in
                        Button(action: { diabetesStage = stage }) {
                            if diabetesStage == stage { Label(stage.label(lang: language), systemImage: "checkmark") }
                            else { Text(stage.label(lang: language)) }
                        }
                    }
                }
            }

            if medicalDietMode == .chronicKidneyDisease {
                menuRow(
                    title: TranslationManager.get("profile.ckd_stage", lang: language),
                    icon: "drop.triangle.fill",
                    value: ckdStage.label(lang: language)
                ) {
                    ForEach(CKDStage.allCases) { stage in
                        Button(action: { ckdStage = stage }) {
                            if ckdStage == stage { Label(stage.label(lang: language), systemImage: "checkmark") }
                            else { Text(stage.label(lang: language)) }
                        }
                    }
                }
            }

            if medicalDietMode != .standard {
                Text(TranslationManager.get("profile.medical_note", lang: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    Image(systemName: "pencil.circle.fill").font(.title2).foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TranslationManager.get("dash.edit_title", lang: language))
                            .font(.headline).foregroundStyle(.primary)
                        Text(TranslationManager.get("dash.edit_subtitle", lang: language))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").rotationEffect(.degrees(isExpanded ? 90 : 0)).foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
            }

            if isExpanded {
                Divider()
                VStack(spacing: 18) {
                    basicProfileSection
                    estimateSummarySection
                    healthSyncSection
                    specialDietSettingsSection
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - [Components] Helpers

struct NumericMeasurementField: View {
    @Binding var value: Double
    let unit: String
    var placeholder: String = "0"
    var maximumFractionDigits: Int = 1
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 8) {
            UIKitNumericTextField(
                value: $value,
                placeholder: placeholder,
                maximumFractionDigits: maximumFractionDigits
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 44 : 32)

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

struct UIKitNumericTextField: UIViewRepresentable {
    @Binding var value: Double
    var placeholder: String
    var maximumFractionDigits: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = NumericOnlyUITextField(frame: .zero)
        textField.maximumFractionDigits = maximumFractionDigits
        textField.delegate = context.coordinator
        textField.keyboardType = .decimalPad
        textField.placeholder = placeholder
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textAlignment = .left
        textField.textColor = .label
        textField.tintColor = .systemBlue
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.smartInsertDeleteType = .no
        textField.textContentType = nil
        textField.clearButtonMode = .whileEditing
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        textField.text = NumericInputSanitizer.displayString(for: value, maximumFractionDigits: maximumFractionDigits)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        uiView.placeholder = placeholder
        uiView.keyboardType = .decimalPad
        uiView.font = .preferredFont(forTextStyle: .body)
        (uiView as? NumericOnlyUITextField)?.maximumFractionDigits = maximumFractionDigits

        guard !uiView.isFirstResponder else { return }
        let displayText = NumericInputSanitizer.displayString(for: value, maximumFractionDigits: maximumFractionDigits)
        if uiView.text != displayText {
            uiView.text = displayText
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIKitNumericTextField

        init(parent: UIKitNumericTextField) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard !string.isEmpty else { return true }
            return string.allSatisfy { NumericInputSanitizer.isAllowedInputCharacter($0) }
        }

        @objc func editingChanged(_ textField: UITextField) {
            let rawText = textField.text ?? ""
            let sanitized = NumericInputSanitizer.sanitizedDecimalString(rawText, maximumFractionDigits: parent.maximumFractionDigits)
            if sanitized != rawText {
                textField.text = sanitized
            }

            if sanitized.isEmpty {
                parent.value = 0
            } else if let parsed = Double(sanitized), parsed.isFinite {
                parent.value = parsed
            }
        }
    }
}

final class NumericOnlyUITextField: UITextField {
    var maximumFractionDigits: Int = 1

    override var textInputMode: UITextInputMode? {
        let activeModes = UITextInputMode.activeInputModes
        return activeModes.first { $0.primaryLanguage == "en-US" }
            ?? activeModes.first { $0.primaryLanguage?.hasPrefix("en") == true }
            ?? super.textInputMode
    }

    override func insertText(_ text: String) {
        if text.allSatisfy({ NumericInputSanitizer.isAllowedInputCharacter($0) }) {
            super.insertText(text)
        } else {
            let sanitized = NumericInputSanitizer.sanitizedDecimalString(text, maximumFractionDigits: maximumFractionDigits)
            guard !sanitized.isEmpty else { return }
            super.insertText(sanitized)
        }
        sanitizeVisibleTextAndNotify()
    }

    override func paste(_ sender: Any?) {
        guard let pastedText = UIPasteboard.general.string else {
            super.paste(sender)
            return
        }
        let sanitized = NumericInputSanitizer.sanitizedDecimalString(pastedText, maximumFractionDigits: maximumFractionDigits)
        guard !sanitized.isEmpty else { return }
        super.insertText(sanitized)
        sanitizeVisibleTextAndNotify()
    }

    private func sanitizeVisibleTextAndNotify() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let sanitized = NumericInputSanitizer.sanitizedDecimalString(self.text ?? "", maximumFractionDigits: self.maximumFractionDigits)
            if self.text != sanitized {
                self.text = sanitized
            }
            self.sendActions(for: .editingChanged)
        }
    }
}

enum NumericInputSanitizer {
    private static let decimalSeparators: Set<Character> = [".", ",", "．", "。"]

    static func isAllowedInputCharacter(_ character: Character) -> Bool {
        character.wholeNumberValue != nil || decimalSeparators.contains(character)
    }

    static func sanitizedDecimalString(_ rawText: String, maximumFractionDigits: Int) -> String {
        var result = ""
        var hasDecimalSeparator = false
        var fractionDigits = 0
        let fractionLimit = max(0, maximumFractionDigits)

        for character in rawText {
            if let wholeNumberValue = character.wholeNumberValue {
                if hasDecimalSeparator {
                    guard fractionDigits < fractionLimit else { continue }
                    fractionDigits += 1
                }
                result.append(String(wholeNumberValue))
            } else if decimalSeparators.contains(character), fractionLimit > 0, !hasDecimalSeparator {
                hasDecimalSeparator = true
                result.append(result.isEmpty ? "0." : ".")
            }
        }

        return result
    }

    static func displayString(for value: Double, maximumFractionDigits: Int) -> String {
        guard value > 0, value.isFinite else { return "" }
        let rounded = value.rounded()
        if abs(value - rounded) < 0.000_001 {
            return String(Int(rounded))
        }
        return String(format: "%.\(maximumFractionDigits)f", value)
    }
}

struct CalorieRingView: View {
    let intake: Int; let limit: Int; let language: AppLanguage
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title2) private var ringSize: CGFloat = 100
    var percentage: Double { min(Double(intake) / Double(limit), 1.0) }
    var isOver: Bool { intake > limit }
    var remaining: Int { limit - intake }
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 30) {
                ringGraphic
                ringDetails
            }
            VStack(spacing: 16) {
                ringGraphic
                ringDetails
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private var ringGraphic: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 15)
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: isOver ? [.red, .orange] : [.green, .mint]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + (percentage * 360))
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 1.0), value: percentage)
            VStack(spacing: 2) {
                Text(isOver ? TranslationManager.get("ring.status_over", lang: language) : TranslationManager.get("ring.status_remain", lang: language))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.8)
                Text("\(abs(remaining))")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(isOver ? .red : .primary)
                    .minimumScaleFactor(0.7)
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    private var ringDetails: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .center : .leading, spacing: 12) {
            StatRow(icon: "flame.fill", color: .orange, title: TranslationManager.get("ring.target_title", lang: language), value: "\(limit)")
            StatRow(icon: "fork.knife", color: .blue, title: TranslationManager.get("ring.intake_title", lang: language), value: "\(intake)")
            HStack(spacing: 4) {
                Image(systemName: isOver ? "figure.walk" : "checkmark.seal.fill")
                Text(isOver ? TranslationManager.get("ring.advice_over", lang: language) : TranslationManager.get("ring.advice_good", lang: language))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isOver ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
            .foregroundColor(isOver ? .red : .green)
            .cornerRadius(8)
        }
    }
}

struct SmartCoachView: View {
    let profile: UserProfile; let todayCalories: Int; let language: AppLanguage
    var insight: InsightResult { HealthCoach.generateInsight(profile: profile, todayCalories: todayCalories, lang: language) }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: "graduationcap.fill").foregroundStyle(.purple); Text(insight.title).font(.headline).foregroundStyle(.primary); Spacer() }
            HStack(alignment: .top, spacing: 12) { VStack(alignment: .leading, spacing: 8) { Text(TranslationManager.get("dash.advice_header", lang: language)).font(.caption).fontWeight(.bold).foregroundStyle(.secondary); Text(insight.advice).font(.subheadline).foregroundStyle(.primary).lineSpacing(4) }; Spacer() }.padding().background(Color.blue.opacity(0.05)).cornerRadius(12)
            HStack(alignment: .top, spacing: 12) { Text("💡"); Text(insight.knowledge).font(.footnote).foregroundStyle(.secondary).lineLimit(nil) }.padding(.top, 4)
        }.padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1)).shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

struct WatchHealthDashboardView: View {
    let snapshot: WatchHealthSnapshot
    let syncState: HealthSyncState
    let language: AppLanguage
    let onSync: () -> Void

    private var isSyncing: Bool {
        switch syncState {
        case .requesting, .syncing: return true
        default: return false
        }
    }

    private var statusText: String {
        switch syncState {
        case .idle:
            return TranslationManager.get("watch.subtitle_idle", lang: language)
        case .unavailable:
            return TranslationManager.get("watch.subtitle_unavailable", lang: language)
        case .requesting, .syncing:
            return TranslationManager.get("watch.subtitle_syncing", lang: language)
        case .synced(let date):
            return TranslationManager.get("watch.subtitle_synced", lang: language, args: [Self.timeFormatter.string(from: date)])
        case .failed(let message):
            return TranslationManager.get("watch.subtitle_failed", lang: language, args: [message])
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    private var sourceIcon: String {
        switch snapshot.activitySourceKind {
        case .appleWatch: return "applewatch.watchface"
        case .healthConnectedDevice: return "sensor.tag.radiowaves.forward"
        case .phoneOrHealthApp: return "heart.text.square.fill"
        case .none: return "figure.walk.circle"
        }
    }

    private var sourceColor: Color {
        switch snapshot.activitySourceKind {
        case .appleWatch: return .green
        case .healthConnectedDevice: return .blue
        case .phoneOrHealthApp: return .pink
        case .none: return .secondary
        }
    }

    private var sourceDescription: String {
        let label = snapshot.activitySourceKind.label(lang: language)
        guard !snapshot.displaySourceName.isEmpty else { return label }
        return "\(label) · \(snapshot.displaySourceName)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: sourceIcon)
                    .font(.title2)
                    .foregroundStyle(sourceColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(TranslationManager.get("watch.title", lang: language))
                        .font(.headline)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                        .lineLimit(2)
                }
                Spacer()
                Button(action: onSync) {
                    if isSyncing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if snapshot.hasActivitySignals {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                    WatchMetricItem(title: TranslationManager.get("watch.active_energy", lang: language), value: "\(Int(snapshot.activeEnergy)) kcal", icon: "flame.fill", color: .orange)
                    WatchMetricItem(title: TranslationManager.get("watch.exercise", lang: language), value: durationText(snapshot.exerciseMinutes), icon: "figure.run", color: .green)
                    WatchMetricItem(title: TranslationManager.get("watch.sleep", lang: language), value: durationText(snapshot.sleepMinutes), icon: "bed.double.fill", color: .indigo)
                    WatchMetricItem(title: TranslationManager.get("watch.heart_rate", lang: language), value: heartText(snapshot.averageHeartRate), icon: "heart.fill", color: .red)
                    WatchMetricItem(title: TranslationManager.get("watch.resting_hr", lang: language), value: heartText(snapshot.restingHeartRate), icon: "heart.text.square.fill", color: .pink)
                    WatchMetricItem(title: TranslationManager.get("watch.hrv", lang: language), value: snapshot.heartRateVariability > 0 ? "\(Int(snapshot.heartRateVariability)) ms" : "-", icon: "waveform.path.ecg", color: .purple)
                    WatchMetricItem(title: TranslationManager.get("watch.oxygen", lang: language), value: oxygenText, icon: "lungs.fill", color: .cyan)
                    WatchMetricItem(title: TranslationManager.get("watch.respiratory", lang: language), value: snapshot.respiratoryRate > 0 ? "\(String(format: "%.1f", snapshot.respiratoryRate))/min" : "-", icon: "wind", color: .teal)
                    WatchMetricItem(title: TranslationManager.get("watch.workouts", lang: language), value: workoutText, icon: "figure.strengthtraining.traditional", color: .blue)
                    WatchMetricItem(title: TranslationManager.get("watch.daylight", lang: language), value: durationText(snapshot.timeInDaylightMinutes), icon: "sun.max.fill", color: .yellow)
                    WatchMetricItem(title: TranslationManager.get("watch.wrist_temp", lang: language), value: snapshot.wristTemperatureCelsius > 0 ? "\(String(format: "%.1f", snapshot.wristTemperatureCelsius)) C" : "-", icon: "thermometer.medium", color: .orange)
                    WatchMetricItem(title: TranslationManager.get("watch.effort", lang: language), value: snapshot.physicalEffortMETs > 0 ? "\(String(format: "%.1f", snapshot.physicalEffortMETs)) MET" : "-", icon: "bolt.heart.fill", color: .purple)
                }

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text(sourceDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .padding(.top, 2)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "figure.walk.circle")
                        .foregroundStyle(.secondary)
                    Text(TranslationManager.get("watch.no_data", lang: language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private var statusColor: Color {
        switch syncState {
        case .failed: return .red
        case .synced: return .secondary
        case .requesting, .syncing: return .blue
        case .unavailable: return .orange
        case .idle: return .secondary
        }
    }

    private var oxygenText: String {
        snapshot.oxygenSaturation > 0 ? "\(Int(snapshot.oxygenSaturation * 100))%" : "-"
    }

    private var workoutText: String {
        guard snapshot.workoutCount > 0 else { return "-" }
        let name = snapshot.latestWorkoutName.isEmpty ? "" : " \(snapshot.latestWorkoutName)"
        return "\(snapshot.workoutCount)x\(name)"
    }

    private func heartText(_ value: Double) -> String {
        value > 0 ? "\(Int(value)) bpm" : "-"
    }

    private func durationText(_ minutes: Double) -> String {
        guard minutes > 0 else { return "-" }
        if minutes >= 60 {
            let hours = Int(minutes / 60)
            let mins = Int(minutes) % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(Int(minutes))m"
    }
}

struct WatchMetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 34)
    }
}

struct WeeklyProgressCard: View {
    let records: [DailyRecord]
    let dailyLimit: Int
    let language: AppLanguage

    var chartData: [DailyRecord] {
        Array(records.sorted { $0.date < $1.date }.suffix(7))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(.purple)
                Text(TranslationManager.get("chart.title", lang: language))
                    .font(.headline)
            }

            Chart(chartData) { record in
                RuleMark(y: .value(TranslationManager.get("chart.limit_axis", lang: language), dailyLimit))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(.gray.opacity(0.3))

                BarMark(
                    x: .value(TranslationManager.get("chart.date_axis", lang: language), record.date, unit: .day),
                    y: .value(TranslationManager.get("chart.calories_axis", lang: language), record.totalCalories)
                )
                .foregroundStyle(barColor(for: record.totalCalories))
                .cornerRadius(4)
                .annotation(position: .top, alignment: .center) {
                    if record.totalCalories > dailyLimit {
                        Text("\(record.totalCalories)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(centered: true) {
                        if let date = value.as(Date.self) {
                            Text(Self.weekdayLabel(for: date, language: language))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(.gray.opacity(0.1))
                }
            }
            .environment(\.locale, Locale(identifier: language.localeIdentifier))

            HStack {
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text(TranslationManager.get("chart.ok", lang: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text(TranslationManager.get("ring.status_over", lang: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(TranslationManager.get("chart.limit", lang: language, args: [dailyLimit]))
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }

    func barColor(for calories: Int) -> Color {
        if calories > dailyLimit { return .red }
        if calories > Int(Double(dailyLimit) * 0.9) { return .orange }
        return .green
    }

    static func weekdayLabel(for date: Date, language: AppLanguage, calendar: Calendar = .current) -> String {
        let index = max(1, min(7, calendar.component(.weekday, from: date))) - 1
        switch language.translationBase {
        case .traditionalChinese:
            return ["日", "一", "二", "三", "四", "五", "六"][index]
        case .japanese:
            return ["日", "月", "火", "水", "木", "金", "土"][index]
        default:
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][index]
        }
    }
}

struct StatRow: View { let icon: String; let color: Color; let title: String; let value: String; var body: some View { HStack { Image(systemName: icon).foregroundColor(color).frame(width: 20); VStack(alignment: .leading, spacing: 0) { Text(title).font(.caption2).foregroundStyle(.secondary); Text(value).font(.headline).fontWeight(.bold) } } } }
struct HealthStatItem: View { let title: String; let value: String; let icon: String; let color: Color; var body: some View { HStack { Image(systemName: icon).foregroundColor(color).font(.title3); VStack(alignment: .leading) { Text(title).font(.caption2).foregroundStyle(.secondary); Text(value).font(.headline).fontWeight(.bold) }; Spacer() }.padding(10).background(Color(UIColor.systemBackground)).cornerRadius(10) } }
struct LoadingSplashView: View { let language: AppLanguage; @State private var isAnimating = false; var body: some View { ZStack { Color(UIColor.systemBackground).ignoresSafeArea(); VStack(spacing: 24) { ZStack { Circle().fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 120, height: 120).scaleEffect(isAnimating ? 1.1 : 1.0).opacity(isAnimating ? 0.5 : 1.0); Image(systemName: "leaf.circle.fill").font(.system(size: 80)).foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)).shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5).scaleEffect(isAnimating ? 1.05 : 1.0) }; VStack(spacing: 8) { Text(TranslationManager.get("app.title", lang: language)).font(.title2).fontWeight(.bold).foregroundStyle(.primary); Text(TranslationManager.get("loading.preparing", lang: language)).font(.caption).foregroundStyle(.secondary) }; ProgressView().padding(.top, 20) } }.onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { isAnimating = true } } } }
struct AnalysisProgressView: View {
    let progress: AnalysisProgress

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(progress.message)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 12)
                Text("\(progress.percentage)%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 42, alignment: .trailing)
            }

            ProgressView(value: progress.clampedFraction, total: 1)
                .progressViewStyle(.linear)
                .tint(.blue)

            Text(progress.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
    }
}
struct ServerStatusIndicator: View { let status: ServerStatus; let language: AppLanguage; var body: some View { HStack(spacing: 6) { Circle().fill(status.color).frame(width: 8, height: 8).shadow(color: status.color.opacity(0.5), radius: 2); Text(status.label(lang: language)).font(.caption2).foregroundStyle(.secondary); if status == .checking { ProgressView().scaleEffect(0.5) } else { Image(systemName: "arrow.clockwise").font(.caption2).foregroundStyle(.tertiary) } }.padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(Color(UIColor.secondarySystemBackground))) } }
struct ActionCard: View { let title: String; let icon: String; let gradient: LinearGradient; let action: () -> Void; var body: some View { Button(action: action) { ActionCardContent(title: title, icon: icon, gradient: gradient) } } }
struct ActionCardContent: View { let title: String; let icon: String; let gradient: LinearGradient; @Environment(\.dynamicTypeSize) private var dynamicTypeSize; var body: some View { VStack(spacing: 12) { Image(systemName: icon).font(dynamicTypeSize.isAccessibilitySize ? .title2 : .title3).foregroundStyle(.white); Text(title).font(.headline).foregroundStyle(.white).lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1).minimumScaleFactor(0.85).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 118 : 100).padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 10 : 0).background(gradient).cornerRadius(16).shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2) } }
struct CaptureControlLabel: View {
    let title: String
    let icon: String
    let tint: Color
    let isPrimary: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(dynamicTypeSize.isAccessibilitySize ? .title3 : .headline)
                .frame(width: 22)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.9)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 68 : 54)
        .padding(.horizontal, 14)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 10 : 0)
        .foregroundStyle(isPrimary ? .white : tint)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPrimary ? tint : Color(UIColor.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPrimary ? tint.opacity(0.18) : tint.opacity(colorScheme == .dark ? 0.6 : 0.38), lineWidth: 1)
        )
    }
}
struct SubscriptionStatusBanner: View { let isPro: Bool; let remainingCount: Int; let language: AppLanguage; let onUpgrade: () -> Void; var body: some View { HStack { VStack(alignment: .leading, spacing: 4) { HStack { Image(systemName: isPro ? "crown.fill" : "gift.fill").foregroundStyle(isPro ? .yellow : .blue); if isPro { Text(TranslationManager.get("status.pro_active", lang: language)).font(.subheadline).fontWeight(.semibold) } else { Text(TranslationManager.get("status.free_remaining", lang: language, args: [remainingCount])).font(.subheadline).fontWeight(.semibold) } }; if !isPro && remainingCount == 0 { Text(TranslationManager.get("status.free_exhausted", lang: language)).font(.caption).foregroundStyle(.red) } }; Spacer(); if !isPro { Button(action: onUpgrade) { Text(TranslationManager.get("status.upgrade_pro", lang: language)).font(.caption).bold().padding(.horizontal, 12).padding(.vertical, 6).background(Color.blue).foregroundStyle(.white).clipShape(Capsule()) } } }.padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(16) } }
struct ImageSelectionView: View {
    let image: Image?
    let language: AppLanguage
    let specialDietAlert: SpecialDietFoodAlert?
    var height: CGFloat = 280
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    init(image: Image?, language: AppLanguage, height: CGFloat = 280, specialDietAlert: SpecialDietFoodAlert? = nil) {
        self.image = image
        self.language = language
        self.height = height
        self.specialDietAlert = specialDietAlert
    }

    var body: some View {
        let effectiveHeight = max(height, dynamicTypeSize.isAccessibilitySize ? 320 : height)

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))

            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: effectiveHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if let specialDietAlert {
                    SpecialDietImageAlertBadge(alert: specialDietAlert, language: language)
                        .padding(12)
                }
            } else {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: effectiveHeight >= 320 ? 76 : 64, height: effectiveHeight >= 320 ? 76 : 64)
                        Image(systemName: "camera.aperture")
                            .font(.system(size: effectiveHeight >= 320 ? 34 : 28, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                    Text(TranslationManager.get("photo.empty_title", lang: language))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    Text(TranslationManager.get("hint.initial", lang: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .frame(height: effectiveHeight)
                .padding(.horizontal, 18)
            }
        }
        .frame(height: effectiveHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct SpecialDietImageAlertBadge: View {
    let alert: SpecialDietFoodAlert
    let language: AppLanguage
    @ScaledMetric(relativeTo: .title2) private var badgeSize: CGFloat = 48
    @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = 26

    var body: some View {
        ZStack {
            Circle()
                .fill(alert.riskLevel.color)
                .frame(width: badgeSize, height: badgeSize)
                .shadow(color: alert.riskLevel.color.opacity(0.45), radius: 8, x: 0, y: 3)

            Circle()
                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                .frame(width: badgeSize, height: badgeSize)

            Image(systemName: "exclamationmark")
                .font(.system(size: iconSize, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .accessibilityLabel(Text(alert.imageAccessibilityLabel(lang: language)))
    }
}

// [Fix] Fully Expanded & Verified SubscriptionInfoView
struct SubscriptionInfoView: View {
    let offerings: Offerings?
    let language: AppLanguage

    private var displayPackage: Package? {
        offerings?.current?.availablePackages.first { $0.packageType == .monthly } ?? offerings?.current?.availablePackages.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(TranslationManager.get("subscription.details", lang: language))) {
                    HStack {
                        Text(TranslationManager.get("subscription.title", lang: language))
                        Spacer()
                        Text(SubscriptionDisplayText.planName(for: displayPackage, language: language)).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(TranslationManager.get("subscription.price", lang: language))
                        Spacer()
                        Text(displayPackage?.localizedPriceString ?? "—").foregroundStyle(.secondary)
                    }
                }

                Section(header: Text(TranslationManager.get("subscription.legal", lang: language))) {
                    Link(TranslationManager.get("footer.privacy_policy", lang: language), destination: URL(string: "https://eric1207cvb.github.io/hsuehyian-pages/")!)
                    Link(TranslationManager.get("footer.terms_eula", lang: language), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }

                Section(footer: Text(TranslationManager.get("subscription.footer", lang: language))) {
                    EmptyView()
                }
            }
            .navigationTitle(TranslationManager.get("subscription.info_title", lang: language))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
