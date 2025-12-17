import SwiftUI
import PhotosUI
import RevenueCat
import Charts
import HealthKit
import StoreKit

// MARK: - [Client v9.34] Main View (Final UI: Horizontal Gender Row)
struct ContentView: View {
    @Binding var selectedLanguage: AppLanguage
    @StateObject private var viewModel = CalorieEstimatorViewModel()
    
    @State private var selectedUIImage: UIImage? = nil
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var isShowingCamera = false
    @State private var cameraUnavailableAlert: Bool = false
    @State private var showManageSubscriptions: Bool = false
    @State private var isShowingSubscriptionInfo: Bool = false
    @State private var isEditingProfile = false
    
    var todayCaloriesIntake: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return viewModel.weeklyRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.totalCalories ?? 0
    }
    
    var canAnalyze: Bool {
        return viewModel.isProUser || viewModel.remainingFreeUsage > 0
    }
    
    var body: some View {
        ZStack {
            if !viewModel.isAppLoading {
                NavigationStack {
                    ScrollView { mainContent }
                        .navigationTitle(LocalizedStringKey("app.title"))
                        .background(Color(UIColor.systemGroupedBackground))
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Menu {
                                    Picker("Language", selection: $selectedLanguage) {
                                        ForEach(AppLanguage.allCases) { lang in Text(lang.displayName).tag(lang) }
                                    }
                                    Divider()
                                    Button { showManageSubscriptions = true } label: { Label("Manage Subscription", systemImage: "creditcard") }
                                    Button { viewModel.restorePurchases() } label: { Label("Restore Purchases", systemImage: "arrow.clockwise") }
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
                LoadingSplashView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    .zIndex(1)
            }
        }
        .id(selectedLanguage)
        .environment(\.locale, Locale(identifier: selectedLanguage.rawValue))
        .sheet(isPresented: $isShowingCamera) { CameraPickerView(selectedImage: $selectedUIImage) }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                    self.selectedUIImage = uiImage
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
            if let offering = viewModel.offerings?.current { PaywallView(offering: offering) }
            else { ProgressView().onAppear { viewModel.fetchOfferings() } }
        }
        .sheet(isPresented: $isShowingSubscriptionInfo) { SubscriptionInfoView(offerings: viewModel.offerings) }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .alert("Error", isPresented: $cameraUnavailableAlert) { Button("OK") {} } message: { Text("Camera access required.") }
    }
    
    var mainContent: some View {
        VStack(spacing: 20) {
            // 1. Status Bar
            VStack(spacing: 12) {
                SubscriptionStatusBanner(
                    isPro: viewModel.isProUser,
                    remainingCount: viewModel.remainingFreeUsage,
                    language: selectedLanguage,
                    onUpgrade: { viewModel.isShowingPaywall = true }
                )
                Button(action: { Task { await viewModel.healthCheck() } }) {
                    ServerStatusIndicator(status: viewModel.serverStatus)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal).padding(.top, 10)
            
            // Limit Calculation
            let limit = UserProfile(
                height: viewModel.height,
                currentWeight: viewModel.currentWeight,
                targetWeight: viewModel.targetWeight,
                stepCount: viewModel.stepCount,
                basalEnergy: viewModel.basalEnergy,
                gender: viewModel.gender
            ).dailyCalorieLimit
            
            // 2. Calorie Ring
            CalorieRingView(intake: todayCaloriesIntake, limit: limit, language: selectedLanguage)
                .padding(.horizontal)
            
            // 3. Smart Coach
            let profile = UserProfile(
                height: viewModel.height,
                currentWeight: viewModel.currentWeight,
                targetWeight: viewModel.targetWeight,
                stepCount: viewModel.stepCount,
                basalEnergy: viewModel.basalEnergy,
                gender: viewModel.gender
            )
            SmartCoachView(profile: profile, todayCalories: todayCaloriesIntake, language: selectedLanguage)
                .padding(.horizontal)
            
            // 4. Health Dashboard (UI Polish)
            HealthDashboardView(
                height: $viewModel.height,
                weight: $viewModel.currentWeight,
                target: $viewModel.targetWeight,
                gender: $viewModel.gender,
                stepCount: viewModel.stepCount,
                basalEnergy: viewModel.basalEnergy,
                todayCalories: todayCaloriesIntake,
                language: selectedLanguage,
                isExpanded: $isEditingProfile,
                onSync: { viewModel.syncHealthData() }
            )
            .padding(.horizontal)
            
            // 5. Weekly Chart
            if !viewModel.weeklyRecords.isEmpty {
                WeeklyProgressCard(records: viewModel.weeklyRecords, dailyLimit: limit, language: selectedLanguage)
                    .padding(.horizontal)
            }
            
            // 6. Camera Actions
            ImageSelectionView(image: viewModel.selectedImage, language: selectedLanguage)
                .onTapGesture { }
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                ActionCard(title: "button.take_photo", icon: "camera.fill", gradient: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)) {
                    if canAnalyze {
                        Task { await ensureCameraAuthorized() ? (isShowingCamera = true) : (cameraUnavailableAlert = true) }
                    } else {
                        viewModel.isShowingPaywall = true
                    }
                }
                .opacity(canAnalyze ? 1.0 : 0.6)
                
                ZStack {
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        ActionCardContent(title: "button.select_album", icon: "photo.on.rectangle.angled", gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .disabled(!canAnalyze)
                    
                    if !canAnalyze {
                        Button(action: { viewModel.isShowingPaywall = true }) { Color.clear }
                    }
                }
                .opacity(canAnalyze ? 1.0 : 0.6)
            }.padding(.horizontal)
            
            // 7. Result Area
            VStack {
                switch viewModel.viewState {
                case .empty:
                    ContentUnavailableView("Ready to Analyze", systemImage: "camera.aperture", description: Text(TranslationManager.get("hint.initial", lang: selectedLanguage)))
                        .padding(.vertical, 30).foregroundStyle(.secondary)
                case .loading(let message):
                    VStack(spacing: 16) {
                        SkeletonView().frame(height: 200).cornerRadius(12)
                        ProgressView()
                        Text(message).font(.subheadline).foregroundStyle(.blue)
                    }
                    .padding()
                case .success(let payload):
                    VStack(spacing: 16) {
                        ResultView(data: payload, language: selectedLanguage)
                        Button(action: {
                            let avgCalories = (payload.safeMin + payload.safeMax) / 2
                            viewModel.logCurrentMeal(calories: avgCalories)
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
                    }
                case .error(let msg):
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundColor(.red)
                        Text(msg).multilineTextAlignment(.center)
                    }
                    .padding().frame(maxWidth: .infinity).background(Color.red.opacity(0.1)).cornerRadius(12)
                }
            }.padding(.horizontal)
            
            // 8. Footer
            VStack(spacing: 16) {
                DataSourcesButton().padding(.horizontal)
                Button(action: { isShowingSubscriptionInfo = true }) {
                    Text("Privacy Policy & Terms").font(.caption).underline().foregroundStyle(.secondary)
                }
                DisclaimerButton(renderAsCard: false).font(.caption2).foregroundStyle(.tertiary)
            }.padding(.bottom)
        }.padding(.vertical)
    }
    
    func ensureCameraAuthorized() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized { return true }
        if status == .notDetermined { return await AVCaptureDevice.requestAccess(for: .video) }
        return false
    }
}

// MARK: - [Fix] HealthDashboardView: Horizontal Gender Row

struct HealthDashboardView: View {
    @Binding var height: Double
    @Binding var weight: Double
    @Binding var target: Double
    @Binding var gender: UserGender
    var stepCount: Int
    var basalEnergy: Double
    var todayCalories: Int
    var language: AppLanguage
    @Binding var isExpanded: Bool
    var onSync: () -> Void
    
    var profile: UserProfile { UserProfile(height: height, currentWeight: weight, targetWeight: target, stepCount: stepCount, basalEnergy: basalEnergy, gender: gender) }
    
    // UI Helper for numeric inputs
    private func inputContainer<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            content()
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
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
                VStack(spacing: 16) {
                    
                    Button(action: onSync) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(TranslationManager.get("profile.sync_health", lang: language))
                        }
                        .font(.footnote).fontWeight(.medium)
                        .padding(.vertical, 6).padding(.horizontal, 12)
                        .background(Capsule().fill(Color.blue.opacity(0.1))).foregroundColor(.blue)
                    }
                    
                    // [Change] Gender Row: Horizontal Layout (Label Left, Value Right)
                    Menu {
                        ForEach(UserGender.allCases, id: \.self) { g in
                            Button(action: { gender = g }) {
                                if gender == g { Label(g.label, systemImage: "checkmark") }
                                else { Text(g.label) }
                            }
                        }
                    } label: {
                        HStack {
                            Label(TranslationManager.get("profile.gender", lang: language), systemImage: "person.fill")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text(gender.label)
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
                    
                    // Measurements Row
                    HStack(spacing: 12) {
                        inputContainer(label: TranslationManager.get("profile.height", lang: language)) {
                            HStack {
                                TextField("0", value: $height, format: .number).keyboardType(.decimalPad)
                                Text("cm").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        inputContainer(label: TranslationManager.get("profile.weight", lang: language)) {
                            HStack {
                                TextField("0", value: $weight, format: .number).keyboardType(.decimalPad)
                                Text("kg").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        inputContainer(label: TranslationManager.get("health.weight_goal", lang: language)) {
                            HStack {
                                TextField("0", value: $target, format: .number).keyboardType(.decimalPad)
                                Text("kg").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 20) {
                        HealthStatItem(title: "BMI", value: profile.bmi, icon: "scalemass.fill", color: .purple)
                        HealthStatItem(title: "TDEE", value: "\(profile.dailyCalorieLimit)", icon: "flame.fill", color: .orange)
                    }
                    
                    // Progress
                    if target != weight {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(TranslationManager.get("health.to_target", lang: language, args: [abs(target - weight)]))
                                    .font(.caption).bold().foregroundStyle(target < weight ? .green : .blue)
                                Spacer()
                                Image(systemName: target < weight ? "arrow.down.right" : "arrow.up.right")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.gray.opacity(0.2)).frame(height: 8)
                                    Capsule().fill(target < weight ? Color.green : Color.blue)
                                        .frame(width: geo.size.width * 0.6, height: 8)
                                }
                            }.frame(height: 8)
                        }
                        .padding(.top, 4)
                    }
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

struct CalorieRingView: View {
    let intake: Int; let limit: Int; let language: AppLanguage
    var percentage: Double { min(Double(intake) / Double(limit), 1.0) }
    var isOver: Bool { intake > limit }
    var remaining: Int { limit - intake }
    var body: some View {
        HStack(spacing: 30) {
            ZStack {
                Circle().stroke(Color.gray.opacity(0.15), lineWidth: 15)
                Circle().trim(from: 0, to: percentage).stroke(AngularGradient(gradient: Gradient(colors: isOver ? [.red, .orange] : [.green, .mint]), center: .center, startAngle: .degrees(-90), endAngle: .degrees(-90 + (percentage * 360))), style: StrokeStyle(lineWidth: 15, lineCap: .round)).rotationEffect(.degrees(-90)).animation(.spring(duration: 1.0), value: percentage)
                VStack(spacing: 2) { Text(isOver ? TranslationManager.get("ring.status_over", lang: language) : TranslationManager.get("ring.status_remain", lang: language)).font(.system(size: 10)).foregroundStyle(.secondary); Text("\(abs(remaining))").font(.title2).fontWeight(.heavy).foregroundStyle(isOver ? .red : .primary); Text("kcal").font(.system(size: 10)).foregroundStyle(.tertiary) }
            }.frame(width: 100, height: 100)
            VStack(alignment: .leading, spacing: 12) {
                StatRow(icon: "flame.fill", color: .orange, title: TranslationManager.get("ring.target_title", lang: language), value: "\(limit)")
                StatRow(icon: "fork.knife", color: .blue, title: TranslationManager.get("ring.intake_title", lang: language), value: "\(intake)")
                HStack(spacing: 4) { Image(systemName: isOver ? "figure.walk" : "checkmark.seal.fill"); Text(isOver ? TranslationManager.get("ring.advice_over", lang: language) : TranslationManager.get("ring.advice_good", lang: language)) }.font(.caption).fontWeight(.medium).padding(.vertical, 6).padding(.horizontal, 10).background(isOver ? Color.red.opacity(0.1) : Color.green.opacity(0.1)).foregroundColor(isOver ? .red : .green).cornerRadius(8)
            }
        }.frame(maxWidth: .infinity).padding(20).background(Color(UIColor.secondarySystemBackground)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1)).shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
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

struct WeeklyProgressCard: View {
    let records: [DailyRecord]; let dailyLimit: Int; let language: AppLanguage
    var chartData: [DailyRecord] { records.sorted { $0.date < $1.date }.suffix(7) }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Image(systemName: "chart.bar.xaxis").foregroundStyle(.purple); Text(TranslationManager.get("chart.title", lang: language)).font(.headline) }
            Chart(chartData) { record in RuleMark(y: .value("Limit", dailyLimit)).lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5])).foregroundStyle(.gray.opacity(0.3)); BarMark(x: .value("Date", record.date, unit: .day), y: .value("Calories", record.totalCalories)).foregroundStyle(barColor(for: record.totalCalories)).cornerRadius(4).annotation(position: .top, alignment: .center) { if record.totalCalories > dailyLimit { Text("\(record.totalCalories)").font(.system(size: 10, weight: .bold)).foregroundColor(.red) } } }.frame(height: 200).chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true) } }.chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine().foregroundStyle(.gray.opacity(0.1)) } }
            HStack { Circle().fill(Color.green).frame(width: 8, height: 8); Text("OK").font(.caption).foregroundStyle(.secondary); Circle().fill(Color.red).frame(width: 8, height: 8); Text(TranslationManager.get("ring.status_over", lang: language)).font(.caption).foregroundStyle(.secondary); Spacer(); Text("Limit: \(dailyLimit) kcal").font(.caption).bold().foregroundStyle(.secondary) }
        }.padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))
    }
    func barColor(for calories: Int) -> Color { if calories > dailyLimit { return .red }; if calories > Int(Double(dailyLimit) * 0.9) { return .orange }; return .green }
}

struct StatRow: View { let icon: String; let color: Color; let title: String; let value: String; var body: some View { HStack { Image(systemName: icon).foregroundColor(color).frame(width: 20); VStack(alignment: .leading, spacing: 0) { Text(title).font(.caption2).foregroundStyle(.secondary); Text(value).font(.headline).fontWeight(.bold) } } } }
struct HealthStatItem: View { let title: String; let value: String; let icon: String; let color: Color; var body: some View { HStack { Image(systemName: icon).foregroundColor(color).font(.title3); VStack(alignment: .leading) { Text(title).font(.caption2).foregroundStyle(.secondary); Text(value).font(.headline).fontWeight(.bold) }; Spacer() }.padding(10).background(Color(UIColor.systemBackground)).cornerRadius(10) } }
struct LoadingSplashView: View { @State private var isAnimating = false; var body: some View { ZStack { Color(UIColor.systemBackground).ignoresSafeArea(); VStack(spacing: 24) { ZStack { Circle().fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 120, height: 120).scaleEffect(isAnimating ? 1.1 : 1.0).opacity(isAnimating ? 0.5 : 1.0); Image(systemName: "leaf.circle.fill").font(.system(size: 80)).foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)).shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5).scaleEffect(isAnimating ? 1.05 : 1.0) }; VStack(spacing: 8) { Text(LocalizedStringKey("app.title")).font(.title2).fontWeight(.bold).foregroundStyle(.primary); Text("AI Preparing Analysis...").font(.caption).foregroundStyle(.secondary) }; ProgressView().padding(.top, 20) } }.onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { isAnimating = true } } } }
struct ServerStatusIndicator: View { let status: ServerStatus; var body: some View { HStack(spacing: 6) { Circle().fill(status.color).frame(width: 8, height: 8).shadow(color: status.color.opacity(0.5), radius: 2); Text(status.label).font(.caption2).foregroundStyle(.secondary); if status == .checking { ProgressView().scaleEffect(0.5) } else { Image(systemName: "arrow.clockwise").font(.caption2).foregroundStyle(.tertiary) } }.padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(Color(UIColor.secondarySystemBackground))) } }
struct ActionCard: View { let title: String; let icon: String; let gradient: LinearGradient; let action: () -> Void; var body: some View { Button(action: action) { ActionCardContent(title: title, icon: icon, gradient: gradient) } } }
struct ActionCardContent: View { let title: String; let icon: String; let gradient: LinearGradient; var body: some View { VStack(spacing: 12) { Image(systemName: icon).font(.system(size: 28)).foregroundStyle(.white); Text(LocalizedStringKey(title)).font(.headline).foregroundStyle(.white) }.frame(maxWidth: .infinity).frame(height: 100).background(gradient).cornerRadius(16).shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2) } }
struct SubscriptionStatusBanner: View { let isPro: Bool; let remainingCount: Int; let language: AppLanguage; let onUpgrade: () -> Void; var body: some View { HStack { VStack(alignment: .leading, spacing: 4) { HStack { Image(systemName: isPro ? "crown.fill" : "gift.fill").foregroundStyle(isPro ? .yellow : .blue); if isPro { Text(TranslationManager.get("status.pro_active", lang: language)).font(.subheadline).fontWeight(.semibold) } else { Text(TranslationManager.get("status.free_remaining", lang: language, args: [remainingCount])).font(.subheadline).fontWeight(.semibold) } }; if !isPro && remainingCount == 0 { Text(TranslationManager.get("status.free_exhausted", lang: language)).font(.caption).foregroundStyle(.red) } }; Spacer(); if !isPro { Button(action: onUpgrade) { Text(TranslationManager.get("status.upgrade_pro", lang: language)).font(.caption).bold().padding(.horizontal, 12).padding(.vertical, 6).background(Color.blue).foregroundStyle(.white).clipShape(Capsule()) } } }.padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(16) } }
struct ImageSelectionView: View { let image: Image?; let language: AppLanguage; var body: some View { ZStack { RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemBackground)).frame(height: 280).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.2), lineWidth: 1)); if let image = image { image.resizable().scaledToFit().frame(height: 280).clipShape(RoundedRectangle(cornerRadius: 16)) } else { VStack(spacing: 12) { Image(systemName: "photo.badge.plus").font(.system(size: 40)).foregroundStyle(.blue.opacity(0.5)).symbolEffect(.pulse, isActive: true); Text(TranslationManager.get("hint.initial", lang: language)).font(.subheadline).foregroundStyle(.secondary) } } }.shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4) } }

// [Fix] Fully Expanded & Verified SubscriptionInfoView
struct SubscriptionInfoView: View {
    let offerings: Offerings?
    
    private var displayPackage: Package? {
        offerings?.current?.availablePackages.first { $0.packageType == .monthly } ?? offerings?.current?.availablePackages.first
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Subscription Details")) {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(displayPackage?.storeProduct.localizedTitle ?? "Pro Subscription").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Price")
                        Spacer()
                        Text(displayPackage?.localizedPriceString ?? "—").foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Legal")) {
                    Link("Privacy Policy", destination: URL(string: "https://eric1207cvb.github.io/hsuehyian-pages/")!)
                    Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
                
                Section(footer: Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Subscription Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
