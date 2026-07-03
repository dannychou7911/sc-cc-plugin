# spec-recovery Skill 改版修改計畫

> **目標 skill**：`skills/spec-recovery/`（含 `agents/spec-scorer.md`）
> **計畫狀態**：已與使用者逐項確認定案，可直接實作
> **實作方式**：交由 skill-creator 執行，依階段 A → E 順序進行
> **Commit 策略**：每階段一個 conventional commit（`feat:` / `fix:` / `refactor:`），footer 不填 scope

## 已定案決策

| 決策點 | 結論 |
|--------|------|
| 輸出路徑相容 | 沿用舊佈局：偵測到 `docs/spec-recovery-progress.md`（舊路徑）存在則繼續用 `docs/`；全新專案用 `docs/specs/` |
| 評分 agent 拆分 | 拆成兩個：`spec-scorer`（sonnet，A/B 評分）＋ `spec-verifier`（不指定 model、繼承 session model，C 差異驗證） |
| 範圍外項目 | 黃金專案回歸測試（延後至真實專案跑完後）；重複 skill 清理（使用者自行處理） |

---

## 階段 A：安全與基礎修正

### A1. 敏感資料遮罩

- **`references/document-conventions.md`**：新增「敏感資料遮罩」硬規則區塊：
  - 環境變數值、API key/token、密碼、連線字串、內部主機名/IP 一律遮罩
  - 遮罩格式範例：`sk-****`、`{已遮罩}`；主機只保留角色描述（如「內部 API gateway」）
  - 違反視為格式規範不合格（納入 C1 的 checklist 扣分項）
- **`references/templates-L0.md`**：環境變數表格的「範例值」欄改為「格式說明」，明註「禁止填入真實值」
- **`SKILL.md` Agent prompt 模板**：加入遮罩指示行（實際讀 `.env` 的是 Explore agent，規範必須進 prompt 它們才看得到）

### A2. 分析基準 commit SHA 與增量更新

- **`references/document-conventions.md`**：Header 規範新增一行 `> **分析基準**：{git short SHA}`
- **`references/templates-L0.md` ~ `templates-L4.md`**：各模板的 Header 範例同步加此欄位
- **`SKILL.md`**：互動模式新增「**更新既有規格**」：
  1. 讀取進度檔與文件 header 的基準 SHA
  2. `git diff <sha>..HEAD --stat` 判斷哪些模組的文件已過期
  3. 只重分析變動範圍，更新文件後刷新 header SHA

### A3. 輸出目錄改為 `docs/specs/`

- **`SKILL.md`**：
  - 產出目錄樹全面改為 `docs/specs/`（進度檔 → `docs/specs/spec-recovery-progress.md`）
  - 相容規則：恢復工作時若偵測到舊路徑進度檔（`docs/spec-recovery-progress.md`）存在，沿用 `docs/` 舊佈局，不搬移
  - Phase 0 掃描規則加排除條款：**排除 `docs/specs/`**（舊佈局專案則排除進度檔中已登記的產出檔案），避免重跑時把自己的產出當成既有文件
- **`references/progress-tracking.md`**：路徑同步更新，加相容說明

### A4. 兩個小 bug 修正

- **`references/qa-protocol.md`**：「3-5 個問題」改為「3-4 個」（共兩處：工具要求段落、第三部分第 3 節標題與內文），並註明 `AskUserQuestion` 單次上限為 4 題
- **`references/progress-tracking.md`**：「何時更新」清單的重複編號修正（目前 7、8 之後又出現 7）

---

## 階段 B：分析能力增強

### B1. Git 考古（Why 的第三來源）

- **`SKILL.md` Phase 0**：新增「git 考古」步驟——掃 `git log` 概覽與 tag、辨識 commit 慣例（如 footer 票號格式），記入參考資料清單
- **`references/analysis-strategy.md`**：新增「Git 考古」章節：
  - **適用範圍**：僅限 🔴 隱性規則與 `[待確認]` 的 Why（成本控制，不逐行 blame）
  - **流程**：`git blame` 定位目標行 → `git log` / `git show` 讀 commit message → 抽取票號 → GitLab MCP 可用時進一步抓 MR 描述與討論串
  - **證據格式**：Why 後附來源，如 `（來源：commit abc1234 / MR !123）`
- **`references/qa-protocol.md`**：「待確認項目確認」加前置步驟——先跑 git 考古，有找到來源的項目直接升級為 `[推斷]` / `[確認]` 附證據，僅剩餘項目才問使用者
- **`SKILL.md` Agent prompt 模板**：加入「隱性規則無法判斷 Why 時，先 git blame 該行追溯 commit message」指示

### B2. i18n 檔案作為行為側寫

- **`references/analysis-strategy.md`**：新增「i18n 作為行為側寫」章節，明訂三條規則：
  1. **單向性**：i18n 只是補充訊號，程式碼是 source of truth；**不得**以 i18n 缺漏判定功能未做錯誤處理
  2. i18n 有錯誤訊息 key → 反查程式碼觸發點 → 補全 L2「錯誤處理」表格
  3. 孤兒 key（i18n 有、程式碼無引用）→ 死碼/棄用功能訊號，標 `[待確認]`
- **`SKILL.md` Phase 0**：掃描目標加入 locale 檔案位置記錄（供 Phase 3 使用）

### B3. 死碼與已棄用功能預先偵測

- **`references/analysis-strategy.md`**：新增偵測方法——route 定義了但無導覽入口、export 了但無人 import、註解暗示棄用
- **`references/qa-protocol.md`**：業務脈絡收集的「已廢棄但保留的功能」類別改為引用偵測結果，把開放式問題（「有沒有廢棄功能？」）轉為具體確認題（「`/legacy-report` 無任何入口指向，是廢棄了嗎？」）

### B4. 從 diff/MR 出發的互動模式

- **`SKILL.md` 互動模式**新增「從 diff/MR 出發」：
  1. 取得 diff（`git diff <base>...HEAD` 或透過 GitLab MCP 取 MR）
  2. 識別受影響檔案 → 對應到功能/模組，並追 blast radius（哪些模組引用了變更檔案）
  3. 執行範圍限定的 Phase 3（若變更涉及 API 層檔案，加 Phase 4）
  4. 已有規格文件 → 走「更新既有規格」模式（配合 A2 的 SHA 機制）；沒有 → 新建

---

## 階段 C：評分系統改造

### C1. 兩個維度 checklist 化（維持 6 維度與權重矩陣不變）

- **`agents/spec-scorer.md`**（E2 後為執行規格唯一來源）：
  - 「**格式規範**」改為 checklist 通過率取分：Header 完整（含分析基準 SHA）、TOC、mermaid、Confidence Marker、敏感遮罩合規。換分規則：100%=5、≥80%=4、≥60%=3、≥40%=2、<40%=1
  - 「**隱性規則覆蓋**」拆兩半：
    - **格式面**（每條規則有 🔴/🟡 分級、附 Why 或 `[待確認]`）→ checklist 通過率取分，同上換分
    - **覆蓋面**（有沒有漏抓規則）→ 移交 C 差異驗證負責，A 評分不再主觀猜測
  - 其餘 4 維度（完整性、準確性、Why 記錄、受眾適配）維持 1-5 量表；權重矩陣不變

### C2. 分層評分、C 抽樣、agent 拆分

- **新增 `agents/spec-verifier.md`**：
  - 只做 C 差異驗證；內容從現有 spec-scorer 的「C. 差異驗證評分」＋「檔案讀取規範」章節搬移
  - `tools: ["Read", "Grep", "Glob", "LSP"]`；**不指定 model**（繼承 session model，因 C 是獨立重讀程式碼盤點行為，是最難的任務）
- **`agents/spec-scorer.md`**：移除 C 章節，保留 A/B；`model: sonnet` 不變
- **`SKILL.md`「品質檢查與評分」章節**改寫：
  - 每個 Phase **首份文件**：A + B（L2）+ C 全套（與現有首份文件檢查點對齊）
  - 後續文件：只跑 A
  - **C 觸發規則**：高風險 L2（認證/權限/金額）強制；一般 L2 每 3 份抽 1 份；A < 70 時作為診斷工具；抽樣發現 ≥3 個高風險遺漏 → 同批文件全跑 C
  - C 由 `spec-verifier` 執行、A/B 由 `spec-scorer` 執行

### C3. B 可測試性公式防「少寫」

- **有跑 C 時**：`B = 驗收場景數 / max(文件描述行為數, C 盤點的程式碼行為數)`
- **沒跑 C 時**：維持原公式，但評分輸出**強制加註**「未經 C 校準，僅反映已描述行為的品質，不反映覆蓋度」
- 配合 D1：分子從「scorer 估計可衍生數」改為「實際產出的 GWT 場景數」（客觀計數）
- 修改位置：`agents/spec-scorer.md` 的 B 章節

---

## 階段 D：產出價值提升

### D1. Given-When-Then 驗收場景

- **`references/templates-L2.md`**：模板 A/B/C/D 各新增「驗收場景（Given-When-Then）」章節：
  - 涵蓋主成功路徑＋錯誤路徑＋邊界情況，Gherkin 格式
  - 沿用 Confidence Marker；場景基於**當前行為**，若當前行為疑似 bug 必須標註（避免 QA 把 bug 當驗收標準）
- **`SKILL.md` 檢查點機制**：首份 L2 文件完成時，用 `AskUserQuestion` 詢問是否需要場景產出，答案記入進度檔「工作偏好」

### D2. Swagger 比對優先（Phase 4 分流）

- **`SKILL.md` Phase 4**加入分流邏輯：
  - **Phase 0 掃到後端 swagger/openapi** → L3 工作從「反推」變成「**比對**」：前端呼叫層假設的契約 vs swagger 宣告的契約做 diff，差異填入 L3 既有的「模板 C：前後端契約差異追蹤表」
  - **無 swagger** → 照現行反推，並**可選**產出 OpenAPI YAML，header 強制標註「由前端呼叫端反推，非後端宣告，僅代表前端消費的子集」
- **`references/templates-L3.md`**：產出指引補上兩種模式的說明

### D3. 跨文件一致性檢查

- **`SKILL.md`**：兩個執行時機——模組完成驗收時（模組範圍）、全專案收尾時（全域）
- **機械級檢查（必跑，主 agent 用 Grep 比對，不需 LLM）**：
  1. L2 文件提到的 API 端點（方法＋路徑）都存在於 L3 api-inventory
  2. L0 模組清單 ↔ L1 檔案一一對應（或標記延後）；L1 頁面清單 ↔ L2 檔案對應
  3. 文件間相對連結（如 `shared-xxx.md` 引用）指向存在的檔案
- **LLM 級檢查（選跑，輕量 agent）**：術語跨文件一致性、L1 狀態機的狀態值與 L2 條件／L3 enum 一致性
- 不一致項標 `[待確認]` 併入既有 Q&A 流程；結果記入進度檔「待處理項目」

### D4. 權限矩陣

- **`references/templates-L3.md`**：新增「模板 D：權限矩陣」——兩張表：「頁面 × 角色」（來源：各 L2 進入條件）、「API × 角色」（來源：L3 角色限制欄位），格內填 ✓/✗/條件式
- **`SKILL.md` Phase 4 產出**：每模組完成 Phase 4 後增量更新 `docs/specs/L3-api/permission-matrix.md`
- 矩陣拼合後的**前後端權限不一致**（頁面允許但 API 拒絕、API 開放但無頁面入口）自動列入隱性規則清單

---

## 階段 E：單一事實來源清理

### E1. template-summaries.md 的去留（先驗證再動手）

1. **驗證步驟**：啟動 spec-scorer agent，prompt 中給 `references/templates-L2.md` 的**絕對路徑**，確認 sub-agent 能用 Read 讀到 skills 目錄下的檔案
2. **可行** → `SKILL.md`「品質檢查與評分」步驟 2 改為「主 agent 將對應 `templates-L{N}.md` 與 `document-conventions.md` 的絕對路徑寫入 scorer prompt，由 scorer 自行讀取」；**刪除 `references/template-summaries.md`**
3. **不可行** → 保留 summaries，僅在檔頭強化同步提醒與檢查機制

### E2. 評分標準分工明確化

- **`agents/spec-scorer.md`** ＝ 執行規格唯一來源（維度定義、checklist、權重矩陣、換分規則、輸出格式）
- **`references/scoring-rubric.md`**：刪除複製的執行規格，只保留方法論內容（權重設計理由、IEEE 29148 等方法論對照表、修正流程說明），檔頭註明「執行版以 `agents/spec-scorer.md` 與 `agents/spec-verifier.md` 為準」

---

## 收尾

- **`README.md`**：更新元件清單（新增 `spec-verifier` agent；若 E1 驗證通過則移除 `template-summaries.md` 的相關描述）
- 實作完成後可用 `plugin-dev:skill-reviewer` 做一次品質審查
- `SKILL.md` frontmatter 的 `description`（觸發條件）**不需修改**

## 驗收清單

- [ ] A：conventions 有遮罩規則與基準 SHA 欄位；L0 模板範例值欄已改；SKILL.md agent prompt 含遮罩指示；docs/specs/ 與舊佈局相容規則已寫入；qa-protocol 上限改 3-4；progress-tracking 編號正確
- [ ] B：analysis-strategy 新增 Git 考古／i18n／死碼偵測三章節（含單向性規則與成本限定）；qa-protocol 有 git 考古前置；SKILL.md 有「更新既有規格」與「從 diff/MR 出發」兩個互動模式
- [ ] C：spec-scorer 無 C 章節、兩維度 checklist 化、B 公式含 max 分母與未校準加註；spec-verifier 存在且無 model 欄位；SKILL.md 有分層評分與 C 抽樣規則
- [ ] D：templates-L2 四個模板都有驗收場景章節；SKILL.md Phase 4 有 swagger 分流與權限矩陣增量更新；一致性檢查（機械 3 項必跑）掛在模組驗收與全專案收尾
- [ ] E：驗證結果已記錄；scoring-rubric 只剩方法論並指向 agent 定義；template-summaries 依驗證結果處理
- [ ] 收尾：README 已更新；每階段一個 conventional commit
