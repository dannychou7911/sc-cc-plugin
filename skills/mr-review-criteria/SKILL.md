---
name: mr-review-criteria
description: Merge Request 審閱回饋的評估判準與報告格式 — 採納程度分級、優先度分級、影響範圍檢查清單、修正方案原則與標準報告結構。凡是要評估 Code Review 意見、判斷 Reviewer Concern 是否成立、決定修正優先度、或產出 MR / PR 審閱分析報告時都要使用這個 Skill，包含 review comment 分析、code review 嚴重度分級、以及任何需要區分「Concern 是否成立」與「Solution 是否適合」的情境。
---

# MR Review 評估判準

這份 Skill 定義評估 Code Review 意見時共用的判準與輸出格式，供 `/review-mr`、`code-reviewer`、`comment-reviewer` 等 Command 與 Sub-agent 共同使用，確保分級標準一致。

## 核心原則

- Reviewer Comment 是需要驗證的輸入，不是既定事實。
- 必須先理解 MR 設計意圖與最新程式碼，再評估 Review Feedback。
- 必須區分 **Reviewer Concern 是否成立** 與 **Reviewer Solution 是否合適**。Concern 成立不代表必須採用 Reviewer 的實作方式。
- 不要只分析單一 Diff Line，必要時追蹤相關 Caller、Consumer 與 Data Flow。
- 分析範圍僅擴大到足以驗證 Concern，不進行無目的 Repository 掃描。
- 分析深度應與問題風險成比例。
- 修正方案以解決 Concern 的最小必要修改為原則。
- 避免 Scope Creep、無關 Refactor 與過度 Abstraction。
- Correctness 與 Regression Safety 優先於 Readability、Naming 與 Code Style。
- 無足夠證據時標示「無法驗證」，不要自行假設。

分析決策順序：

**MR Context → Reviewer Concern → 驗證問題 → 分析影響 → 評估 Solution → 比較替代方案 → 最小安全修改 → 修正優先度**

## 影響範圍檢查清單

判定每項 Concern 與其修正方案是否影響：

功能行為、商業邏輯、UI / UX、API 介面、State Management、Shared Component、Composable、Service、Type Definition、Test、Performance、Maintainability、Architecture。

另外確認：

- 是否影響其他 Caller / Consumer
- 是否改變 Public API 或 Component Contract
- 是否需要同步修改 Type
- 是否需要新增或調整 Test
- 是否可能產生 Regression
- 是否可能造成連鎖修改

影響程度分為 **Direct Impact** / **Indirect Impact** / **No Meaningful Impact**。

## 合宜性評估角度

Correctness、Readability、Maintainability、Performance、Consistency、Architecture、Team Convention、Type Safety、Test Coverage、Scope。

## 採納程度（五級）

- **接受** — Concern 成立，Reviewer Solution 合理，修改收益高於風險。
- **部分接受** — Concern 成立，但 Reviewer Solution 不是最佳方案，應提出更符合現有設計的替代方案。
- **不建議接受** — Concern 不成立，或修改會造成額外複雜度、Regression、Architecture 衝突或 Scope Creep。
- **無需修改** — 問題已由最新程式碼修正，或現有機制已提供等效處理。
- **無法驗證** — 缺少必要 Context，無法可靠形成結論。

Concern 成立但 Solution 不適合時：接受 Concern、明確指出不採用原 Solution 的原因、提出更小或更符合現有 Architecture 的替代方案。

## 優先度（三級）

依實際風險分類，不依 Comment 出現順序。

**Blocking** — 可能造成功能錯誤、Business Logic 錯誤、Data Corruption、Security Issue、Regression、Breaking Change、Runtime Error。應優先修正。

**Recommended** — 不一定直接造成錯誤，但明顯改善 Maintainability、Type Safety、Test Coverage、Architecture Consistency，或屬明確 Technical Debt。原則上建議在本 MR 處理。

**Optional** — Naming、Style、Minor Readability、非必要 Refactor、個人偏好且不影響品質。除非修改成本極低，否則避免擴大 MR Scope。

## 修正方案原則

- 優先採用能解決 Concern 的最小必要修改。
- 優先沿用現有 Architecture、Pattern 與 Team Convention。
- 不因 Review Comment 順便進行無關重構。
- 不進行與 Concern 無關的大規模 Rename。
- 不任意重新設計 Architecture。
- 不因追求「更乾淨」而增加不必要 abstraction。
- Reviewer Solution 造成較大修改時，優先評估是否存在較小範圍方案。

修正優先順序：

**Correctness / Regression Safety > Business Logic > Type Safety / Test > Maintainability > Readability / Style**

## 報告格式

輸出時**嚴格遵守以下結構**。主表只放摘要，詳細內容一律下放到「Comment N 詳述」，避免表格在終端機中無法閱讀。

---

**MR Review Summary — `<project-path>` `<mr-number>`**

### 審閱意見明細

| # | 檔案:位置 | Concern 摘要 | 採納程度 | 優先度 |
| - | -------- | ----------- | ------- | ----- |
| 1 | | | 接受／部分接受／不建議接受／無需修改／無法驗證 | Blocking／Recommended／Optional |
| 2 | | | | |

每格內容一行以內。任何需要展開的說明都寫進下方詳述，不要塞進表格。

### Comment N 詳述

僅對需要展開的項目產生（原則上所有 Blocking、所有「部分接受」與「不建議接受」都需要）。

**Reviewer Concern** — 審閱者真正關注的問題。

**驗證結果** — 問題是否存在、判斷依據、相關程式碼流程、是否存在 Reviewer 未考慮的 Context。

**影響範圍** — Direct / Indirect / No Meaningful，以及受影響的 Caller、Type、Test。

**合宜性評估** — Concern 是否成立、Solution 是否適合、採納或不採納的理由。

**修正方案** — 修改檔案、修改位置、修改邏輯、測試調整、驗證方式、Regression Risk，必要時附簡短程式碼範例。

### 整體評估

| 項目 | 內容 |
| --- | --- |
| Blocking 問題 | |
| 建議優先修正項目 | |
| 潛在高風險修改 | |
| 可延後處理項目 | |
| 不建議採納項目 | |
| 已處理／無需修改項目 | |

### 建議修正計畫

依 Dependency、Correctness 與 Regression Risk 排序，不依 Review Comment 出現順序。

| 順序 | 修正項目 | 涉及檔案 | 說明 | 驗證方式 |
| --- | --- | --- | --- | --- |
| 1 | | | | |
| 2 | | | | |
