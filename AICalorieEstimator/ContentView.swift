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

// --- 1. 資料結構 (v8) ---
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

// --- 2. 錯誤類型 ---
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

// --- 3. 語言選項 ---
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
    
    @AppStorage("selectedLanguage") private var selectedLanguage: AppLanguage = .traditionalChinese
    
    var body: some View {
        // 【!!! v8.2 升級：加入 "導覽列" !!!】
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
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
                                Text("button.take_photo")
                            }.font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color.green.opacity(0.8)).foregroundStyle(.white).cornerRadius(12)
                        }
                        
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on_rectangle.angled")
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
                    
                    // (我們 "刪除" 了底下的 Picker)
                    
                }
                .padding(.top, 1) // (讓 ScrollView 頂部貼齊)
            }
            // --- 【!!! v8.2 升級：標題 & 工具列按鈕 !!!】---
            .navigationTitle("app.title") // 1. 把標題 "放" 到導覽列上
            .navigationBarTitleDisplayMode(.large) // (用大標題)
            .toolbar {
                // 2. 在導覽列 "加上" 一個工具列
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 3. 在 "右上角" (Trailing)
                    
                    // 4. 加入一個 "下拉選單 (Menu)"
                    Menu {
                        // 5. 【!!! 把 "Picker" 藏在選單裡 !!!】
                        Picker("language", selection: $selectedLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.inline) // (使用 "inline" 樣式，讓它變成選單)
                        
                    } label: {
                        // 6. 選單的 "按鈕"，就是 "地球" 圖示
                        Image(systemName: "globe")
                            .font(.title3) // (讓圖示大一點)
                    }
                }
            }
        }
        // 【!!! v8 升級：強制 App 使用 "使用者選擇" 的語言 !!!】
        .environment(\.locale, .init(identifier: selectedLanguage.rawValue))
    }
    
    // --- (analyzeImage 函式 保持不變) ---
    func analyzeImage(uiImage: UIImage) async {
        self.viewState = .loading("hint.loading_upload")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
             self.viewState = .loading("hint.loading_ai")
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
    
    // --- (healthCheck 函式 保持不變) ---
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
}

// --- 7. 拆分出來的「子畫面」 (View Components) ---
// (InitialHintView, ErrorView, ResultView)
// (這些 "必須" 保留)

struct InitialHintView: View {
    var body: some View {
        Text("hint.initial")
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
                    Text("result.total_calories") // (使用 Key)
                        .font(.headline).foregroundStyle(.secondary)
                    Text("\(data.totalCaloriesMin) - \(data.totalCaloriesMax) 卡")
                        .font(.largeTitle).fontWeight(.bold).foregroundStyle(.blue)
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("result.items_found") // (使用 Key)
                        .font(.headline)
                    Text(data.foodList)
                        .font(.body).fontWeight(.semibold)
                }
                Divider()
                VStack(alignment: .leading, spacing: 5) {
                    Text("result.ai_analysis") // (使用 Key)
                        .font(.headline)
                    Text(data.reasoning)
                        .font(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// --- 10. (Helper 保持不變) ---
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
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
        ))
        .environment(\.locale, .init(identifier: "en"))
    }
}
#Preview("預覽 - 骨架屏 (v5)") {
    // (包在 NavigationStack 裡)
    NavigationStack {
        ContentView(viewState: .loading("hint.loading_ai"))
    }
}
