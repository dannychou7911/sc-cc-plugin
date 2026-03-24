# 分析策略

## 符號定位策略

分析程式碼時，優先使用 LSP 進行符號定位（定義跳轉、引用查找、型別資訊），LSP 不可用時退回 Grep。

- **Go to Definition**：追蹤可復用邏輯單元的原始定義
- **Find References**：找出某個符號被哪些模組引用，判斷是否為共用邏輯
- **Type Information**：理解型別約束和介面定義

> 主 agent 和 Explore agent 均適用此策略。Explore agent prompt 中應包含「符號定位優先使用 LSP，LSP 不可用時退回 Grep」。

---

## 前端專案的分析順序

```
路由表 → 頁面清單 → 逐頁互動行為
→ 狀態管理 → 表單與驗證
→ 條件渲染規則 → API 呼叫層
```

## 後端專案的分析順序

```
Route 定義 → API 清單 → 資料模型（DB schema）
→ 逐支 API 拆解（驗證 → 權限 → 邏輯 → 寫入 → 副作用）
→ Middleware / 橫切關注點 → 排程任務 → 環境變數
```

## 何時使用 / 不使用 Sub-agent

**使用 Explore agent 的時機**：
- 需要掃描多個獨立目錄或模組（互不依賴的探索）
- 單一 Phase 內有 ≥2 個可平行化的探索任務
- 專案規模較大（>10 個頁面或模組），串行分析耗時過長

**不使用 agent 的時機**：
- 分析單一檔案或小型模組（直接用 Read/Grep 即可）
- 任務之間有依賴關係（如需要 Phase 1 結果才能進行 Phase 2）
- 使用者僅問「這段 code 的規格是什麼」（範圍太小，不值得啟動 agent）

**agent 使用上限**：單一訊息中同時啟動的 agent 建議不超過 5 個，避免回傳結果過多難以整合。

## 隱性規則偵測與分級

在分析過程中，主動搜尋以下模式並以 🔴/🟡 分級標記。分級標準詳見 `references/implicit-rules-standard.md`。

**偵測清單**：

- `if (xxx === 數字)` 或 `if (xxx === '某字串')` → magic value
- `setTimeout` / `debounce` 的延遲數值 → 記錄用途與數值
- 硬編碼的 URL、路徑、設定值
- 對特定欄位排序的依賴
- 時區相關的運算
- 幣別或數字精度的處理
- 靜默截斷或轉換（如 `.slice()`、`.toFixed()`）
- 非同步呼叫的順序依賴
- 可復用邏輯單元（mixin / hook / service / utility 等）中的輸入過濾或資料轉換
- 字串匹配做路由或條件判斷（如 `url.includes('xxx')`），隱性假設 URL 結構
- 自定義非標準狀態碼或錯誤代碼（如應用層自定義的 HTTP-like 狀態碼）
- 多資料來源的同步機制（如持久層與記憶體狀態不一致時的同步策略）

**分級判斷**：問「如果有人在重構時忽略了它，會不會出 bug？」→ 會出 bug = 🔴，不會 = 🟡

**Why 記錄要求**：每條隱性規則必須附 Why（為什麼這樣設計），或標記 `[待確認]`。只描述 what 而不解釋 why 的規格文件，在 Why 記錄維度會被扣分。

## 可復用邏輯追蹤

分析目標模組時，若引用了可復用邏輯單元，**必須追蹤原始檔並展開其完整行為**。

### 原則

可復用邏輯單元是指任何被目標模組引入、且貢獻行為的外部程式碼，包括但不限於：
- 前端：mixin（Vue）、hook（React）、composable（Vue 3）、HOC、directive、shared component
- 後端：service、middleware、decorator、base class、utility module、interceptor、guard
- 通用：trait（Rust/PHP）、module include（Ruby）、protocol extension（Swift）

### 常見遺漏類型

| 類型 | 範例 |
|------|------|
| 輸入處理邏輯 | 正則過濾、格式限制、自動完成觸發 |
| 生命週期鉤子 | 初始化、銷毀、關閉前確認 |
| 資料轉換 | 加密傳輸、格式轉換、欄位重命名 |
| 錯誤處理 | 全域錯誤攔截、重試策略、fallback 邏輯 |
| 狀態副作用 | 自動同步、快取清除、事件發送 |

### 偵測方式

1. 搜尋目標檔案中的引入語句（import / require / include / use / extends / mixins / inject 等）
2. 過濾出非第三方套件的專案內部引用
3. 追蹤到原始檔，判斷是否包含行為邏輯（而非僅型別定義或常數）
4. 展開其中包含的行為（事件處理、資料轉換、狀態管理、錯誤處理）

## Edge Cases

| 情境 | 處理方式 |
|------|---------|
| **Monorepo** | 先問聚焦哪個 package |
| **Micro-frontend/service** | 每個服務獨立規格，額外記錄服務間通訊 |
| **混合 legacy**（新舊框架並存） | 分別記錄，標記遷移邊界 |
| **無原始碼** | 使用 `interview-questions.md` 延伸訪談 |
| **>15 模組** | 請使用者排優先級，分批處理 |

## 品質自查清單

產出規格文件後，用以下清單自我檢查：

- [ ] 以行為（而非檔案結構）為組織單位？
- [ ] 記錄了 why，而非只有 what？
- [ ] 標記了所有隱性規則（🔴/🟡 分級），每條附 Why 或 `[待確認]`？
- [ ] 可復用邏輯單元的互動行為已展開描述（非僅寫「使用了 XX」）？
- [ ] 若有表單：包含所有欄位的驗證規則？
- [ ] 若有狀態機：所有狀態與轉換都有記錄？
- [ ] 若有 API：包含錯誤情境和 Request 範例？
- [ ] 區分了「當前行為」和「預期行為」（可能有 bug 的地方）？
- [ ] QA 能直接根據文件撰寫測試案例？
- [ ] 設計決策有記錄 why 和 trade-off？
- [ ] 同名異義概念有明確標記？
- [ ] 格式符合 `document-conventions.md` 規範（mermaid、TOC、Confidence Markers）？
- [ ] 遇到無法從程式碼推斷的第三方套件行為時，已用 context7 或 WebSearch 查文件？
