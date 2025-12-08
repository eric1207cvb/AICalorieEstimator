import UIKit
import SwiftUI
import PhotosUI
import RevenueCat // 導入 RevenueCat SDK
import StoreKit
import AVFoundation

// --- 0. Helper & Extension ---
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// --- 1. API 設定 ---
enum API {
    #if DEBUG
    static let baseURL = URL(string: "https://aicalorie-server.onrender.com")!
    #else
    static let baseURL = URL(string: "https://aicalorie-server.onrender.com")!
    #endif
}

// --- 2. 資料結構 ---
struct RequestPayload: Codable {
    let image: String
    let language: String
}
struct CloudResponsePayload: Codable, Equatable {
    let foodList: String
    let totalCaloriesMin: Int
    let totalCaloriesMax: Int
    let reasoning: String
}

// --- 3. 錯誤類型 ---
enum CalorieEstimatorError: Error, LocalizedError {
    case imageConversionFailed, jsonEncodingFailed, invalidAPIURL
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "error.json_decode".localized
        case .jsonEncodingFailed: return "error.json_decode".localized
        case .invalidAPIURL: return "error.no_connection".localized
        }
    }
}

// --- 5. ViewState Enum ---
enum ViewState: Equatable {
    case empty
    case loading(String)
    case success(CloudResponsePayload)
    case error(String)
}

// --- 6. ContentView 主畫面 ---
struct ContentView: View {
    
    @Binding var selectedLanguage: AppLanguage
    
    init(viewState: ViewState = .empty, selectedLanguage: Binding<AppLanguage>) {
        self._viewState = State(initialValue: viewState)
        self._selectedLanguage = selectedLanguage
    }
    
    @State private var selectedImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var isShowingCamera = false
    @State private var viewState: ViewState = .empty
    
    @State private var cameraUnavailableAlert: Bool = false
    
    // RevenueCat 狀態變數
    @State private var offerings: Offerings?
    @State private var rcStatusMessage: String = "正在檢查訂閱狀態..."
    @State private var isProUser: Bool = false
    @State private var isShowingPaywall: Bool = false
    
    @State private var showRCAlert: Bool = false
    
    #if DEBUG
    // 【修復 1】預設改為 false，防止切換語言重置畫面時，自動開啟開發者後門
    @State private var debugBypassPro: Bool = false
    #endif
    
    @State private var showManageSubscriptions: Bool = false
    @State private var isShowingSubscriptionInfo: Bool = false
    
    // 【5次免費額度邏輯】
    let maxFreeUsageCount = 5
    let usageKey = "user_free_usage_count_v1"
    
    // 取得目前已使用次數
    func getCurrentUsageCount() -> Int {
        return UserDefaults.standard.integer(forKey: usageKey)
    }
    
    // 增加使用次數 (消耗一點)
    func incrementUsageCount() {
        let current = getCurrentUsageCount()
        UserDefaults.standard.set(current + 1, forKey: usageKey)
        // 更新狀態文字
        updateStatusMessage()
    }
    
    // 檢查是否還有剩餘次數
    func hasRemainingFreeUsage() -> Bool {
        return getCurrentUsageCount() < maxFreeUsageCount
    }
    
    // 【修復 2】集中管理狀態文字邏輯
    // 確保無論是 App 啟動、網路回應或切換語言，顯示的邏輯都是一致的
    func updateStatusMessage() {
        if isProUser {
            self.rcStatusMessage = "會員狀態：專業版 (Pro) 已解鎖！"
        } else {
            let used = getCurrentUsageCount()
            let remaining = max(0, maxFreeUsageCount - used)
            
            if remaining > 0 {
                self.rcStatusMessage = "免費試用剩餘次數：\(remaining) 次"
            } else {
                self.rcStatusMessage = "免費額度已用完。請升級以繼續使用。"
            }
        }
    }
    
    // 相機授權檢查
    func ensureCameraAuthorized() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return UIImagePickerController.isSourceTypeAvailable(.camera)
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted && UIImagePickerController.isSourceTypeAvailable(.camera)
        default:
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 訂閱區塊
                    VStack(alignment: .leading, spacing: 12) {
                        SubscriptionStatusView(
                            offerings: $offerings,
                            statusMessage: $rcStatusMessage,
                            isProUser: $isProUser,
                            isShowingPaywall: $isShowingPaywall
                        )

                        HStack(spacing: 12) {
                            if let storefront = Purchases.shared.storeFrontCountryCode, !storefront.isEmpty {
                                Text("Storefront: \(storefront)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()

                            Button {
                                Purchases.shared.restorePurchases { customerInfo, error in
                                    if let error = error {
                                        print("Restore failed: \(error.localizedDescription)")
                                    } else {
                                        print("Restore succeeded: \(String(describing: customerInfo))")
                                        // 恢復購買後也要更新狀態
                                        if let info = customerInfo {
                                            self.isProUser = info.entitlements.active.keys.contains("pro")
                                            self.updateStatusMessage()
                                        }
                                    }
                                }
                            } label: {
                                Label("Restore", systemImage: "arrow.clockwise.circle")
                                    .labelStyle(.titleAndIcon)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .controlSize(.regular)

                            Button {
                                showManageSubscriptions = true
                            } label: {
                                Label("Manage", systemImage: "gearshape")
                                    .labelStyle(.titleAndIcon)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .controlSize(.regular)
                        }
                    }
                    .padding(14)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Language").font(.caption).foregroundStyle(.secondary)
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    
                    #if DEBUG
                    DisclosureGroup {
                        Toggle(isOn: $debugBypassPro) {
                            Text("[DEBUG] Bypass Pro Requirement")
                        }
                    } label: {
                        Text("Developer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    #endif
                    
                    // 圖片顯示區
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(height: 300)
                        if let image = selectedImage {
                            image.resizable().scaledToFit()
                                .frame(height: 290)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .resizable().scaledToFit().frame(width: 80, height: 80)
                                    .foregroundStyle(.gray.opacity(0.5))
                                Text("Tap camera or photos to start")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 按鈕區
                    HStack(spacing: 15) {
                        Button(action: {
                            Task {
                                if await ensureCameraAuthorized() {
                                    self.isShowingCamera = true
                                } else {
                                    self.cameraUnavailableAlert = true
                                }
                            }
                        }) {
                            Label { Text(LocalizedStringKey("button.take_photo")) } icon: { Image(systemName: "camera.fill") }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            Label { Text(LocalizedStringKey("button.select_album")) } icon: { Image(systemName: "photo.on.rectangle.angled") }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)

                    Button(action: { Task { await healthCheck() } }) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                            Text(LocalizedStringKey("button.health_check"))
                        }.font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.orange.opacity(0.9)).foregroundStyle(.white).cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // .sheet & onChange
                    .sheet(isPresented: $isShowingCamera) {
                        CameraPickerView(selectedImage: $selectedUIImage)
                    }
                    .onChange(of: photosPickerItem) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                self.selectedUIImage = uiImage
                            }
                        }
                    }
                    .onChange(of: selectedUIImage) { _, newImage in
                        if let uiImage = newImage {
                            self.selectedImage = Image(uiImage: uiImage)
                            Task { await analyzeImage(uiImage: uiImage) }
                        } else {
                            self.selectedImage = nil
                            self.viewState = .empty
                        }
                    }
                    .onChange(of: isShowingPaywall) { _, newValue in
                        if newValue == false { // Paywall closed
                            Purchases.shared.getCustomerInfo { info, _ in
                                let isPro = info?.entitlements.active.keys.contains("pro") ?? false
                                DispatchQueue.main.async {
                                    self.isProUser = isPro
                                    self.updateStatusMessage()
                                }
                            }
                        }
                    }
                    .alert("相機不可用", isPresented: $cameraUnavailableAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("此裝置無相機或未授權使用相機，請改用相簿選取照片。")
                    }
                    
                    // 結果顯示區
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("label.analysis_result"))
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        VStack {
                            switch viewState {
                            case .empty:
                                InitialHintView()
                            case .loading(let message):
                                SkeletonView()
                                Text(LocalizedStringKey(message))
                                    .font(.body).foregroundStyle(.blue)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 10)
                                    .animation(.easeInOut, value: message)
                            case .success(let payload):
                                ResultView(data: payload, language: selectedLanguage)
                            case .error(let errorMessage):
                                ErrorView(message: errorMessage)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .top)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .animation(.easeInOut, value: viewState)
                    }
                    .padding(.horizontal)
                    
                    DataSourcesButton()
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        Button {
                            isShowingSubscriptionInfo = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("Subscription Terms & Info")
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote)
                            }
                            .font(.footnote)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.gray.opacity(0.12))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)

                        DisclaimerButton(renderAsCard: true)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top, 1)
            }
            .navigationTitle(LocalizedStringKey("app.title"))
            .navigationBarTitleDisplayMode(.large)
        }
        .id(selectedLanguage) // 注意：這個 id 會導致切換語言時 View 重建，所以 updateStatusMessage 必須在 onAppear 執行
        .onAppear {
            // 【修復 3】畫面一出現（或重建）就立刻檢查本地次數
            // 這樣即使網路還沒回來，用戶也會立刻看到「額度已用完」
            updateStatusMessage()
            fetchOfferings()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("proStatusUpdated"))) { output in
            if let isPro = output.object as? Bool {
                self.isProUser = isPro
                self.updateStatusMessage()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Purchases.shared.getCustomerInfo { info, _ in
                let isPro = info?.entitlements.active.keys.contains("pro") ?? false
                DispatchQueue.main.async {
                    self.isProUser = isPro
                    self.updateStatusMessage()
                }
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            if let offering = offerings?.current {
                PaywallView(offering: offering)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("正在載入產品…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .onAppear { fetchOfferings() }
            }
        }
        .sheet(isPresented: $isShowingSubscriptionInfo) {
            SubscriptionInfoView(offerings: offerings)
        }
        .onDisappear {
            Purchases.shared.getCustomerInfo { info, _ in
                let isPro = info?.entitlements.active.keys.contains("pro") ?? false
                DispatchQueue.main.async {
                    self.isProUser = isPro
                    self.updateStatusMessage()
                }
            }
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .alert("無法顯示購買頁面", isPresented: $showRCAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(rcStatusMessage)
        }
    }
    
    // --- (analyzeImage 函式) ---
    func analyzeImage(uiImage: UIImage) async {
        
        #if DEBUG
        let shouldBypass = debugBypassPro
        #else
        let shouldBypass = false
        #endif
        
        // 1. Pro 用戶 -> 通過
        if isProUser {
            // Pass
        }
        // 2. 開發者模式 -> 通過
        else if shouldBypass {
            // Pass
        }
        // 3. 檢查剩餘次數
        else if hasRemainingFreeUsage() {
            incrementUsageCount() // 消耗一次額度
            print("🟢 免費額度消耗中。已使用 \(getCurrentUsageCount()) / \(maxFreeUsageCount)")
        }
        // 4. 次數已用完 -> 阻擋
        else {
            print("🔴 免費額度已用完 (5/5)，觸發 Paywall。")
            self.viewState = .empty
            self.updateStatusMessage() // 強制 UI 更新
            self.isShowingPaywall = true
            return
        }
        
        // --- AI 分析邏輯 ---
        self.viewState = .loading("hint.loading_upload".localized)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.viewState = .loading("hint.loading_ai".localized)
        }
        do {
            let responseData = try await fetchCaloriesFromImage(
                for: uiImage,
                language: selectedLanguage.rawValue
            )
            self.viewState = .success(responseData)
            playHaptic(.success)
        } catch {
            let userMessage = decodeError(error)
            self.viewState = .error(userMessage)
            playHaptic(.error)
        }
    }

    // --- (fetchCaloriesFromImage 保持不變) ---
    func fetchCaloriesFromImage(for image: UIImage, language: String) async throws -> CloudResponsePayload {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CalorieEstimatorError.imageConversionFailed
        }
        let base64String = imageData.base64EncodedString()
        let payload = RequestPayload(image: base64String, language: language)
        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            throw CalorieEstimatorError.jsonEncodingFailed
        }
        let url = API.baseURL.appendingPathComponent("estimate-calories")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedPayload
        request.timeoutInterval = 90
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "伺服器回傳錯誤 (StatusCode: \((response as? HTTPURLResponse)?.statusCode ?? 0))"])
            }
            let decodedResponse = try JSONDecoder().decode(CloudResponsePayload.self, from: data)
            return decodedResponse
        } catch {
            print("網路請求失敗 (AI Image): \(error)")
            throw error
        }
    }
    
    // --- (healthCheck 保持不變) ---
    func healthCheck() async {
        self.viewState = .loading("hint.loading_ai".localized)
        do {
            let url = API.baseURL.appendingPathComponent("health")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            if (200..<300).contains(httpResponse.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? "(無 body)"
                self.viewState = .success(CloudResponsePayload(foodList: "", totalCaloriesMin: 0, totalCaloriesMax: 0, reasoning: "health_check.success".localized + "\nBody: \(body)"))
            } else {
                let snippet = String(data: data.prefix(200), encoding: .utf8) ?? ""
                let message = "HTTP \(httpResponse.statusCode). \("error.bad_server_response".localized)\n\(snippet)"
                self.viewState = .error(message)
            }
        } catch {
            let userMessage = decodeError(error)
            self.viewState = .error("health_check.fail".localized(with: userMessage))
        }
    }
    
    // --- (decodeError 保持不變) ---
    func decodeError(_ error: Error) -> String {
        if let err = error as? URLError {
            switch err.code {
            case .timedOut: return "error.timeout".localized
            case .cannotConnectToHost: return "error.no_connection".localized
            case .notConnectedToInternet: return "error.no_internet".localized
            default: return "error.json_decode".localized
            }
        } else if (error as? DecodingError) != nil {
            return "error.json_decode".localized
        } else {
            return error.localizedDescription
        }
    }
    
    func playHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if targetEnvironment(simulator)
        return
        #else
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        #endif
    }
    
    // --- 【修復 4】RevenueCat Fetch Offerings (邏輯優化) ---
    func fetchOfferings() {
        Purchases.shared.getOfferings { (offerings, error) in
            if let error = error {
                print("RevenueCat Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // 這裡不直接設字串，而是看還有沒有次數
                    self.updateStatusMessage()
                }
            }

            Purchases.shared.getCustomerInfo { (customerInfo, error) in
                let isPro = customerInfo?.entitlements.active.keys.contains("pro") ?? false
                
                DispatchQueue.main.async {
                    self.offerings = offerings
                    self.isProUser = isPro
                    // 【關鍵修正】不要直接覆蓋字串，而是重新呼叫 updateStatusMessage
                    // 這樣它會檢查：如果不是 Pro，且次數用完，會保持顯示「額度已用完」
                    // 而不是顯示「連線成功」讓人誤會
                    self.updateStatusMessage()
                }
            }
        }
    }
}

// --- V9 Helper View 訂閱狀態顯示區 ---
struct SubscriptionStatusView: View {
    @Binding var offerings: Offerings?
    @Binding var statusMessage: String
    @Binding var isProUser: Bool
    @Binding var isShowingPaywall: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("label.subscription_status".localized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Image(systemName: isProUser ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isProUser ? .green : .red)
                if isProUser {
                    Text("✅ 專業版已解鎖")
                        .foregroundColor(.green)
                        .font(.body)
                        .fontWeight(.semibold)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusMessage) // 直接顯示 Content View 傳來的動態訊息 (含次數)
                            .font(.footnote)
                            .foregroundColor(.red)
                        
                        Button("立即解鎖 Pro 功能") {
                            self.isShowingPaywall = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                    }
                }
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background((isProUser ? Color.green.opacity(0.1) : Color.red.opacity(0.1)))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(10)
    }
}


// --- 7. 拆分出來的「子畫面」 ---
// (保持不變)

struct InitialHintView: View {
    var body: some View {
        Text(LocalizedStringKey("hint.initial"))
            .font(.body).foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct ErrorView: View {
    let message: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            let isSuccess = message.contains("✅")
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title3).foregroundStyle(isSuccess ? .green : .red)
            Text(message)
                .font(.body).foregroundStyle(isSuccess ? .green : .red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ResultView: View {
    let data: CloudResponsePayload
    let language: AppLanguage
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey("result.total_calories"))
                        .font(.headline).foregroundStyle(.secondary)
                    Text(formatEstimatedCalories(min: data.totalCaloriesMin, max: data.totalCaloriesMax, language: language))
                        .font(.largeTitle).fontWeight(.bold).foregroundStyle(.blue)
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStringKey("result.items_found"))
                        .font(.headline)
                    Text(data.foodList)
                        .font(.body).fontWeight(.semibold)
                }
                Divider()
                VStack(alignment: .leading, spacing: 5) {
                    Text(LocalizedStringKey("result.ai_analysis"))
                        .font(.headline)
                    Text(data.reasoning)
                        .font(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("預覽 - 成功狀態") {
    NavigationStack {
        ContentView(viewState: .success(
            CloudResponsePayload(
                foodList: "1 x Coca-Cola (330ml)",
                totalCaloriesMin: 140,
                totalCaloriesMax: 140,
                reasoning: "Based on the image, this is one 330ml can of Coca-Cola."
            )
        ), selectedLanguage: .constant(.traditionalChinese))
        .environment(\.locale, Locale(identifier: "en"))
    }
}
#Preview("預覽 - 骨架屏") {
    NavigationStack {
        ContentView(viewState: .loading("hint.loading_ai"), selectedLanguage: .constant(.traditionalChinese))
    }
}

func formatEstimatedCalories(min: Int, max: Int, language: AppLanguage) -> String {
    let unit: String
    switch language {
    case .traditionalChinese:
        unit = "大卡"
    case .english:
        unit = "kcal"
    case .japanese:
        unit = "キロカロリー"
    }
    return "\(min) - \(max) \(unit)"
}

// MARK: - Subscription Info View
struct SubscriptionInfoView: View {
    let offerings: Offerings?

    private var displayPackage: Package? {
        if let current = offerings?.current {
            if let monthly = current.availablePackages.first(where: { $0.packageType == .monthly }) {
                return monthly
            }
            return current.availablePackages.first
        }
        return nil
    }

    private var title: String {
        if let pkg = displayPackage {
            return pkg.storeProduct.localizedTitle
        }
        return "Pro Subscription"
    }

    private var priceString: String {
        if let pkg = displayPackage {
            return pkg.localizedPriceString
        }
        return "—"
    }

    private var periodDescription: String {
        if let pkg = displayPackage, let period = pkg.storeProduct.subscriptionPeriod {
            switch (period.unit, period.value) {
            case (.day, 1): return "Daily"
            case (.day, _): return "Every \(period.value) days"
            case (.week, 1): return "Weekly"
            case (.week, _): return "Every \(period.value) weeks"
            case (.month, 1): return "Monthly"
            case (.month, _): return "Every \(period.value) months"
            case (.year, 1): return "Yearly"
            case (.year, _): return "Every \(period.value) years"
            @unknown default: return "Auto-renewing"
            }
        }
        return "Auto-renewing"
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Subscription Details")) {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(title).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Length")
                        Spacer()
                        Text(periodDescription).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Price")
                        Spacer()
                        Text(priceString).foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Legal")) {
                    Link("Privacy Policy", destination: URL(string: "https://eric1207cvb.github.io/hsuehyian-pages/")!)
                    Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }

                Section(footer: Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage and cancel your subscriptions in your App Store account settings after purchase.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Subscription Info")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
