# Handoff

Handoff 保存一項進行中工作在跨 Agent、工具或工作階段交接時，接手者需要知道的當前狀態、驗證依據與下一步。

Handoff 延續目前工作的執行狀態；正式需求、設計、決策、變更與任務由專案採用的正式系統管理。專案可選擇使用 OpenSpec，未使用時則依既有 Issue、ADR、規格文件或其他正式工作流程處理。

## 文件單位

每一項需要延續的進行中工作對應一份 handoff 文件。

```text
.ai/handoff/
├── 2026-08-07-align-webhook-query-authorization.md
└── 2026-08-09-add-user-login.md
```

- Handoff 以一項需要延續的進行中工作為單位。
- 同一項工作跨 Agent 或工作階段時，持續更新原 handoff 文件。
- Handoff 僅用於需要跨 Agent、工具或工作階段延續的工作。

## 檔名

檔名格式為：

```text
YYYY-MM-DD-<work-id>.md
```

日期代表這份 handoff 建立或正式交接的日期，用來辨識 handoff 的時間順序。

有對應 OpenSpec change 時，`work-id` 優先使用 change ID：

```text
openspec/changes/align-webhook-query-authorization/
.ai/handoff/2026-08-07-align-webhook-query-authorization.md
```

沒有使用 OpenSpec 或沒有對應 change 時，優先使用專案既有工作項目 ID；若沒有合適 ID，使用簡短且能表達工作範圍的 kebab-case 名稱：

```text
.ai/handoff/2026-08-07-investigate-login-timeout.md
```

同一份 handoff 跨日更新時沿用原檔名；最後更新時間由 frontmatter 的 `updated_at` 表示。

## 文件格式

Handoff 使用 Markdown，並以少量 YAML frontmatter 保存識別工作及驗證時效性所需的資訊。

```md
---
created_at: 2026-08-07
updated_at: 2026-08-07T16:30:00+08:00
openspec_change: align-webhook-query-authorization
branch: feature/align-webhook-query-authorization
baseline_commit: abc1234
---

# Webhook 查詢授權對齊交接

## Objective

使前端 Webhook 查詢權限符合 `align-webhook-query-authorization` change。

## Scope and references

- GET webhook 僅需 `ADMIN`。
- POST re-register 維持 `ADMIN + 1001`。
- 授權依據為已核可的 proposal 與 design。
- 前端 repository 不包含後端依據 commit，因此無法直接驗證該 commit object。

## Current state

- Auth store、Header Popover、Bot 管理頁與 mock authorization 已完成調整。
- 目標 Bot Popover 的 16 個 E2E scenarios 全數通過。
- 全套 E2E 仍有 5 個既有 `scheduled-delivery` scenario 逾時。

## Next action

確認 5 個既有逾時是否影響本 change 的完成判定，再處理尚未完成的驗證項目。

## TDD evidence

| 階段 | Red 結果 | Green 實作與回歸 |
| --- | --- | --- |
| Auth store | 新增 `canViewWebhook` 案例後得到 3 failures。 | 新增 `canViewWebhook = isAdmin`；相關單元測試通過。 |
| Bot 管理頁 | ADMIN 無 1001 時未呼叫查詢。 | 分離查詢與管理權限；相關測試通過。 |

## Verification

| 指令 | 結果 |
| --- | --- |
| `pnpm lint` | 通過，0 errors；96 個既有 warnings。 |
| `pnpm type-check` | 通過。 |
| `pnpm test:run` | 通過，65 files / 732 tests。 |
| `pnpm test:e2e` | 104 passed、5 個既有 scenario 逾時。 |

## Unfinished verification

- 全套 E2E 有 5 個 `scheduled-delivery` scenario 逾時。
- 目標功能的 16 個 scenarios 均通過。
- 對應的 OpenSpec 驗證項目尚未完成。

## Working set

- `src/stores/auth.ts`
- `tests/unit/stores/auth.spec.ts`
- `tests/e2e/bots/bot-status-popover.spec.ts`
```

範例只展示格式與資訊層次，不代表每份 handoff 都需要相同的區段或證據量。

### Frontmatter

| 欄位 | 用途 |
| --- | --- |
| `created_at` | Handoff 建立或正式交接的日期，應與檔名日期一致 |
| `updated_at` | 最後一次實質更新的時間 |
| `openspec_change` | 對應的 OpenSpec change ID，僅在專案使用 OpenSpec 且有對應 change 時填寫 |
| `branch` | 對應的 Git branch |
| `baseline_commit` | Handoff 最後一次依專案現況驗證時所對應的 Git commit |

`created_at` 與 `updated_at` 為必要欄位。其他欄位沒有對應值時可以省略，不填入空值。

### 必要區段

每份 handoff 應包含：

- `Objective`：目前工作的目標，優先引用正式來源，不重寫完整規格。
- `Current state`：已確認的實際進度與工作狀態。
- `Next action`：接手者可以直接執行的下一個動作。

### 選用區段

依工作需要加入：

- `Scope and references`：工作範圍、正式依據、限制與無法驗證的來源。
- `TDD evidence`：能證明行為改變的關鍵 Red／Green 證據。
- `Verification`：已執行的驗證指令與結果。
- `Unfinished verification`：未執行、未通過或仍待確認的驗證。
- `Blockers`：阻礙工作繼續進行的事項。
- `Working set`：目前相關檔案與未提交變更。

不需要為了符合格式而保留空區段。證據應聚焦接手與判斷所需的結果，不複製完整終端輸出。

## 使用流程

### 建立

- 只有工作可能需要跨 Agent、工具或工作階段延續時才建立。
- 檔名使用建立或正式交接當日的日期與工作 ID。
- 引用專案正式工作來源，不複製完整需求或設計；有對應 OpenSpec change 時可使用 change ID。
- 以建立時的 Git branch 與 commit 作為狀態驗證參照。

### 接手

1. 依工作 ID 找到對應的最新 handoff。
2. 讀取相關正式工作項目、OpenSpec change、Issue 或正式文件。
3. 比對 branch、commit、工作目錄與程式碼現況。
4. 確認 handoff 仍然有效後繼續工作。
5. 發現會影響需求、行為、範圍或下一步的衝突時，整理證據並向使用者確認。

### 更新

在下列情況更新原 handoff：

- 完成影響接手方式的重要步驟。
- 下一步發生改變。
- 出現或解除 blocker。
- 驗證結果改變完成狀態或風險判斷。
- 即將交給其他 Agent 或工具。
- 工作階段即將結束，但工作尚未完成。

更新時同步修改 `updated_at`，將內容重寫為最新有效狀態，並沿用原檔名。工作所在 branch 或驗證基準改變時，同步更新 `branch` 與 `baseline_commit`。

### 結束

當工作完成或 handoff 不再有效時：

- 正式結果應已反映至程式碼與專案採用的正式系統；若使用 OpenSpec，依其流程同步對應 change。
- 尚未處理的獨立事項移至 `.ai/follow-up/`。
- 有回溯價值的 handoff 移至 `.ai/archive/`。
- 沒有回溯價值的 handoff 直接刪除。

## 內容原則

- 描述當前狀態、驗證依據與下一步，不保存完整對話或推理過程。
- 已確認事實、未驗證推測與未完成驗證必須清楚區分。
- 重要敘述附上可驗證的正式來源、檔案或指令。
- 驗證結果應如實記錄部分成功、既有失敗與未完成項目。
- 不重複保存正式系統已經管理的內容。
- 不保存密碼、token、個資或其他敏感資料。
