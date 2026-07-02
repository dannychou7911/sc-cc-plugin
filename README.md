# sc-cc-plugin

團隊共享的 Claude Code plugin 工具集，收錄經過實戰驗證的 skills、agents 與 slash commands，提升日常開發效率。

## 包含元件

### Skills

主動觸發的技能，Claude Code 會依情境自動載入，也可用 `/sc-cc-plugin:<name>` 手動呼叫。

| 名稱 | 說明 |
|------|------|
| `spec-recovery` | 從棕地專案（brownfield）既有程式碼回推、補齊 L0-L4 規格文件，不限前後端框架或語言 |
| `dev-workflow-v2` | 通用開發工作流程，涵蓋需求分析、程式碼探索、設計、開發（TDD）、驗證五階段，以棕地專案為預設情境，各階段產出對應 Markdown 文件 |
| `review-comments` | 依 8 大核心原則審查程式碼註解品質（重 why 而非 what），輸出結構化審查報告、不改動程式碼 |
| `vue-pattern` | Vue 官方 Style Guide 規則知識庫，涵蓋 Priority A–D 共 26 條規則，Composition API 與 Options API 範例並陳 |
| `java-coding-standards` | Spring Boot 與 Quarkus 的 Java 17+ 編碼標準，依 build file 自動偵測框架並套用對應慣例 |
| `mermaid` | 依需求產生 Mermaid 圖表，支援 flowchart、sequence、class、ER、Gantt 等 23 種圖表類型 |
| `obsidian-markdown` | 建立與編輯 Obsidian Flavored Markdown（wikilinks、embeds、callouts、properties 等語法） |
| `strategic-compact` | 在邏輯斷點建議手動 context compaction，避免 auto-compaction 在不恰當時機觸發 |

### Agents

專責的子代理，可用 `@` 呼叫或由主 agent 主動委派。

| 名稱 | 說明 |
|------|------|
| `frontend-code-reviewer` | 通用程式碼審閱專家，聚焦可讀性、可維護性、安全性與專案慣例，不限框架，僅回報高信心度（>80%）的問題。框架專屬規則由 `references/` 擴充補充 |
| `spec-scorer` | 規格文件品質評分專家，獨立審閱 `spec-recovery` 產出的 L0-L4 文件（多維度評分、可測試性評分、差異驗證），與主 agent 分離以避免 confirmation bias |

### Slash Commands

| 指令 | 參數 | 說明 |
|------|------|------|
| `/commit` | `[message] \| --amend` | 使用 conventional commit 格式建立格式良好的 commit，預設不使用 emoji |
| `/review-mr` | `<project-path> <mr-number>` | 分析指定專案 MR 的所有審閱回饋，驗證後產出修正計畫 |
| `/rewrite-comments` | `[file-path]` | 改寫程式碼註解，著重 why 而非 what；冗餘者刪除、過期者修正、推斷不出意圖者標記請人補 |
| `/squash-branch` | `[base-branch]` | 將目前分支自基準分支分歧後的所有 commits 合併為單一 commit，執行前先建立備份分支 |

## 安裝方式

### 本地測試

```bash
claude --plugin-dir /path/to/sc-cc-plugin
```

### 驗證安裝

啟動 Claude Code 後：

- 輸入 `/`，確認看到帶有 `(sc-cc-plugin)` 標籤的 `/commit`、`/review-mr`、`/rewrite-comments`、`/squash-branch`
- 輸入 `@`，確認看到 `frontend-code-reviewer` 與 `spec-scorer` 兩個 agent
- 輸入 `/spec`，確認 skills（如 `/sc-cc-plugin:spec-recovery`）出現在清單中

## 使用範例

```bash
# 回推整個專案規格（skill 亦會在相關語境中自動觸發）
/spec-recovery

# 回推單一模組
/spec-recovery src/modules/auth

# 建立 conventional commit
/commit

# 分析某專案的 MR 回饋並產出修正計畫
/review-mr ~/Project/my-app 486

# 將目前分支的多個 commits 壓成一個（先建立備份分支）
/squash-branch main
```

## 需求

- Claude Code >= 1.0.33
