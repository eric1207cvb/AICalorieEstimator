import SwiftUI
import RevenueCat

// 這就是我們的付款介面，它會接收到 App 傳來的訂閱方案
struct PaywallView: View {
    
    // 接收從 ContentView 傳來的 Offering 狀態
    let offering: Offering
    
    // 關閉按鈕，讓用戶可以返回
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                // 1. 標題與說明
                Text("Upgrade to Pro!")
                    .font(.largeTitle)
                    .bold()
                
                Text("Unlock unlimited AI analysis and get accurate calorie counts for any food item.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 2. 顯示 Packages / 價格清單
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(offering.availablePackages) { package in
                        PackageCell(package: package)
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                // 3. 恢復購買按鈕
                Button("Restore Purchases") {
                    // TODO: 恢復購買邏輯
                }
                .font(.callout)
                
                // 4. 服務條款
                Text("By subscribing, you agree to our Terms of Service.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
            }
            .padding()
            .toolbar {
                // 5. 關閉按鈕
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 輔助結構：顯示單個訂閱 Package 的資訊
struct PackageCell: View {
    let package: Package
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(package.storeProduct.localizedTitle)
                    .font(.headline)
                Text(package.storeProduct.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            
            // 價格按鈕
            Button(package.localizedPriceString) {
                // TODO: 購買觸發點
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// 預覽結構
#Preview {
    // 警告：這個預覽會因為沒有真實的 RevenueCat Package 資料而失敗
    // 我們需要模擬一個 Package 來預覽，但現在我們略過預覽
    // PaywallView(offering: <#T##Offering#>) 
    Text("Paywall Preview requires live data.")
}
