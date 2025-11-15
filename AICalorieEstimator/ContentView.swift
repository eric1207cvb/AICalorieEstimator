import UIKit
import SwiftUI
import PhotosUI
import RevenueCat // 導入 RevenueCat SDK

// --- 0. Helper & Extension (修正編譯順序) ---
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
    // 【!!! 暫時 "改成" 雲端網址來測試 !!!】
    static let baseURL = URL(string: "/estimate-calories", relativeTo: URL(string: "https://aicalorie-server.onrender.com")!)! // <-- 貼上你的網址
    #else
    static let baseURL = URL(string: "https://your-prod-domain.com")!
    #endif
}

// --- 2. 資料結構 (v8) ---
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
    
    // 接收來自 App.swift 的語言狀態 (Binding)
    @Binding var selectedLanguage: AppLanguage
    
    init(viewState: ViewState = .empty, selectedLanguage: Binding<AppLanguage>) {
        self._viewState = State(initialValue: viewState)
        self._selectedLanguage = selectedLanguage // 綁定語言
    }
    
    @State private var selectedImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var isShowingCamera = false
    @State private var viewState: ViewState = .empty
    
    // 【!!! V9 升級：新增 RevenueCat 狀態變數 !!!】
    @State private var offerings: Offerings?
    @State private var rcStatusMessage: String = "正在檢查訂閱狀態..."
    @State private var isProUser: Bool = false // V9.1 最終判斷權限
    @State private var isShowingPaywall: Bool = false // V12 升級：控制 Paywall 顯示
    
    #if DEBUG
    @State private var debugBypassPro: Bool = false
    #endif
    
    var body: some View {
        // 【!!! v8.2 升級：加入 "導覽列" !!!】
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 【!!! V9 升級：訂閱狀態列 !!!】
                    SubscriptionStatusView(
                        offerings: $offerings,
                        statusMessage: $rcStatusMessage,
                        isProUser: $isProUser, // 傳遞會員狀態
                        isShowingPaywall: $isShowingPaywall // 傳遞新的 Paywall 狀態
                    )
                    .padding(.horizontal)
                    
                    // 語言選擇器（最小更動）
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    #if DEBUG
                    // 調試用：繞過 Pro 限制
                    Toggle(isOn: $debugBypassPro) {
                        Text("[DEBUG] Bypass Pro Requirement")
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal)
                    #endif
                    
                    // (圖片顯示區 - 保持不變)
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 2)
                            .frame(height: 300)
                        if let image = selectedImage {
                            image.resizable().scaledToFit()
                                .frame(height: 290)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "photo")
                                .resizable().scaledToFit().frame(width: 100, height: 100)
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10) // (因為標題移到 "上面" 了，給它一點空間)
                    
                    // --- 按鈕區 (v8) ---
                    HStack(spacing: 15) {
                        Button(action: { self.isShowingCamera = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text(LocalizedStringKey("button.take_photo"))
                            }.font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color.green.opacity(0.8)).foregroundStyle(.white).cornerRadius(12)
                        }
                        
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text(LocalizedStringKey("button.select_album"))
                            }.font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color.blue).foregroundStyle(.white).cornerRadius(12)
                        }
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
                    
                    // --- .sheet & onChange (v4) ---
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
                            // V9 升級：這裡處理圖片切換，並觸發分析
                            Task { await analyzeImage(uiImage: uiImage) }
                        } else {
                            self.selectedImage = nil
                            self.viewState = .empty
                        }
                    }
                    
                    // --- 結果顯示區 (v5 骨架屏) ---
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("label.analysis_result"))
                            .font(.headline).padding(.bottom, 5)
                        
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
                                ResultView(data: payload)
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
                    
                }
                .padding(.top, 1) // (讓 ScrollView 頂部貼齊)
            }
            // --- 【!!! v8.2 升級：標題 & 工具列按鈕 !!!】---
            .navigationTitle(LocalizedStringKey("app.title"))
            .navigationBarTitleDisplayMode(.large)
            // 【!!! V12 最終修正：移除 Toolbar 避免 Bug 衝突 !!!】
        }
        // Environment 和 ID 綁定已移至 App.swift
        .onAppear {
            fetchOfferings()
        }
        .sheet(isPresented: $isShowingPaywall) {
            if let offering = offerings?.current {
                // 傳遞正確的 Offering 資料給 Paywall
                PaywallView(offering: offering)
            }
        }
    }
    
    // --- (analyzeImage 函式 - V11 實作鎖定) ---
    func analyzeImage(uiImage: UIImage) async {
        // 【!!! V9 升級：專業版鎖定檢查 (支援 DEBUG 繞過) !!!】
        #if DEBUG
        let shouldBypass = debugBypassPro
        #else
        let shouldBypass = false
        #endif
        if !isProUser && !shouldBypass {
            // 如果不是 Pro 用戶，顯示鎖定錯誤，並跳出
            self.viewState = .error("error.pro_required".localized)
            return
        }
        // 【!!! 如果是 Pro 用戶，才執行原本的分析邏輯 !!!】
        
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
        } catch {
            let userMessage = decodeError(error)
            self.viewState = .error(userMessage)
        }
    }

    // --- (fetchCaloriesFromImage 函式 保持不變) ---
    func fetchCaloriesFromImage(for image: UIImage, language: String) async throws -> CloudResponsePayload {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CalorieEstimatorError.imageConversionFailed
        }
        let base64String = imageData.base64EncodedString()
        let payload = RequestPayload(image: base64String, language: language)
        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            throw CalorieEstimatorError.jsonEncodingFailed
        }
        guard let url = URL(string: "/estimate-calories", relativeTo: API.baseURL) else {
            throw CalorieEstimatorError.invalidAPIURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedPayload
        request.timeoutInterval = 90 // (保持 90 秒)
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
    
    // --- (healthCheck 函式 保持不變 - 修正了 requestBody 錯誤) ---
    func healthCheck() async {
        self.viewState = .loading("hint.loading_ai".localized)
        do {
            guard let url = URL(string: "/health", relativeTo: API.baseURL) else {
                throw CalorieEstimatorError.invalidAPIURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15
            // 修正：刪除了 request.requestBody = nil
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let body = String(data: data, encoding: .utf8) ?? "(無 body)"
            self.viewState = .error("health_check.success".localized + "\nBody: \(body)")
        } catch {
            let userMessage = decodeError(error)
            self.viewState = .error("health_check.fail".localized(with: userMessage))
        }
    }
    
    // --- (decodeError 函式 保持不變) ---
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
    
    // 【!!! V9 升級：新增 RevenueCat 函數 - 最終版 !!!】
    func fetchOfferings() {
        Purchases.shared.getOfferings { (offerings, error) in
            // 處理 Offerings 錯誤 (如果 Product Catalog 是空的，會在這裡報錯)
            if let error = error {
                print("RevenueCat Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.rcStatusMessage = "無法連接訂閱服務。請檢查網路或 App Store 狀態。"
                }
                // 即使 Offerings 失敗，也要繼續檢查用戶狀態
            }

            // 檢查 CustomerInfo (會員狀態)
            Purchases.shared.getCustomerInfo { (customerInfo, error) in
                // 檢查用戶是否有我們在 RevenueCat 設定的 "pro" 會員資格
                let isPro = customerInfo?.entitlements.active.keys.contains("pro") ?? false
                
                // 成功取得，更新狀態
                DispatchQueue.main.async {
                    self.offerings = offerings
                    self.isProUser = isPro // V9.1 關鍵：更新會員狀態
                    
                    if isPro {
                        self.rcStatusMessage = "會員狀態：專業版 (Pro) 已解鎖！"
                        print("✅ 用戶是專業版會員！")
                    } else if offerings?.current != nil { // 檢查是否有至少一個 Offering
                         // Offerings 載入成功，但用戶不是 Pro
                        self.rcStatusMessage = "連線成功。請點擊購買按鈕解鎖專業版。"
                    } else {
                        // 初始 Offerings 失敗 (Product Catalog is empty)
                         self.rcStatusMessage = "產品目錄未載入。請檢查 RevenueCat 設定。"
                    }
                }
            }
        }
    }
}

// --- V9 Helper View 訂閱狀態顯示區 ---
struct SubscriptionStatusView: View {
    @Binding var offerings: Offerings?
    @Binding var statusMessage: String
    @Binding var isProUser: Bool // 接收會員狀態
    @Binding var isShowingPaywall: Bool // 【V12 升級：控制 Paywall 狀態】
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("label.subscription_status".localized)
                .font(.subheadline)
                .fontWeight(.bold)
            
            // 檢查是否成功找到方案
            if isProUser {
                 // 狀態 1: 專業版已解鎖
                 Text("✅ 專業版已解鎖")
                     .foregroundColor(.green)
            } else {
                 // 狀態 2: 未解鎖，顯示錯誤/購買按鈕
                 VStack(alignment: .leading, spacing: 10) {
                     // 顯示錯誤訊息 (因為目錄是空的)
                     HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        Text("❌ \(statusMessage)")
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.red)
                     }
                     
                     // 【!!! 最終 UI 突圍：強制顯示購買按鈕 !!!】
                     // 無論 offerings 是否為空，只要不是 Pro，就顯示這個按鈕
                     Button("立即解鎖 Pro 功能") {
                         self.isShowingPaywall = true
                     }
                     .buttonStyle(.borderedProminent)
                     .tint(.red) // 顯示為紅色，提醒用戶升級
                     
                 }
            }
        }
        .padding()
        .background(isProUser ? Color.green.opacity(0.1) : Color.red.opacity(0.1)) // 根據 Pro 狀態改變背景色
        .cornerRadius(10)
    }
}


// --- 7. 拆分出來的「子畫面」 (View Components) ---
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

// (ResultView v8 版)
struct ResultView: View {
    let data: CloudResponsePayload
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey("result.total_calories"))
                        .font(.headline).foregroundStyle(.secondary)
                    Text("\(data.totalCaloriesMin) - \(data.totalCaloriesMax) 卡")
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

// --- (Preview 保持不變) ---
#Preview("預覽 - 成功狀態 (v7)") {
    // (包在 NavigationStack 裡，才能預覽 "標題")
    NavigationStack {
        ContentView(viewState: .success(
            CloudResponsePayload(
                foodList: "1 x Coca-Cola (330ml)",
                totalCaloriesMin: 140,
                totalCaloriesMax: 140,
                reasoning: "Based on the image, this is one 330ml can of Coca-Cola, which is approx 140 calories."
            )
        ), selectedLanguage: .constant(.traditionalChinese)) // 修正預覽
        .environment(\.locale, .init(identifier: "en"))
    }
}
#Preview("預覽 - 骨架屏 (v5)") {
    // (包在 NavigationStack 裡)
    NavigationStack {
        ContentView(viewState: .loading("hint.loading_ai"), selectedLanguage: .constant(.traditionalChinese)) // 修正預覽
    }
}

