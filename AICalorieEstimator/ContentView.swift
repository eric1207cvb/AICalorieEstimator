import UIKit
import SwiftUI
import PhotosUI

// --- 0. API 設定 ---
// (IP 保持你「個人熱點」的 IP)
enum API {
    #if DEBUG
    static let baseURL = URL(string: "http://172.20.10.3:3000")!
    #else
    static let baseURL = URL(string: "https://your-prod-domain.com")!
    #endif
}

// --- 1. 【!!! 核心升級：v4 的資料結構 !!!】---

// (RequestPayload "還原" 成傳送 "image")
struct RequestPayload: Codable {
    let image: String
}

// (ResponsePayload "簡化" 成 "純文字" 結果)
struct CloudResponsePayload: Codable, Equatable {
    let foodList: String // (e.g., "3 顆茶葉蛋, 1 個御飯糰")
    let totalCaloriesMin: Int
    let totalCaloriesMax: Int
    let reasoning: String
}

// --- 2. 客製化的錯誤類型 ---
// (保持不變)
enum CalorieEstimatorError: Error, LocalizedError {
    case imageConversionFailed, jsonEncodingFailed, invalidAPIURL
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "錯誤：無法將照片轉換為 data 格式。"
        case .jsonEncodingFailed: return "錯誤：無法將請求編碼為 JSON。"
        case .invalidAPIURL: return "錯誤：後端 API 的網址無效。"
        }
    }
}

// --- 3. ViewState Enum ---
// (修改 .success，讓它 "包含" 我們的新資料)
enum ViewState: Equatable {
    case empty
    case loading(String)
    case success(CloudResponsePayload) // <-- (還原)
    case error(String)
}

// --- 4. ContentView 主畫面 ---
struct ContentView: View {
    
    init(viewState: ViewState = .empty) {
        self._viewState = State(initialValue: viewState)
    }
    
    // --- 狀態變數 ---
    @State private var selectedImage: Image? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var isShowingCamera = false
    
    // (已刪除 CoreMLManager 和 localDetections)
    
    @State private var viewState: ViewState = .empty
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("AI 熱量估算 App")
                .font(.largeTitle).fontWeight(.bold)
            
            // --- 【!!! 核心升級：簡化的圖片區 !!!】---
            // (已 "刪除" GeometryReader 和 ForEach 畫框邏輯)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(height: 300)

                // (只顯示照片，或預設圖示)
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
            
            // --- 按鈕區 (保持不變) ---
            HStack(spacing: 15) {
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("選擇照片")
                    }.font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundStyle(.white).cornerRadius(12)
                }
                Button(action: { self.isShowingCamera = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("即時拍攝")
                    }.font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Color.green.opacity(0.8)).foregroundStyle(.white).cornerRadius(12)
                }
            }
            .padding(.horizontal)
            Button(action: { Task { await healthCheck() } }) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                    Text("測試連線")
                }.font(.headline).frame(maxWidth: .infinity).padding()
                .background(Color.orange.opacity(0.9)).foregroundStyle(.white).cornerRadius(12)
            }
            .padding(.horizontal)
            
            // --- .sheet & onChange (保持不變) ---
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
                    // 【觸發點】
                    Task { await analyzeImage(uiImage: uiImage) }
                } else {
                    self.selectedImage = nil
                    self.viewState = .empty
                }
            }
            
            // --- 結果顯示區 (文字) ---
            VStack(alignment: .leading) {
                Text("分析結果：")
                    .font(.headline).padding(.bottom, 5)
                
                VStack {
                    switch viewState {
                    case .empty: InitialHintView()
                    case .loading(let message): LoadingView(message: message)
                    case .success(let payload): ResultView(data: payload) // <-- (切換到 v4 版)
                    case .error(let errorMessage): ErrorView(message: errorMessage)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 150, alignment: .top)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .animation(.easeInOut, value: viewState)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    // --- 【!!! 核心升級：v4 版主流程 (體感速度) !!!】---
    func analyzeImage(uiImage: UIImage) async {
        
        // 1. 階段一：上傳 (0.5 秒)
        self.viewState = .loading("正在上傳照片...")
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 2. 階段二：AI 分析 (真正的等待, 15-20 秒)
        self.viewState = .loading("AI 正在辨識與估算中...")
        
        do {
            // (還原成 "上傳完整照片" 的函式)
            let responseData = try await fetchCaloriesFromImage(for: uiImage)
            
            // 3. 階段三：下載 (0.5 秒)
            self.viewState = .loading("正在整理分析結果...")
            try? await Task.sleep(nanoseconds: 500_000_000)

            // 4. 階段四：成功！
            self.viewState = .success(responseData)
            
        } catch {
            // (錯誤處理保持不變)
            let userMessage: String
            if let err = error as? URLError {
                switch err.code {
                case .timedOut: userMessage = "連線逾時 (30s)：AI 處理時間過長或伺服器無回應。"
                case .cannotConnectToHost: userMessage = "無法連線到伺服器：請確認 IP (`\(API.baseURL.absoluteString)`) 正確。"
                case .notConnectedToInternet: userMessage = "目前沒有網路連線。"
                default: userMessage = "網路異常（\(err.code.rawValue)）"
                }
            } else if (error as? DecodingError) != nil {
                userMessage = "伺服器回傳了無法解析的資料。請確認 App 與 Server 版本一致。"
            } else {
                userMessage = error.localizedDescription
            }
            self.viewState = .error(userMessage)
        }
    }

    // --- 【!!! 核心升級：v4 版網路請求 (傳送照片) !!!】---
    func fetchCaloriesFromImage(for image: UIImage) async throws -> CloudResponsePayload {
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CalorieEstimatorError.imageConversionFailed
        }
        let base64String = imageData.base64EncodedString()
        let payload = RequestPayload(image: base64String) // (還原)
        
        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            throw CalorieEstimatorError.jsonEncodingFailed
        }

        // [重要] 呼叫 "舊的" (但已升級) API 路由
        guard let url = URL(string: "/estimate-calories", relativeTo: API.baseURL) else {
            throw CalorieEstimatorError.invalidAPIURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedPayload
        request.timeoutInterval = 30 // (30 秒的合理等待時間)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "伺服器回傳錯誤 (StatusCode: \((response as? HTTPURLResponse)?.statusCode ?? 0))"])
            }
            let rawJSON = String(data: data, encoding: .utf8) ?? "無法解碼 JSON"
            print("--- AI Server (v4) 回傳資料 ---\n\(rawJSON)\n----------------------")
            
            // 【關鍵】解析 "新" 的 CloudResponsePayload 結構
            let decodedResponse = try JSONDecoder().decode(CloudResponsePayload.self, from: data)
            return decodedResponse
        } catch {
            print("網路請求失敗 (AI 2): \(error)")
            throw error
        }
    }
    
    // --- 健康檢查 (healthCheck) ---
    // (我們 "借用" ErrorView 來顯示成功訊息)
    func healthCheck() async {
        self.viewState = .loading("正在測試連線至 \(API.baseURL.absoluteString)...")
        do {
            guard let url = URL(string: "/health", relativeTo: API.baseURL) else {
                throw CalorieEstimatorError.invalidAPIURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15
            let start = Date()
            let (data, response) = try await URLSession.shared.data(for: request)
            let elapsed = Date().timeIntervalSince(start)
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                 throw URLError(.badServerResponse)
            }
            let body = String(data: data, encoding: .utf8) ?? "(無 body)"
            
            self.viewState = .error("✅ 健康檢查成功！\nHTTP \(httpResponse.statusCode), RTT: \(String(format: "%.2f", elapsed))s\nBody: \(body)")
            
        } catch {
            let userMessage: String
            if let err = error as? URLError {
                switch err.code {
                case .timedOut: userMessage = "連線逾時"
                case .cannotConnectToHost: userMessage = "無法連線到伺服器 (IP: \(API.baseURL.absoluteString))"
                default: userMessage = "網路異常（\(err.code.rawValue)）"
                }
            } else {
                userMessage = error.localizedDescription
            }
            self.viewState = .error("❌ " + userMessage)
        }
    }
}

// --- 7. 拆分出來的「子畫面」 (View Components) ---

struct InitialHintView: View {
    var body: some View {
        Text("請點擊「選擇照片」或「即時拍攝」開始分析。")
            .font(.body).foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct LoadingView: View {
    let message: String
    var body: some View {
        VStack(spacing: 15) {
            ProgressView().scaleEffect(1.5)
            Text(message)
                .font(.body).foregroundStyle(.blue)
                .animation(.easeInOut, value: message)
        }
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

// --- 【!!! 核心升級：v4 版的 ResultView !!!】---
// (它 "只" 接收 "CloudResponsePayload")
struct ResultView: View {
    let data: CloudResponsePayload
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                
                // 1. 總熱量
                VStack(alignment: .leading) {
                    Text("總熱量估算")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(data.totalCaloriesMin) - \(data.totalCaloriesMax) 卡")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                Divider()
                
                // 2. 辨識項目 (來自 AI 2 的 "純文字" 列表)
                VStack(alignment: .leading, spacing: 10) {
                    Text("辨識項目：")
                        .font(.headline)
                    Text(data.foodList) // <-- (顯示 "3 顆茶葉蛋, 1 個御飯糰")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                // 3. AI 的估算過程
                VStack(alignment: .leading, spacing: 5) {
                    Text("AI 估算過程：")
                        .font(.headline)
                    Text(data.reasoning) // <-- 顯示 AI 的估算過程
                        .font(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


// --- 9. 預覽畫面 (Preview) ---
#Preview("預覽 - 成功狀態 (v4)") {
    ContentView(viewState: .success(
        CloudResponsePayload(
            foodList: "3 顆茶葉蛋, 1 個鮪魚御飯糰 (預覽)",
            totalCaloriesMin: 400,
            totalCaloriesMax: 450,
            reasoning: "辨識到 3 顆茶葉蛋 (約 210 卡) 和 1 個御飯糰 (約 200 卡)。"
        )
    ))
}
#Preview("預覽 - 初始狀態") {
    ContentView()
}
