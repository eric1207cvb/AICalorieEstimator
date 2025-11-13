import UIKit
import SwiftUI
import PhotosUI

// --- 0. API 設定：集中管理 Base URL ---
enum API {
    #if DEBUG
    // 【!!! 最終 IP !!!】
    // 這就是你 Mac 在「個人熱點」網路上的 IP 位址
    static let baseURL = URL(string: "http://172.20.10.3:3000")!
    #else
    // Production 網域（未來部署時使用）
    static let baseURL = URL(string: "https://your-prod-domain.com")!
    #endif
}

// --- 1. 定義 JSON 資料結構 (Codable) ---
struct RequestPayload: Codable {
    let image: String
}

struct BoundingBox: Codable, Equatable {
    let x_min: Double
    let y_min: Double
    let x_max: Double
    let y_max: Double
}

struct ResponsePayload: Codable, Equatable {
    static func == (lhs: ResponsePayload, rhs: ResponsePayload) -> Bool {
        return lhs.foodName == rhs.foodName && lhs.caloriesMin == rhs.caloriesMin
    }
    let foodName: String
    let confidence: Double
    let caloriesMin: Int
    let caloriesMax: Int
    let reasoning: String
    let tips: String
    let boundingBox: BoundingBox
}

// --- 2. 客製化的錯誤類型 ---
enum CalorieEstimatorError: Error, LocalizedError {
    case imageConversionFailed
    case jsonEncodingFailed
    case invalidAPIURL
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed: return "錯誤：無法將照片轉換為 data 格式。"
        case .jsonEncodingFailed: return "錯誤：無法將請求編碼為 JSON。"
        case .invalidAPIURL: return "錯誤：後端 API 的網址無效。"
        }
    }
}

// --- 3. ViewState Enum ---
enum ViewState: Equatable {
    case empty
    case loading(String)
    case success(ResponsePayload)
    case error(String)
}


// --- 4. ContentView 主畫面 ---
struct ContentView: View {
    
    // 為了 #Preview
    init(viewState: ViewState = .empty) {
        self._viewState = State(initialValue: viewState)
    }
    
    // --- 狀態變數 ---
    @State private var selectedImage: Image? = nil // (UI 顯示用)
    @State private var selectedUIImage: UIImage? = nil // "原始圖片" (來自相機或相簿)
    
    @State private var viewState: ViewState = .empty
    @State private var photosPickerItem: PhotosPickerItem? = nil // (相簿選擇器用)
    
    @State private var isShowingCamera = false // 是否顯示相機
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("AI 熱量估算 App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // --- 圖片顯示區 (Bounding Box 功能) ---
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 2)
                    .frame(height: 300)

                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        if let image = selectedImage {
                            image.resizable().scaledToFit()
                                .frame(width: geo.size.width, height: geo.size.height)
                        } else {
                            Image(systemName: "photo")
                                .resizable().scaledToFit().frame(width: 100, height: 100)
                                .foregroundStyle(.gray.opacity(0.5))
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                        
                        // 繪製 Bounding Box
                        if case .success(let data) = viewState {
                            let box = data.boundingBox
                            let w = geo.size.width
                            let h = geo.size.height
                            let rectWidth = w * (box.x_max - box.x_min)
                            let rectHeight = h * (box.y_max - box.y_min)
                            let rectX = w * box.x_min
                            let rectY = h * box.y_min
                            
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow, lineWidth: 4)
                                .frame(width: rectWidth, height: rectHeight)
                                .offset(x: rectX, y: rectY)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                                
                            Text(data.foodName)
                                .font(.caption).fontWeight(.bold).padding(4)
                                .background(Color.yellow).foregroundStyle(Color.black)
                                .cornerRadius(4).offset(x: rectX, y: rectY - 20)
                        }
                    }
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            // --- 按鈕區 ---
            HStack(spacing: 15) {
                // (A) 相簿選擇器
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("選擇照片")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                
                // (B) 即時拍攝按鈕
                Button(action: { self.isShowingCamera = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("即時拍攝")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            // (C) 健康檢查
            Button(action: {
                Task { await healthCheck() }
            }) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                    Text("測試連線")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.9))
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // --- .sheet (用來顯示相機) ---
            .sheet(isPresented: $isShowingCamera) {
                CameraPickerView(selectedImage: $selectedUIImage)
            }
            
            // --- onChange 邏輯 (關鍵) ---
            
            // (1) 監聽 "相簿選擇器"
            .onChange(of: photosPickerItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        self.selectedUIImage = uiImage
                    }
                }
            }
            
            // (2) 監聽 "原始圖片" (單一 AI 觸發點)
            .onChange(of: selectedUIImage) { _, newImage in
                if let uiImage = newImage {
                    self.selectedImage = Image(uiImage: uiImage)
                    Task { await analyzeImage(uiImage: uiImage) }
                } else {
                    self.selectedImage = nil
                    self.viewState = .empty
                }
            }
            
            // --- 結果顯示區 (文字) ---
            VStack(alignment: .leading) {
                Text("分析結果：")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                VStack {
                    switch viewState {
                    case .empty: InitialHintView()
                    case .loading(let message): LoadingView(message: message)
                    case .success(let payload): ResultView(data: payload)
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
            
            // 顯示目前使用中的 Base URL，方便偵錯
            Text("API：\(API.baseURL.absoluteString)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
        .padding(.top, 40)
    }
    
    // --- 主流程 & 網路請求 ---
    
    func analyzeImage(uiImage: UIImage) async {
        self.viewState = .loading("AI 分析中，請稍候...")
        do {
            let responseData = try await fetchCaloriesFromBackend(for: uiImage)
            self.viewState = .success(responseData)
        } catch {
            let userMessage: String
            if let err = error as? URLError {
                switch err.code {
                case .timedOut:
                    userMessage = "連線逾時：請確認伺服器是否啟動、IP/Port 是否正確，或網路是否穩定。"
                case .cannotConnectToHost, .cannotFindHost:
                    userMessage = "無法連線到伺B服器：請確認 IP (`\(API.baseURL.absoluteString)`) 是否正確。"
                case .notConnectedToInternet:
                    userMessage = "目前沒有網路連線，請檢查 Wi‑Fi 或行動網路。"
                default:
                    userMessage = "網路異常（\(err.code.rawValue)），請稍後再試。"
                }
            } else if let err = error as? CalorieEstimatorError {
                userMessage = err.localizedDescription
            } else {
                userMessage = error.localizedDescription
            }
            self.viewState = .error(userMessage)
        }
    }

    func fetchCaloriesFromBackend(for image: UIImage) async throws -> ResponsePayload {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CalorieEstimatorError.imageConversionFailed
        }
        let base64String = imageData.base64EncodedString()
        let payload = RequestPayload(image: base64String)
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
        request.timeoutInterval = 60
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "伺服器回傳錯誤 (StatusCode: \((response as? HTTPURLResponse)?.statusCode ?? 0))"])
            }
            let rawJSON = String(data: data, encoding: .utf8) ?? "無法解碼 JSON"
            print("--- AI Server 回傳資料 ---\n\(rawJSON)\n----------------------")
            let decodedResponse = try JSONDecoder().decode(ResponsePayload.self, from: data)
            return decodedResponse
        } catch {
            print("網路請求失敗: \(error)")
            throw error
        }
    }
    
    // 健康檢查：快速測試後端是否可達
    func healthCheck() async {
        self.viewState = .loading("正在測試連線至 \(API.baseURL.absoluteString)...")
        do {
            guard let url = URL(string: "/health", relativeTo: API.baseURL) else {
                throw CalorieEstimatorError.invalidAPIURL
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15 // 15秒超時
            let start = Date()
            let (data, response) = try await URLSession.shared.data(for: request)
            let elapsed = Date().timeIntervalSince(start)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            let body = String(data: data, encoding: .utf8) ?? "(無 body)"
            if (200..<300).contains(httpResponse.statusCode) {
                let placeholder = ResponsePayload(
                    foodName: "健康檢查成功",
                    confidence: 1.0,
                    caloriesMin: httpResponse.statusCode,
                    caloriesMax: httpResponse.statusCode,
                    reasoning: "HTTP \(httpResponse.statusCode), RTT: \(String(format: "%.2f", elapsed))s\nBody: \(body)",
                    tips: "Base URL：\(API.baseURL.absoluteString)",
                    boundingBox: BoundingBox(x_min: 0, y_min: 0, x_max: 0, y_max: 0)
                )
                self.viewState = .success(placeholder)
            } else {
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "健康檢查失敗：HTTP \(httpResponse.statusCode). Body: \(body)"])
            }
        } catch {
            // (healthCheck 的錯誤處理和 analyzeImage 相同)
            let userMessage: String
            if let err = error as? URLError {
                switch err.code {
                case .timedOut:
                    userMessage = "連線逾時：請確認伺服器是否啟動、IP/Port 是否正確，或網路是否穩定。"
                case .cannotConnectToHost, .cannotFindHost:
                    userMessage = "無法連線到伺服器：請確認 IP (`\(API.baseURL.absoluteString)`) 是否正確。"
                case .notConnectedToInternet:
                    userMessage = "目前沒有網路連線，請檢查 Wi‑Fi 或行動網路。"
                default:
                    userMessage = "網路異常（\(err.code.rawValue)），請稍後再試。"
                }
            } else if let err = error as? CalorieEstimatorError {
                userMessage = err.localizedDescription
            } else {
                userMessage = error.localizedDescription
            }
            self.viewState = .error(userMessage)
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
            Text(message).font(.body).foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
struct ErrorView: View {
    let message: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3).foregroundStyle(.red)
            Text("分析失敗：\n\(message)")
                .font(.body).foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
struct ResultView: View {
    let data: ResponsePayload
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(data.foodName).font(.title).fontWeight(.bold).foregroundStyle(.blue)
            Text("熱量：約 \(data.caloriesMin) - \(data.caloriesMax) 卡")
                .font(.headline).fontWeight(.semibold)
            VStack(alignment: .leading, spacing: 5) {
                Text("AI 分析：").font(.caption).foregroundStyle(.secondary)
                Text(data.reasoning).font(.body)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text("AI 建議：").font(.caption).foregroundStyle(.secondary)
                Text(data.tips).font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// --- 9. 預覽畫面 (Preview) ---
#Preview("預覽 - 成功狀態") {
    ContentView(viewState: .success(
        ResponsePayload(
            foodName: "鹽酥雞 (預覽)", confidence: 0.9, caloriesMin: 600, caloriesMax: 750,
            reasoning: "看起來超好吃，油炸物與九層塔的完美組合。",
            tips: "建議搭配無糖綠茶，去油解膩。",
            boundingBox: BoundingBox(x_min: 0.1, y_min: 0.2, x_max: 0.9, y_max: 0.8)
        )
    ))
}
#Preview("預覽 - 初始狀態") {
    ContentView()
}
