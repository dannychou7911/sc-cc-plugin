# Archive

Archive 保存已退出當前工作狀態，但仍具有回溯價值的 handoff 與 follow-up 最終快照。

封存內容只描述特定時間與專案狀態下的歷史脈絡，不代表目前的專案事實或待執行工作。

Archive 保存與專案工作相關的歷史執行脈絡；正式需求、設計、決策、變更與任務仍由專案採用的正式系統管理。OpenSpec 是可選整合，不是使用本方法的必要前提。

## 資訊邊界

| 類型 | 用途 |
| --- | --- |
| Handoff | 目前仍需要接手並繼續執行的工作 |
| Follow-up | 目前不處理，但仍值得日後關注的候選事項 |
| Archive | 已退出當前狀態，只在需要追溯時讀取的歷史脈絡 |

內容的處理方式依目前行動價值與回溯價值判斷：

```text
仍要繼續目前工作
  → 保留於 handoff

仍可能成為後續工作
  → 保留於 follow-up

不再需要行動，但值得理解過去
  → 移入 archive

不再需要行動，也沒有回溯價值
  → 刪除
```

## 檔名

Archive 使用單一目錄，檔名格式為：

```text
YYYY-MM-DD-<source-type>-<topic>.md
```

- `YYYY-MM-DD`：移入 archive 的日期，用來辨識封存順序。
- `source-type`：原始文件類型，使用 `handoff` 或 `follow-up`。
- `topic`：沿用原文件的工作或事項主題。

```text
.ai/archive/
├── 2026-08-10-handoff-align-webhook-query-authorization.md
└── 2026-08-15-follow-up-remove-unused-announcement-attachment-methods.md
```

封存時依封存日期與來源類型重新命名。原始建立日期保留於 frontmatter 的 `created_at`。

```text
原文件：
.ai/follow-up/2026-07-22-remove-unused-announcement-attachment-methods.md

封存後：
.ai/archive/2026-08-15-follow-up-remove-unused-announcement-attachment-methods.md
```

## 文件格式

Archive 保留原 handoff 或 follow-up 的 metadata 與最終內容，並加入封存 metadata 及 `Archive outcome`。

```md
---
created_at: 2026-07-22
updated_at: 2026-08-12T14:30:00+08:00
archived_at: 2026-08-15T10:00:00+08:00
source_type: follow-up
archive_reason: formalized
archived_from: .ai/follow-up/2026-07-22-remove-unused-announcement-attachment-methods.md
openspec_change: remove-legacy-attachment-methods
baseline_commit: 07e3ede5
---

# 移除 AnnouncementsService 未使用的附件操作

## Archive outcome

- 封存原因：已轉為正式 OpenSpec change。
- 最後結果：使用者確認納入後續開發。
- 正式來源：`openspec/changes/remove-legacy-attachment-methods/`

## Context

這個問題是在驗證 `add-scheduled-announcement-delivery` 時發現。

## Finding

`AnnouncementsService.uploadAttachment()` 與 `deleteAttachment()` 已無有效路由，
但仍保留舊邏輯。

## Why it matters

如果舊方法未來被誤接回路由，可能繞過目前的鎖定與授權規則。

## Why deferred

當時不影響原 OpenSpec change，因此先列為 follow-up。

## Evidence and references

- `src/modules/announcements/announcements.service.ts`
- Baseline commit：`07e3ede5`
```

範例中的 `Archive outcome` 是封存時新增的結果摘要；其餘內容保留原文件退出當前狀態時的最終快照。

### Frontmatter

封存時保留原文件既有欄位，並加入：

| 欄位 | 用途 |
| --- | --- |
| `archived_at` | 正式退出當前狀態的時間，日期應與封存檔名一致 |
| `source_type` | 原始文件類型：`handoff` 或 `follow-up` |
| `archive_reason` | 退出當前狀態並封存的原因 |
| `archived_from` | 原文件在 active 狀態中的路徑 |

這四個欄位為 archive 必要欄位。

時間欄位分別表示：

- `created_at`：原文件建立時間。
- `updated_at`：原文件最後一次有效狀態更新時間。
- `archived_at`：原文件退出當前狀態並移入 archive 的時間。

封存時保留原本的 `created_at` 與 `updated_at`，以區分內容更新時間與封存時間。

原文件保留的 `status` 屬於退出當前狀態前的歷史值；archive 的目前生命週期由文件位置、`archived_at` 與 `archive_reason` 表示。

### Archive outcome

每份 archive 應在標題後加入 `Archive outcome`，說明：

- 封存原因。
- 最後結果。
- 已轉入的正式工作系統、OpenSpec、Issue 或其他正式來源。
- 與最後結果相關的未解決脈絡，以及其目前追蹤來源。

只保留有對應內容的項目，不建立空項目。

仍需採取行動的未解決事項應建立 follow-up；archive 只保存歷史說明與對該 follow-up 的參照。

## 使用原則

### 保存最終快照

Handoff 或 follow-up 退出當前狀態時，archive 保存其最後有效狀態。

```text
持續更新 active 文件
        ↓
退出當前狀態
        ↓
保存最終快照至 archive
```

Git 保存檔案的修改歷史；archive 讓仍有價值的歷史脈絡可以直接被找到與理解。

### 從當前狀態移入 Archive

封存時將文件從 handoff 或 follow-up 移入 archive，使每份資訊只有一個目前位置。

這能維持：

- Handoff 只包含仍需接手的工作。
- Follow-up 只包含仍待考慮的事項。
- Archive 只包含已退出當前狀態的內容。

### 只保存具有回溯價值的內容

適合封存的內容包括：

- 重要驗證結果或失敗原因。
- 工作中止、被取代或改變方向的原因。
- 難以從程式碼或 Git 重新理解的執行脈絡。
- Follow-up 正式化後與正式工作系統或文件的關聯。
- 被取消但未來可能需要理解的工作狀態。
- 使用者明確要求保留的內容。

失效且沒有回溯價值的內容直接刪除。

### 不作為當前事實

Archive 表示內容在特定時間與專案狀態下的歷史脈絡。它與目前的程式碼、Git、正式工作系統、正式文件、handoff 或 follow-up 不同時，先視為時間與狀態差異；差異若會影響目前需求、行為、範圍或下一步，Agent 應整理證據並向使用者確認。

Archive 與目前現況不同是正常情況，不需要修改歷史內容使其符合現在。

### 按需讀取

Archive 不屬於一般工作階段的預設載入內容。適合查閱的時機包括：

- 使用者詢問過去如何處理某項工作。
- 新工作與過去的 handoff 或 follow-up 有直接關係。
- 需要理解某項做法為何被取消或取代。
- 正式文件或目前 handoff 明確引用某份 archive。
- 相似問題再次出現，需要查找過去證據。

### 維持歷史完整性

封存後的內容維持其最終快照，不再作為持續更新的當前文件。

如果封存內容需要更正，應附加更正說明或指向目前的正式來源，保留原本的時間與狀態脈絡。

如果封存事項重新成為工作，以 archive 作為歷史參考，並依目前狀態建立新的 handoff 或 follow-up。

### 保留封存脈絡

封存內容應能辨識：

- 原始類型是 handoff 或 follow-up。
- 退出當前狀態的時間。
- 封存原因與最後結果。
- 已轉入的正式工作系統、OpenSpec、Issue 或其他正式來源。
- 當時依據的 commit、change 或其他證據。

## Handoff 封存條件

Handoff 在下列情況退出當前狀態，且具有回溯價值時移入 archive：

- 工作已完成並完成必要驗證。
- 工作被取消。
- 工作被新的實作方向取代。
- 對應的正式工作項目已結束或封存。
- 目前不再需要接手，但最終狀態值得保留。

如果工作是否完成或內容是否過期存在資訊衝突，Agent 應整理證據並向使用者確認後再處理。

## Follow-up 封存條件

Follow-up 在下列情況退出當前狀態，且具有回溯價值時移入 archive：

- 已納入專案正式工作流程，並建立必要的 OpenSpec change、Issue 或正式文件參照。
- 已由其他工作處理。
- 已被新的做法取代。
- 使用者決定不再處理，但需要保留原因。
- 已失去時效，但內容仍具有歷史價值。

Follow-up 的存放時間不作為失效判斷依據。

## 生命週期

```text
handoff／follow-up
        ↓
退出當前狀態
        ↓
判斷是否具有回溯價值
    ┌───────────┴───────────┐
    ↓                       ↓
  有價值                  無價值
    ↓                       ↓
 archive                  delete
    ↓
僅在需要追溯時讀取
```
