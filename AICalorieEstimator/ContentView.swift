import UIKit
import SwiftUI
import PhotosUI

// --- 0. API 設定 ---
enum API {
    #if DEBUG
    static let baseURL = URL(string: "http://172.20.10.3:3000")!
    #else
    static let baseURL = URL(string: "https.your-prod-domain.com")!
    #endif
}

// --- 1. 【v8 升級：國際版資料結構】---
struct RequestPayload: Codable {
    let image: String
    let language: String // <-- 【新增】我們要告訴 Server 用什麼語言
}
struct CloudResponsePayload: Codable, Equatable {
    let foodList: String
    let totalCaloriesMin: Int
    let totalCaloriesMax: Int
    let reasoning: String
}

// --- 2. 錯誤類型 ---
enum CalorieEstimatorError: Error, LocalizedError {
    case imageConversionFailed, jsonEncodingFailed, invalidAPIURL
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "error.json_decode".localized // (借用)
        case .jsonEncodingFailed: return "error.json_decode".localized // (借用)
        case .invalidAPIURL: return "error.no_connection".localized // (借用)
        }
    }
}

// --- 3. 【v8 升級：語言選項】---
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .japanese: return "日本語"
        }
    }
}

// --- 4. ViewState Enum ---
enum ViewState: Equatable {
    case empty
    case loading(String)
    case success(CloudResponsePayload)
    case error(String)
}

// --- 5. ContentView 主畫面 ---
struct ContentView: View {
    
    init(viewState: ViewState = .empty) {
        self._viewState = State(initialValue: viewState)
    }
    
    @State private var selectedImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var isShowingCamera = false
    @State private var viewState: ViewState = .empty
    
    // 【!!! v8 升級：儲存 "使用者選擇" 的語言 !!!】
    // (AppStorage 會自動把選項存在手機裡)
    @AppStorage("selectedLanguage") private var selectedLanguage: AppLanguage = .traditionalChinese
    
    var body: some View {
        ScrollView { // (改成 ScrollView 讓「語言切換器」放得下)
            VStack(spacing: 20) {
                
                Text("app.title")
                    .font(.largeTitle).fontWeight(.bold)
                
                // --- 圖片顯示區 (v4) ---
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
                
                // --- 按鈕區 (v8) ---
                HStack(spacing: 15) {
                    Button(action: { self.isShowingCamera = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("button.take_photo")
                        }.font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.green.opacity(0.8)).foregroundStyle(.white).cornerRadius(12)
                    }
                    
                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("button.select_album")
                        }.font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.blue).foregroundStyle(.white).cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Button(action: { Task { await healthCheck() } }) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                        Text("button.health_check")
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
                        Task { await analyzeImage(uiImage: uiImage) }
                    } else {
                        self.selectedImage = nil
                        self.viewState = .empty
                    }
                }
                
                // --- 結果顯示區 (v5 骨架屏) ---
                VStack(alignment: .leading) {
                    Text("label.analysis_result")
                        .font(.headline).padding(.bottom, 5)
                    
                    VStack {
                        switch viewState {
                        case .empty:
                            InitialHintView()
                        case .loading(let message):
                            SkeletonView() // <-- (v5 骨架屏)
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
                
                // --- 【!!! v8 升級：語言切換器 !!!】---
                Divider()
                VStack {
                    // (Picker 會自動讀取 AppLanguage 裡的 displayName)
                    Picker("language", selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented) // (分段按鈕)
                }
                .padding()
            }
            .padding(.top, 40)
        }
        // 【!!! v8 升級：強制 App 使用 "使用者選擇" 的語言 !!!】
        .environment(\.locale, .init(identifier: selectedLanguage.rawValue))
    }
    
    // --- v7 主流程 (體感速度) ---
    func analyzeImage(uiImage: UIImage) async {
        self.viewState = .loading("hint.loading_upload")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
             self.viewState = .loading("hint.loading_ai")
        }
        do {
            // 【!!! v8 升級：傳入 "使用者選擇" 的語言 !!!】
            let responseData = try await fetchCaloriesFromImage(
                for: uiImage,
                language: selectedLanguage.rawValue // (e.g., "en", "zh-Hant", "ja")
            )
            self.viewState = .success(responseData)
        } catch {
            let userMessage = decodeError(error)
            self.viewState = .error(userMessage)
        }
    }

    // --- 【v7.1 升級：網路請求 (傳送語言)】---
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
        request.timeoutInterval = 30
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
    
    // --- 健康檢查 (healthCheck) ---
    func healthCheck() async {
        self.viewState = .loading("hint.loading_ai")
        do {
            guard let url = URL(string: "/health", relativeTo: API.baseURL) else {
                throw CalorieEstimatorError.invalidAPIURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15
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
    
    // --- 統一的錯誤處理函式 ---
    func decodeError(_ error: Error) -> String {
        if let err = error as? URLError {
            switch err.code {
            case .timedOut: return "error.timeout".localized
            case .cannotConnectToHost: return "error.no_connection".localized
            case .notConnectedToInternet: return "error.no_internet".localized
            default: return "error.json_decode".localized // (簡化)
            }
        } else if (error as? DecodingError) != nil {
            return "error.json_decode".localized
        } else {
            return error.localizedDescription
        }
    }
}

// --- 7. 拆分出來的「子畫面」 (View Components) ---
// (InitialHintView, ErrorView, ResultView)
// (我們 "必須" 把它們 "保留" 在 ContentView.swift 的底部)
// (我們 "不需要" SkeletonView / Shimmer，因為它們在新檔案裡)

struct InitialHintView: View {
    var body: some View {
        Text("hint.initial") // <-- (使用 Key)
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

// (ResultView v4 版)
struct ResultView: View {
    let data: CloudResponsePayload
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    Text("result.total_calories") // <-- (使用 Key)
                        .font(.headline).foregroundStyle(.secondary)
                    Text("\(data.totalCaloriesMin) - \(data.totalCaloriesMax) 卡")
                        .font(.largeTitle).fontWeight(.bold).foregroundStyle(.blue)
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("result.items_found") // <-- (使用 Key)
                        .font(.headline)
                    Text(data.foodList)
                        .font(.body).fontWeight(.semibold)
                }
                Divider()
                VStack(alignment: .leading, spacing: 5) {
                    Text("result.ai_analysis") // <-- (使用 Key)
                        .font(.headline)
                    Text(data.reasoning)
                        .font(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// --- 10. 【新增】一個 Helper 讓 .strings 更好用 ---
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
