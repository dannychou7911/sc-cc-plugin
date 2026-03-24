---
name: spec-recovery
description: >
  從棕地專案（brownfield project）的既有程式碼中回推、產生、補齊規格文件。
  適用於任何前端（Vue / React / Angular / 任意框架）與後端（Node.js / Python / Go / 任意語言）專案，
  不限定框架或語言。
  當使用者提到「回推規格」、「補規格書」、「產生規格文件」、「從 code 生成文件」、
  「reverse engineer spec」、「recover specification」、「建立文件」、
  「幫我寫規格」、「這段 code 的規格是什麼」、「分析這個模組」，
  或者使用者給了一段程式碼或一個專案目錄要求產出文件時，都應觸發本技能。
  也適用於使用者想對某個特定檔案、元件、API、模組產生規格描述的情境。
  即使使用者只說「幫我看看這段 code」但上下文暗示需要文件化，也應主動觸發。
  Chinese triggers: "規格書", "規格文件", "產生規格", "文件化", "棕地專案", "逆向工程文件"
---

# Spec Recovery — 棕地專案規格回推技能

## 核心理念

從既有程式碼中萃取結構化規格文件，讓團隊能理解、維護、並安全修改系統。

### 三個關鍵原則

1. **行為導向，非檔案導向**（BDD）：以「使用者或系統能做什麼」為分析單位，而非「這個檔案做了什麼」。行為規格的生命週期遠長於實作細節。
2. **記錄 Why，而非 What**（ADR）：程式碼本身就是 what，規格要補的是 why（為什麼這樣做）和 what should be（預期行為——當前行為可能包含 bug）。
3. **漸進式產出**（Legacy Code）：不追求一次補齊所有規格。優先處理高風險、高變動頻率的模組，用「碰到就補」的策略持續累積。

### 範圍限制

本技能**只產出規格文件**，不執行以下工作：
- 不撰寫或修改程式碼（包括測試程式碼、重構建議的實作）
- 不執行 CI/CD、部署、或環境設定
- 不產生 API mock、stub、或測試資料
- L4 的註解建議以清單形式呈現，不直接寫入程式碼

### 方法論基礎

| 方法論 | 採用的概念 |
|--------|-----------|
| BDD | 以行為為單位拆解功能，Given-When-Then 思維萃取行為 |
| DDD 戰略設計 | Bounded Context、模組邊界識別、同名異義概念辨識 |
| Specification by Example | 活文件策略、規格與程式碼共同演進 |
| Architecture Decision Records | 記錄決策的 why 與 trade-off（系統級 + 模組級） |
| Working Effectively with Legacy Code | 漸進式策略、安全網思維、識別測試接縫 |
| C4 Model | 文件分層（L0-L4），不同粒度給不同受眾 |

---

## 工作流程

根據使用者的請求範圍，選擇合適的起始階段。整個專案從 Phase 0 開始；單一模組或功能可從 Phase 2 或 Phase 3 開始。

```
Phase 0: 既有文件掃描        ← 掃描專案內已有的文件作為參考
  ↓
Phase 1: 全局地圖 (L0)
  ↓
Phase 2: 模組拆解 (L1)       ← 含模組級決策考古
  ↓
Phase 3: 功能行為拆解 (L2)   ← 投資報酬率最高
  ↓
Phase 4: API 契約 (L3)
  ↓
Phase 5: 程式碼內文件建議 (L4) ← 含活文件維護策略
```

### Phase 結束流程

每個 Phase 結束後依序執行以下三步驟（後續以「執行 Phase 結束流程」引用）：

1. **待確認項目確認**：對文件中所有 `[待確認]` 項目，使用 `AskUserQuestion` 工具逐一向使用者確認，將回答寫回文件（更新為 `[確認]` 或 `[未確定]`）
2. **Q&A 協議**：執行 `references/qa-protocol.md`（含業務脈絡收集、補充 Q&A）
3. **Context 壓縮檢查**：使用 `strategic-compact` skill 評估是否需要壓縮，若建議壓縮則執行 `/compact`。若使用者環境缺少 `strategic-compact` skill 或 `/compact` command，提醒使用者補上

### Phase 間銜接原則

每個 Phase 開始時（或從中斷處恢復時）：
1. **先讀取 `docs/spec-recovery-progress.md`** — 必讀「工作偏好」和「待處理項目」，「歷史紀錄」可跳過
2. **再讀取前一個 Phase 已產出的文件**（如 `docs/L0-system-overview.md`）— 取得分析基礎
3. 從進度檔中第一個未完成（⬚ 或 🔄）的項目繼續

### 平行探索策略

使用 Agent tool（`subagent_type: "Explore"`）平行化獨立的探索任務，大幅縮短分析時間。

**原則**：
- 同一 Phase 內互不依賴的探索任務，用多個 Explore agent **同時啟動**（單一訊息多個 Agent tool call）
- 每個 agent 給予明確的探索範圍與結構化回傳格式
- 主 agent 負責整合結果、撰寫最終文件
- 探索深度指定為 `"very thorough"`，確保不遺漏

**檔案讀取策略**（漸進式，節省 context）：

```
Glob（找檔案）→ Grep（找關鍵模式，定位行號）→ Read(limit: 1200)（預覽前 1200 行）→ 確認相關才完整讀取
```

- 預設使用 `Read(limit: 1200)` 預覽檔案，不要一次讀取整個檔案
- 若預覽後確認該檔案與分析目標相關，再用 `offset` + `limit` 讀取剩餘部分
- 優先用 Grep 定位關鍵行號（如特定函式、API 呼叫），再用 `offset` 精準讀取片段
- 框架特定的讀取策略，參見對應 reference 檔案

**Agent prompt 模板**：

```
分析 {專案路徑} 的 {探索目標}。

檔案讀取規範：
- 使用 Glob 找出目標檔案，用 Grep 定位關鍵模式
- 預設用 Read(limit: 1200) 預覽，確認相關才完整讀取
- 超過 1200 行的檔案，用 offset + limit 讀取剩餘部分

可復用邏輯追蹤：
- 若目標檔案引用了可復用邏輯單元（mixin、hook、composable、service、utility、base class、decorator、HOC 等），必須追蹤原始檔並展開其完整行為
- 特別注意互動行為（輸入過濾、自動提交、焦點管理、鍵盤事件處理、資料轉換）

流程圖使用 mermaid.js flowchart 語法繪製。

回傳以下結構：
## 發現
- （條列式發現）
## 隱性規則
- 🔴 {規則描述}（Why：{為什麼這樣設計}）（忽略會導致：{後果}）
- 🟡 {規則描述}（Why：{為什麼}）
- 若無法從程式碼判斷 Why，標記 [待確認]
（分級標準見 references/implicit-rules-standard.md）
## 待確認
- （無法從程式碼確定的項目）
```

所有產出存放於專案 `docs/` 目錄下：

```
docs/
├── spec-recovery-progress.md   ← 進度追蹤（必須維護）
├── L0-system-overview.md
├── L1-modules/
│   └── {module-name}.md
├── L2-features/
│   ├── {feature-name}.md
│   └── shared-{component-name}.md  ← 使用 ≥2 頁面的共用元件
├── L3-api/
│   ├── api-inventory.md
│   └── {domain}.md
└── L4-code-notes/
    └── (建議清單或 PR 形式)
```

### 進度追蹤

維護 `docs/spec-recovery-progress.md` 追蹤所有任務的完成狀態。詳見 `references/progress-tracking.md`。

**核心規則**：
- Phase 1 完成後建立進度檔
- **每產出一份文件後，必須立即更新進度檔**
- 使用者偏好記錄到進度檔的「工作偏好」區塊，里程碑記錄到「歷史紀錄」區塊
- 恢復工作時先讀取進度檔，從未完成項目繼續

### 檢查點機制

每個 Phase 的**第一份文件**完成後，暫停並用 `AskUserQuestion` 確認粒度、格式、方向是否符合使用者需求。通過後再批量處理剩餘項目。將確認結果記錄到進度檔的「工作偏好」區塊。

---

### Phase 0：既有文件掃描（Existing Documentation Scan）

**目標**：在分析程式碼之前，先掃描專案內已存在的文件，作為後續分析的輔助參考。

**執行步驟**：

1. 用 Glob 掃描常見文件位置與格式：
   - `README.md`、`docs/**/*.md`、`wiki/**/*`
   - `*.swagger.json`、`*.openapi.yaml`、`openapi/**/*`
   - `ARCHITECTURE.md`、`DESIGN.md`、`CHANGELOG.md`
   - `*.api.md`、`api-docs/**/*`
   - `CLAUDE.md`（專案特定指引）
   - 使用者額外提供的文件路徑
2. 用 Grep 掃描是否有行內設計註解（如 `@description`、`@design`、`@architecture`）
3. 整理為**參考資料清單**，標記每份文件的類型與涵蓋範圍
4. 在後續 Phase 分析時，交叉比對程式碼行為與既有文件描述，標記**文件與實作不一致**之處

**產出**：參考資料清單（不獨立輸出檔案，併入 L0 文件的附錄）。

> 若專案無任何既有文件，跳過此 Phase 直接進入 Phase 1。

---

### Phase 1：全局地圖（System Inventory）

**目標**：建立系統鳥瞰圖，識別所有入口點、邊界、與架構決策。

**執行步驟**（⚡ 標示可平行化的步驟）：

使用 4 個 Explore agent 同時啟動以下探索任務：

| Agent | 探索任務 | 掃描範圍 |
|-------|---------|---------|
| ⚡ Agent A | 技術棧與第三方依賴 | package.json / requirements.txt / go.mod、config 檔 |
| ⚡ Agent B | 前端入口點（路由定義、頁面清單） | 路由設定檔、pages/ 目錄結構 |
| ⚡ Agent C | 後端入口點（API route、controller） | server/、api/、controller/ 目錄 |
| ⚡ Agent D | 資料模型（型別定義、DB migration、ORM model） | types/、models/、migration/、schema 相關檔案 |

主 agent 整合 4 個結果後：
5. 繪製模組清單與依賴關係
6. **系統級決策考古**：記錄可觀察到的架構決策（技術選型、通訊方式、部署架構），嘗試推斷 why

**產出**：L0 系統概觀文件。讀取 `references/templates-L0.md` 取得模板。產出前檢查「文件通用規範」（mermaid、🔴/🟡 分級、TOC）。產出後執行「品質檢查與評分」（含啟動 `spec-scorer` agent）。

**業務脈絡收集**：Phase 1 Q&A 時，根據分析發現主動收集全局業務脈絡（見 `references/qa-protocol.md`「業務脈絡收集」）。

**Confidence Tagging**：每項發現標記信心度：
- `[確認]` — 程式碼明確顯示
- `[推斷]` — 從程式碼模式合理推論
- `[待確認]` — 無法僅從程式碼判斷

> Phase 1 是「施工鷹架」，快速完成比精確更重要。

---

### Phase 2：模組拆解（Module Decomposition）

**目標**：針對每個模組，定義職責、邊界、資料流、對外依賴、以及設計決策。

**執行步驟**（⚡ 標示可平行化的步驟）：

⚡ **平行分析各模組**：為每個模組啟動獨立的 Explore agent（建議同時不超過 5 個），每個 agent 負責回答：
   - 這個模組**負責什麼**？（職責）
   - 這個模組**不負責什麼**？（邊界——同樣重要）
   - 資料從哪裡進來、到哪裡去？（資料流）
   - 依賴哪些其他模組？被哪些模組依賴？（依賴關係）
   - 是否包含狀態機？若有，列出所有狀態與轉換
   - 有無 workaround、異常模式、特殊判斷？（決策考古）

主 agent 整合各模組結果後：
1. **同名異義辨識**（DDD）：如果同一個詞（如「訂單」「使用者」）在不同模組中有不同含義，明確標記
2. 整理跨模組依賴關係圖

**產出**：L1 模組規格文件。讀取 `references/templates-L1.md` 取得模板。產出前檢查「文件通用規範」（mermaid、🔴/🟡 分級、TOC）。產出後執行「品質檢查與評分」（含啟動 `spec-scorer` agent）。

---

### Phase 3：功能行為拆解（Feature Behavior Decomposition）

**目標**：以使用者或系統行為為單位，產出可直接轉化為測試案例的功能規格。這是投資報酬率最高的階段。

**執行步驟**（⚡ 標示可平行化的步驟）：

⚡ **平行分析各頁面/功能**：為每個頁面或功能啟動獨立的 Explore agent（建議同時不超過 5 個），每個 agent 用以下框架分析：
   - **進入條件**：路由、認證、角色限制
   - **初始載入行為**：進入時發生什麼？呼叫哪些 API？成功/失敗各如何？
   - **使用者操作**：逐一列舉所有可操作項目，每個操作的觸發條件、行為、結果
   - **可復用邏輯追蹤**：目標模組引用的可復用邏輯單元（如 mixin、hook、composable、service、utility、base class、decorator、HOC 等），若包含互動行為（如輸入過濾、自動提交、焦點管理、資料轉換），必須追蹤原始檔並展開分析其完整行為，不可僅描述「使用了 XX」
   - **條件渲染規則**：哪些 UI 元素在什麼條件下出現/隱藏
   - **錯誤處理**：各種錯誤情境的處理方式
   - 若為表單功能：欄位型別、必填性、驗證規則、送出流程、離開防護
   - 標記所有**隱性規則**（🔴/🟡 分級），**每條規則必須附 Why**（為什麼這樣設計）或標記 `[待確認]`。分級標準見 `references/implicit-rules-standard.md`
   - 若有**共用元件**（使用 ≥2 頁面 + 有非平凡行為），為其建立獨立 L2 文件（如 `shared-change-password.md`），頁面文件改為引用

**業務脈絡收集**：每個模組的 Phase 3 開始前，根據 L1 文件中的發現，收集該模組的業務語義（見 `references/qa-protocol.md`「業務脈絡收集」）。

**產出**：L2 功能規格文件。讀取 `references/templates-L2.md` 取得模板。產出前檢查「文件通用規範」（mermaid、🔴/🟡 分級、TOC）。產出後執行「品質檢查與評分」（含啟動 `spec-scorer` agent，需額外執行 B 可測試性評分）。

> 框架特定的萃取技巧，根據偵測到的技術棧載入對應參考文件：
> - Vue 2 / Nuxt 2 專案：讀取 `references/vue2-nuxt2-patterns.md`
> - Vue 3 專案：讀取 `references/vue3-patterns.md`
> - React 專案：讀取 `references/react-patterns.md`
> - NestJS / Node.js 後端：讀取 `references/nestjs-patterns.md`

---

### Phase 4：API 契約（API Contract）

**目標**：記錄前後端之間的資料契約，特別是隱性假設。

**執行步驟**（⚡ 標示可平行化的步驟）：

⚡ 使用 2 個 Explore agent 同時掃描：

| Agent | 探索任務 |
|-------|---------|
| ⚡ Agent A | 前端 API 呼叫層：掃描所有 API 呼叫（axios/fetch），整理端點清單、請求參數、回應處理 |
| ⚡ Agent B | 後端 API 定義：掃描 server/api/ 目錄，整理路由、middleware、handler、回應格式 |

> 若後端不在分析範圍內，僅啟動 Agent A 從前端反推。

主 agent 整合後：
1. 合併為完整 API 端點清單（方法、路徑、認證、角色）
2. 對每支 API 記錄：請求參數、回應格式、錯誤碼
3. 標記前後端契約中的**隱性假設**：命名轉換、分頁資訊位置、日期格式、數值精度

**產出**：L3 API 規格文件。讀取 `references/templates-L3.md` 取得模板。產出前檢查「文件通用規範」（mermaid、🔴/🟡 分級、TOC）。產出後執行「品質檢查與評分」（含啟動 `spec-scorer` agent）。

---

### Phase 5：程式碼內文件建議 + 活文件策略（Code-Level Documentation）

**目標**：識別需要但缺少的行內註解，並建立讓規格文件「活下去」的策略。

**執行步驟**（⚡ 標示可平行化的步驟）：

⚡ 使用 2 個 Explore agent 同時掃描：

| Agent | 探索任務 |
|-------|---------|
| ⚡ Agent A | 掃描需要註解的程式碼段落：複雜業務邏輯、Workaround/Hack、非顯而易見的副作用、magic number |
| ⚡ Agent B | 靜態掃描測試覆蓋狀況（不執行測試）：比對測試檔與源碼檔的對應關係，識別無測試覆蓋的高風險區域，產出測試接縫（test seam）建議清單 |

主 agent 整合後：
1. 建議標準化標記：TODO、FIXME、HACK、NOTE、@see、@since
2. **活文件維護策略**：根據專案技術棧，建議讓規格與程式碼同步演進的具體做法

**產出**：L4 程式碼註解建議。讀取 `references/templates-L4.md` 取得模板與標記規範。產出前檢查「文件通用規範」（mermaid、🔴/🟡 分級、TOC）。產出後執行「品質檢查與評分」（含啟動 `spec-scorer` agent）。

---

## 分析策略

詳見 `references/analysis-strategy.md`（含前端/後端分析順序、Sub-agent 使用時機、隱性規則偵測清單）。

---

## 互動模式

> **重要**：所有需要使用者回答的問題（模組優先級、確認項目、Q&A 問題等），必須使用 `AskUserQuestion` 工具提問，不要用普通文字輸出。這讓使用者能清楚辨識需要回應的地方，避免問題被分析文字淹沒。

### 使用者給了整個專案

1. 執行 Phase 0 掃描專案內既有文件
2. 執行 Phase 1 產出全局地圖（參考 Phase 0 結果）
3. 執行 Phase 結束流程
4. 向使用者確認：「以下是我識別出的模組清單，你想優先分析哪些模組？」
5. 根據使用者選擇，依序執行 Phase 2 → 3 → 4 → 5（每個 Phase 開始時先讀取前一個 Phase 的產出檔案）
6. 每個 Phase 結束後執行 Phase 結束流程

### 使用者選擇特定模組深入分析

適用於 Phase 1-2 已完成，使用者想針對單一模組走完 Phase 3→4→5 的情境。

1. 讀取進度檔，確認 Phase 1-2 已完成
2. 讀取該模組的 L1 文件，取得頁面/功能清單
3. 針對該模組依序執行 Phase 3 → 4 → 5
4. Phase 4/5 僅掃描該模組相關的 API 和程式碼（非全專案）
5. 每個 Phase 結束後執行 Phase 結束流程

### 使用者給了單一檔案或模組

1. 跳過 Phase 1，直接從 Phase 2 或 Phase 3 開始
2. 產出對應層次的規格
3. 如果發現依賴其他模組資訊，主動提示使用者是否要一併分析

### 使用者問「這段 code 的規格是什麼」

1. 判斷程式碼性質（頁面元件？API handler？工具函式？）
2. 選擇最適合的層次模板
3. 直接產出規格，不需走完整流程

### 無原始碼（僅口述或截圖）

跳過所有 Phase，使用 `references/interview-questions.md` 進行延伸訪談，根據回答建構規格。

---

## 品質檢查與評分

產出規格文件後，依序執行：

1. **自我檢查**（主 agent）：依 `references/analysis-strategy.md`「品質自查清單」和 `references/document-conventions.md` 檢查格式規範
2. **啟動 `spec-scorer` agent 評分**：使用 Agent tool 啟動 `spec-scorer` 自訂 agent（`subagent_type` 不需指定，直接用 agent name `spec-scorer`）。Prompt 需提供：待評文件路徑、文件層次（L0-L4）、模板格式要求摘要、原始碼目錄路徑、是否啟動差異驗證（C 評分）。模板格式要求可引用 `references/template-summaries.md`，或自行讀取對應 `references/templates-L{N}.md` 後摘要（因 sub agent 無法讀取 skills 目錄）
3. **差異驗證自動啟用規則**：涉及認證/權限/敏感資料的高風險模組、L2 文件、A 評分 < 70 的文件，必須啟動 C 評分
4. **後續處理**：≥ 70 通過（記錄分數到進度檔）；60-69 補強最弱 1-2 個維度後重新評分；< 60 重做。修正時必須回到原始碼重新驗證（不憑記憶修正），重新評分必須啟動新的 spec-scorer agent（不可自我評分）。二次評分仍 < 70 則用 `AskUserQuestion` 請人工介入。將**最終分數**記錄到進度檔對應表格

詳細的評分維度、權重矩陣、Prompt 範例、修正流程、進度檔記錄格式，見 `references/scoring-rubric.md`。

---

## 文件通用規範

所有 L0–L4 產出文件的格式規範（Header、TOC、Confidence Markers、mermaid、隱性規則標記、語言）詳見 `references/document-conventions.md`。

產出前必須對照該規範檢查。

## Edge Cases

專案結構特殊情境（Monorepo、Micro-frontend、混合 legacy 等）的處理方式，詳見 `references/analysis-strategy.md`「Edge Cases」。
