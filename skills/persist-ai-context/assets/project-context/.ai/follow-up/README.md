# Follow-up

Follow-up 保存 AI 協作過程中發現、值得保留，但不屬於目前工作範圍、不需要立即處理，也尚未納入正式工作系統的後續候選事項。

記錄 follow-up 不代表已授權執行，也不代表它具有排程優先權。由使用者決定是否啟動、捨棄或正式化。

使用者確認執行的 follow-up 應進入專案採用的正式工作流程。專案可選擇使用 OpenSpec；未使用時則依既有 Issue、ADR、規格文件或其他正式系統處理。

## 資訊邊界

| 類型 | 用途 |
| --- | --- |
| Handoff | 目前工作尚未完成，接手後應繼續處理 |
| Follow-up | 值得日後處理，但目前不展開 |
| 正式工作系統 | 保存已確認要執行的需求、決策、變更與任務；可包含 OpenSpec、Issue 或其他既有系統 |
| 正式文件 | 保存 ADR、規格與長期專案知識 |
| Archive | 已失效、已處理或不再需要關注的歷史內容 |

## 文件單位

每個 follow-up 項目使用一份文件，使各項目可以獨立被正式化、封存或刪除。

```text
.ai/follow-up/
├── 2026-07-22-remove-unused-announcement-attachment-methods.md
├── 2026-07-22-add-attachment-http-authorization-tests.md
└── 2026-07-22-confirm-mixed-status-task-sorting.md
```

- 每份文件只保存一個可獨立正式化、封存或刪除的 follow-up 項目。
- 每個項目以日期與主題組成的檔名識別。
- 同一事項已存在於 follow-up 時，更新原文件，不建立重複項目。

## 檔名

檔名格式為：

```text
YYYY-MM-DD-<topic>.md
```

日期代表 follow-up 被發現或正式記錄的日期，用來辨識時間順序。`topic` 使用簡短、可獨立理解的 kebab-case 名稱。

```text
.ai/follow-up/2026-07-22-remove-unused-announcement-attachment-methods.md
```

同一份 follow-up 跨日更新時沿用原檔名；最後更新時間由 frontmatter 的 `updated_at` 表示。

## 文件格式

Follow-up 使用 Markdown，並以少量 YAML frontmatter 保存識別、時效與來源資訊。

```md
---
created_at: 2026-07-22
updated_at: 2026-07-22T16:30:00+08:00
status: deferred
openspec_change: add-scheduled-announcement-delivery
baseline_commit: 07e3ede5
---

# 移除 AnnouncementsService 未使用的附件操作

## Context

這個問題是在驗證 `add-scheduled-announcement-delivery` 時發現。
目前 change 已滿足核准需求，不受此問題阻礙。

## Finding

`AnnouncementsService.uploadAttachment()` 與 `deleteAttachment()` 已無有效路由，
但仍保留未套用目前公告鎖定與授權規則的舊邏輯。

## Why it matters

如果舊方法未來被誤接回路由，可能繞過目前的鎖定檢查，
並產生與正式附件 API 不一致的錯誤語意。

## Why deferred

此問題不影響目前 change 的需求與驗證結果，且尚未被納入新的正式工作。

## Evidence and references

- `src/modules/announcements/announcements.service.ts`：`uploadAttachment()`、`deleteAttachment()`
- `src/modules/announcements/announcements.controller.ts`：已註解的舊附件路由
- OpenSpec change：`add-scheduled-announcement-delivery`
- Baseline commit：`07e3ede5`

## Suggested approach

確認沒有呼叫端後，考慮移除兩個舊 service methods、相關未使用 import，
以及 controller 內已註解的舊路由。

## Suggested verification

- 使用 `rg` 確認不存在舊呼叫端。
- 執行 announcement 與 attachment 相關測試。

## Exit criteria

附件寫入只剩 `AttachmentsService` 單一實作來源，且相關回歸測試通過。
```

範例只展示格式與資訊層次；建議方案與驗證方式不代表已獲得執行授權。

### Frontmatter

| 欄位 | 用途 |
| --- | --- |
| `created_at` | Follow-up 被發現或正式記錄的日期，應與檔名日期一致 |
| `updated_at` | 最後一次實質更新的時間 |
| `status` | `deferred` 或 `needs-confirmation` |
| `openspec_change` | 發現此項目的 OpenSpec change ID，僅在專案使用 OpenSpec 且有對應 change 時填寫 |
| `baseline_commit` | 發現此事項時，證據或現況所依據的 Git commit |

`created_at`、`updated_at` 與 `status` 為必要欄位。其他欄位沒有對應值時可以省略，不填入空值。

`baseline_commit` 保存事項被發現時的證據基準。後續補充新證據時，在內容中附上新的 commit 或正式來源，保留原始發現脈絡。

狀態只用來區分：

- `deferred`：已確認目前不處理。
- `needs-confirmation`：需要使用者、產品或其他權責人確認。

Follow-up 處理完成後，依回溯價值正式化、封存或刪除。

優先級與處理順序僅記錄使用者或正式來源已確認的結果。

### 必要區段

每份 follow-up 應包含：

- `Finding`：具體發現的現象或問題。
- `Why it matters`：未來可能造成的影響或保留價值。
- `Why deferred`：為什麼現在不處理。
- `Evidence and references`：相關程式碼、正式工作項目、OpenSpec、Issue、commit、測試或其他證據。

### 選用區段

依項目需要加入：

- `Context`：發現項目的工作背景與來源。
- `Suggested approach`：可能的處理方向，不視為已授權方案。
- `Suggested verification`：正式啟動後可考慮的驗證方式。
- `Exit criteria`：如何判斷此事項已被解決。

不需要為了符合格式而保留空區段。內容不應依賴原始對話才能理解。

## 使用原則

### 不擴張目前工作範圍

Agent 在工作中發現不影響目前目標的額外問題時，可以記錄為 follow-up，不自行延伸處理。

適合記錄的情況包括：

- 發現與目前 change 無關的潛在問題。
- 發現值得改善，但不影響目前交付的程式碼或流程。
- 發現需要更多證據才能判斷的現象。
- 使用者明確表示日後再處理的事項。

### 記錄不代表授權執行

Agent 可以保存 follow-up、補充相關證據，並在適合的時機提醒使用者。

未經使用者確認，Agent 不應因 follow-up 存在而開始實作、自行排定優先順序，或擴張目前工作的範圍。

### 不延後阻礙目前工作的事項

會影響目前需求、行為、範圍或下一步的問題，不能只記錄後放置：

```text
影響目前工作
  → 在 handoff 註明
  → 必要時立即向使用者確認

不影響目前工作
  → 可以記錄為 follow-up
```

資訊衝突若會阻礙目前工作，應立即整理證據並向使用者確認；只有非阻斷、可以延後處理的衝突才適合放入 follow-up。

### 只保存有後續價值的內容

Follow-up 不用來保存所有想法。適合保存的內容通常至少符合一項：

- 未來可能影響正確性、安全性或維護性。
- 已有具體證據或可重現現象。
- 使用者明確要求日後提醒。
- 與可能的後續需求有直接關係。
- 若不保存，很可能在跨 Agent 或工作階段後遺失。

純粹靈感、模糊猜測或沒有後續行動價值的內容不需要保存。

### 不重複正式工作

如果內容已存在於專案的正式工作系統或文件，follow-up 只引用正式來源，或直接移除。

當使用者確認要處理某個 follow-up 時，應將它納入專案既有的正式工作流程；若使用 OpenSpec，建立或更新對應 change。不要在兩處持續維護相同內容。

## 檢視時機

Agent 不需要在每個工作階段開始時讀取所有 follow-up，避免與目前工作無關的事項干擾當前脈絡。

適合檢視 follow-up 的時機包括：

- 使用者準備選擇下一項工作。
- 目前工作與某個 follow-up 有直接關係。
- Handoff 明確引用某個 follow-up。
- 使用者要求整理後續候選事項。
- 目前正式工作項目結束，準備檢視工作中額外發現的事項。

## 生命週期

```text
協作過程中發現非當前範圍事項
                ↓
判斷不需立即處理，但值得保存
                ↓
建立 follow-up
                ↓
使用者決定後續處理方式
       ┌────────┼────────┐
       ↓        ↓        ↓
   正式化     封存      刪除
```

- 使用者決定執行：納入專案既有的正式工作流程，並視需要建立或引用 OpenSpec change、Issue 與正式文件。
- 已處理或失去時效，但值得回溯：移入 `.ai/archive/`。
- 已被其他內容涵蓋：合併或刪除。
- 不再相關且沒有回溯價值：直接刪除。

## 建立前判斷

建立 follow-up 前確認：

1. 這件事是否不需要現在處理？
2. 它是否尚未成為正式需求或任務？
3. 如果現在不記錄，是否可能遺失有價值的資訊？

只有「現在不用處理、尚未成為正式工作，但值得保留」的事項，才適合建立 follow-up。
