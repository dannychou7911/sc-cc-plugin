---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git branch:*), Bash(git reset:*), AskUserQuestion
argument-hint: "[base-branch]"
description: 將目前分支自基準分支分歧後的所有 commits 合併為單一 commit，執行前先建立備份分支
---

將目前分支自基準分支分歧後的所有 commits 合併（squash）成一個 commit。

## 基準分支決定方式

使用者輸入：`$ARGUMENTS`

決定 `$BASE_BRANCH` 的順序：

1. **若使用者有指定參數**（例如 `/squash-branch main`、`/squash-branch develop`、`/squash-branch origin/release`）：
   - 直接使用該參數作為 `$BASE_BRANCH`
   - 以 `git rev-parse --verify <base>` 驗證該 ref 存在；不存在則停下來告知使用者並結束
2. **若使用者未指定**：
   - 依序檢查 `master` → `main` → `develop` 哪個本地分支存在（用 `git rev-parse --verify <name>`）
   - 取第一個存在的作為 `$BASE_BRANCH`
   - 若三者皆不存在，停下來請使用者明確指定基準分支
   - 若同時存在多個（例如 master 與 main 都有），停下來詢問使用者要用哪一個

決定後，於後續流程一律使用 `$BASE_BRANCH` 變數，不要 hardcode 分支名。

## 流程

### 1. 前置檢查

並行執行以下檢查：

- `git status`：確認工作目錄乾淨（若有未提交變更，停下來詢問是否要 stash 或先 commit）
- `git rev-parse --abbrev-ref HEAD`：取得當前分支名稱
- 若當前分支等於 `$BASE_BRANCH`（或為 `master` / `main` / `develop`），停下來警告並要求確認
- `git merge-base $BASE_BRANCH HEAD`：取得與 `$BASE_BRANCH` 的分歧點（記為 `$MERGE_BASE`）
- `git log --oneline $MERGE_BASE..HEAD`：列出將被合併的 commits

若 commits 數量為 0 或 1，告知使用者「沒有需要 squash 的 commits」並結束。

### 2. 建立備份分支

以當前分支名為基礎產生備份分支名：`backup/{原分支名稱以 - 取代 /}-before-squash`

例：`feat/P26-499` → `backup/feat-P26-499-before-squash`

若同名備份分支已存在，附加時間戳：`backup/{name}-before-squash-{YYYYMMDD-HHMMSS}`

執行：`git branch <備份分支名>`

並驗證備份分支已建立。

### 3. 確認 commit message 來源

使用 AskUserQuestion 詢問使用者：

- **手動提供完整 message**：等使用者下一則訊息給完整內容
- **依範圍內 commits 自動彙整**（Recommended）：讀取每個 commit 的 subject + body，整合為一個 message，分區塊（如 新增 / 修正 / 重構）描述，自動附上 branch footer（從分支名稱抽取 ticket id，例如 `feat/P26-499` → footer `P26-499`）
- **使用最近一個 commit 的 message**：直接沿用最新 commit 的 message

### 4. 執行 squash

- `git reset --soft $MERGE_BASE`：將 HEAD 回退到分歧點，所有變更保留為 staged
- `git status`：確認所有變更已 staged
- `git commit -m "$(cat <<'EOF' ... EOF)"`：以步驟 3 的 message 建立新 commit（使用 HEREDOC 保證格式）
- 若有 pre-commit hook 失敗，不要 `--no-verify`，回報失敗原因讓使用者修正

### 5. 回報結果

並行執行：

- `git log --oneline $BASE_BRANCH..HEAD`：顯示新的 commit
- `git diff --stat $BASE_BRANCH..HEAD`：顯示變更檔案統計

回報：

- 使用的基準分支 `$BASE_BRANCH`
- 備份分支名稱
- 原 commits 數量 → 1
- 變更檔案統計
- 提醒：本機 history 已改寫，下次 push 需 `--force-with-lease`（不主動 push）

## 安全規範

- 不執行 `git push`（除非使用者明確要求）
- 不執行 `--no-verify`
- 不刪除備份分支
- commit message 遵循 conventional commit，scope 不填寫，footer 使用分支名稱抽取的 ticket id
