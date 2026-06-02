# WebService 網路層

以 [Moya](https://github.com/Moya/Moya) 為基礎、可重複使用的網路層。
核心（`Core/`）與專案無關，可整包搬到其他 iOS 專案使用；
`Service/`、`Repository/`、`ViewModel/` 則是各專案自訂的範例。

---

## 1. 資料夾結構

```
WebService/
├── Core/                          ← 與專案無關，可整包複製
│   ├── APITargetType.swift         共通 TargetType（預設 header / 驗證碼 / sampleData）
│   ├── DecodableTargetType.swift   把回應型別綁在 Target 上（associatedtype Response）
│   ├── Response+Decode.swift       Moya.Response / Single 的解碼 helper
│   ├── JSONCoding.swift            專案統一的 JSONDecoder / JSONEncoder
│   ├── Provider.swift              MoyaProvider 建立工廠（session / plugin / stub 切換）
│   ├── MoyaProvider+Async.swift    async/await 介面
│   ├── MoyaProvider+Rx.swift       RxSwift 介面（選用）
│   ├── Plugin/
│   │   ├── CachePlugin.swift        依 Target 設定 cachePolicy
│   │   └── ErrorTransformerPlugin.swift  把後端錯誤轉成型別化的 APIException
│   ├── Error/WebAPIError.swift     對應「API path + 錯誤碼」的 TargetError
│   ├── Extensions/Moya+Task.swift  把 Encodable 轉成 query string 的 Task
│   ├── DecodableType/DecodableBool.swift  容忍 "true"/1/true 多型 bool 的 property wrapper
│   └── Mock/MockData.swift         從 bundle 讀本地 JSON（給 sampleData 用）
│
├── Service/        各支 API 定義（範例：StockAnalysisService）
├── Repository/     對 ViewModel 暴露語意化方法的資料來源層
├── ViewModel/      MVVM 的 ViewModel（範例）
└── Mock/           各 API 的假資料 JSON（專案自訂）
```

### 分層職責

```
View (UIViewController)
  ↓ 訂閱 state
ViewModel        ← 業務邏輯、狀態管理，不碰 UIKit
  ↓ 呼叫
Repository       ← 決定打哪支 API、用哪個 Provider（DI 注入，方便測試）
  ↓
MoyaProvider + Core
  ↓
Service (Target) ← 一支 API 的定義：url / method / query / Response 型別
```

---

## 2. 相依套件

Core 依賴以下 Pod：

```ruby
pod 'Moya', '14.0.0'
pod 'Moya/RxSwift', '14.0.0'   # 只有要用 Rx 介面時才需要
pod 'RxSwift', '5.1.2'         # 同上
pod 'Alamofire', '~> 5.6.1'    # Moya 會自動帶入
```

> **只想用 async/await、不想引入 RxSwift？**
> 刪掉 `Core/MoyaProvider+Rx.swift`，並把 `Core/Response+Decode.swift` 裡
> `PrimitiveSequence` 那個 extension 移除即可，Core 就只依賴 Moya。

---

## 3. 如何搬到其他專案

1. 把整個 **`Core/`** 資料夾拖進新專案（Xcode 16 同步資料夾的話直接放進 target 目錄即可，無需手動加檔案）。
2. 在 `Podfile` 加入上面的相依套件，執行 `pod install`。
3. 開始照「第 4 節」定義你自己的 API。

`Core/` 沒有寫死任何 host、token 或專案專屬邏輯，可直接重複使用。

---

## 4. 新增一支 API（三步驟）

### Step 1：定義 Service（Target）

```swift
import Moya
import Alamofire

enum UserService {

    final class GetProfile: DecodableTargetType {
        typealias Response = Profile               // ① 綁定回應型別

        let baseURL = URL(string: "https://api.example.com")!
        let path = "/v1/profile"
        let method: Moya.Method = .get
        var task: Task { .requestQueryEncodable(query) }   // ② 用 Encodable 當 query

        struct Query: Encodable { let userID: String }
        private let query: Query
        init(_ query: Query) { self.query = query }

        struct Profile: Decodable {                // ③ 回應型別
            let id: String
            let name: String
        }
    }
}
```

需要快取就再 conform `DynamicCacheable`（加一個 `let cached: Bool`）；
需要帶 Bearer Token 就 conform `APIAccessTokenAuthorizable`。

### Step 2：定義 Repository

```swift
import Moya
import RxSwift

protocol UserRepositoryType {
    func fetchProfile(userID: String) async throws -> UserService.GetProfile.Profile
    func fetchProfile(userID: String) -> Single<UserService.GetProfile.Profile>
}

final class UserRepository: UserRepositoryType {
    private let provider: MoyaProvider<UserService.GetProfile>
    init(provider: MoyaProvider<UserService.GetProfile> = .default) {
        self.provider = provider
    }

    // async/await
    func fetchProfile(userID: String) async throws -> UserService.GetProfile.Profile {
        try await provider.requestAsync(.init(.init(userID: userID)))
    }
    // RxSwift
    func fetchProfile(userID: String) -> Single<UserService.GetProfile.Profile> {
        provider.requestSingle(.init(.init(userID: userID)))
    }
}
```

### Step 3：在 ViewModel 使用

```swift
// async/await
let profile = try await repository.fetchProfile(userID: "42")

// RxSwift
repository.fetchProfile(userID: "42")
    .observeOn(MainScheduler.instance)     // RxSwift 5 是 observeOn；RxSwift 6 改成 observe(on:)
    .subscribe(onSuccess: { ... }, onError: { ... })
    .disposed(by: disposeBag)
```

---

## 5. 測試與本地假資料

`Provider.make` 會在環境變數 `STUB == "true"` 時改用 `stubProvider`，
以 Target 的 `sampleData` 回應，不打真正的網路。

- **單元測試**：直接把 `MoyaProvider<T>.stubProvider` 注入 Repository。
- **UITest / 開發離線**：在 scheme 的 Environment Variables 設 `STUB = true`。
- `sampleData` 可用 `MockData.fromJsonFile(fileName:)` 讀 bundle 內的 JSON
  （JSON 檔放哪層資料夾都行，Bundle 會自動尋找）。

---

## 6. 重要設計決策

| 決策 | 原因 |
|------|------|
| `baseURL` 不寫在 `APITargetType` 預設值，改由各 Target 提供 | host 是專案/環境設定，Core 才能保持中性、可攜 |
| 用 `DecodableTargetType` 的 `associatedtype Response` | request helper 能自動推導回應型別，呼叫端免手動指定 decode 型別 |
| 同時提供 async/await 與 RxSwift | 新程式用 async；既有大量 Rx 的程式可漸進遷移 |
| `Provider.make(cache:extraPlugins:)` 單一入口 | 集中管理 session/plugin，避免每個 provider 各自設定漂移 |
| `JSONDecoder.default` 集中設定 | 全專案用同一套日期 / key 策略，改一處即全域生效 |

---

## 7. 注意事項

- **RxSwift 版本差異**：本專案使用 RxSwift **5.1.2**，操作子是 `observeOn` / `subscribe(onSuccess:onError:)`。
  若搬到使用 RxSwift 6+ 的專案，需改成 `observe(on:)` / `subscribe(onSuccess:onFailure:)`。
- **Moya 14 沒有原生 async**：`MoyaProvider+Async.swift` 是用 `withCheckedThrowingContinuation`
  橋接，並支援 Task 取消。升級到 Moya 15+ 後可改用官方 async API。
