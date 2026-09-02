---
description: 分析指定專案 MR 的所有審閱回饋，驗證合理性並產出修正計畫
argument-hint: <project-path> <mr-number>
---

分析專案 `$1` 的 Merge Request `$2` 的所有審閱回饋。

若 `$1` 或 `$2` 為空，直接向使用者詢問缺少的參數，不要推測、不要從 git remote 或當前分支自行推導。

本 Command **只進行分析與規劃，絕對不修改任何程式碼**。

判準、分級定義與報告格式一律依 `mr-review-criteria` Skill，先載入該 Skill 再開始分析。

## 1. 取得 MR 上下文

使用 GitLab MCP 取得：

- MR Title、Description
- Source Branch、Target Branch
- Commits
- Changed Files 與 Diff
- 所有 Review Comments、Discussions、Suggestions、Inline Comments

先確認再往下走：

- 這個 MR 要解決什麼問題
- 核心異動範圍
- 現有實作的設計意圖
- 是否存在既有 Architecture、Pattern 或 Team Convention

不要只根據 Reviewer 指定的單一程式碼片段判斷。

僅在驗證某項 Concern 所必要時，才進一步讀取 Caller / Consumer、Component、Composable、Store、Service、API、Type、Test 或 Data Flow。避免無目的地擴大 Repository 掃描範圍。

## 2. 整理審閱回饋

以「一個 Discussion / Concern」為分析單位，不要把同一 Discussion 的每則回覆拆成獨立問題。

每項整理：問題描述、Reviewer Concern、Reviewer 建議方案、涉及檔案與位置、Discussion 狀態、是否已由後續 Commit 處理。

同時確認：Resolved / Unresolved、Active / Outdated、Reviewer 是否有後續補充或撤回、Author 是否已回覆、是否屬於重複 Concern。

處理原則：

- 相同根因的 Comments 合併分析。
- 已 Resolved 且最新程式碼已修正者，不列入待修正項目。
- Outdated Comment 不直接忽略，仍需確認相同問題是否存在於最新程式碼。
- Discussion 有後續結論時，以最新有效共識為準。

## 3. 驗證 Reviewer Concern

Reviewer 的意見是需要驗證的輸入，不是既定事實。針對每項 Concern，先確認問題是否真的存在：

- Reviewer 描述的行為是否會實際發生
- 判斷是否符合 MR 最新程式碼
- 是否已有 Guard、Validation、Fallback 或其他機制處理
- 是否只有特定條件或 Edge Case 才會發生
- 是否已被後續 Commit 修正
- Reviewer 是否忽略其他程式碼路徑或設計意圖
- 是否有測試或型別約束可作為判斷依據

資訊不足以可靠判斷時標示「無法驗證」，不要自行補充不存在的前提。

分析深度與問題風險成比例：Naming、Style、簡單 Readability 可簡短判斷；Correctness、Business Logic、State、API、Architecture、Regression 需追蹤完整相關流程。

## 4. 分析影響範圍

依 Skill 的影響範圍檢查清單，判定每項 Concern 與其修正方案的 Direct / Indirect / No Meaningful Impact。

## 5. 評估合宜性與優先度

依 Skill 的採納程度五級與優先度三級進行分類。必須分開判斷「Concern 是否成立」與「Solution 是否適合」。

## 6. 提出修正方案

依 Skill 的修正方案原則，對每項需處理的 Concern 提供修改策略、預計修改檔案與位置、修改步驟、測試調整、Regression Risk、驗證方式，必要時附簡短程式碼範例。

## 7. 產出報告

依 Skill 定義的報告格式輸出，標題請填入本次的專案路徑 `$1` 與 MR 編號 `$2`。
