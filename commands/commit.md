---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(test:*), Bash(cat:*), Bash(grep:*), Bash(command -v:*), Bash(pnpm run:*), Bash(npm run:*), Bash(yarn run:*), Bash(bun run:*)
argument-hint: [message] | --amend
description: 使用 conventional commit 格式建立格式良好的 commit；除非使用者明確要求，否則預設不使用 emoji
---

# 智慧 Git Commit

建立格式良好的 commit：$ARGUMENTS

## 目前 Repository 狀態

* Git 狀態：!git status --porcelain
* 目前分支：!git branch --show-current
* 已暫存變更：!git diff --cached --stat
* 未暫存變更：!git diff --stat
* 最近 commit：!git log --oneline -5

## 此指令會做什麼

1. 若專案可判定為 Node.js 專案，才執行 pre-commit 檢查；否則忽略此步驟：

   * 若根目錄不存在 `package.json`，略過 lint / build 檢查

   * 若根目錄存在 `package.json`，先判斷 package manager：

     * 存在 `pnpm-lock.yaml` 時使用 `pnpm`
     * 存在 `bun.lockb` 或 `bun.lock` 時使用 `bun`
     * 存在 `yarn.lock` 時使用 `yarn`
     * 存在 `package-lock.json` 時使用 `npm`
     * 若沒有 lockfile，依序檢查 `pnpm`、`bun`、`yarn`、`npm` 是否可用，使用第一個可用工具

   * 若 `package.json` 存在 `lint` script，使用偵測到的 package manager 執行 lint

   * 若 `package.json` 存在 `build` script，使用偵測到的 package manager 執行 build

   * 若不存在對應 script，略過該檢查

2. 使用 `git status` 檢查哪些檔案已暫存

3. 如果沒有任何檔案已暫存，會自動使用 `git add` 加入所有已修改與新增的檔案

4. 執行 `git diff` 以理解即將提交的變更內容

5. 分析 diff，判斷是否存在多個不同的邏輯變更

6. 如果偵測到多個不同變更，會建議將 commit 拆分成多個較小的 commit

7. 若建議拆分 commit，必須先列出拆分方案與每個 commit 的檔案範圍；未經使用者確認，不得自行拆分、重排 staged files 或建立多個 commit

8. 針對每個 commit，或未拆分時的單一 commit，使用 conventional commit 格式建立 commit message

9. 除非使用者明確要求使用 emoji，否則 commit message 預設不使用 emoji

10. 從目前分支名稱提取 issue 編號，符合條件時加入 commit footer

11. 一律審查 commit diff，確保 commit message 與變更內容一致

## Commit 最佳實務

* **提交前驗證**：若專案已配置相關檢查，提交前應執行 lint / build，確保程式碼品質與建置狀態

* **原子化 commit**：每個 commit 應只包含服務於單一目的的相關變更

* **拆分大型變更**：如果變更涉及多個關注點，應拆分成多個 commit

* **Conventional commit 格式**：使用 `<type>: <description>` 格式，其中 type 可為：

  * feat：新功能
  * fix：錯誤修正
  * docs：文件變更
  * style：程式碼風格變更，例如格式化
  * refactor：既不修正錯誤、也不新增功能的程式碼變更
  * perf：效能改善
  * test：新增或修正測試
  * chore：建置流程、工具、設定等變更
  * ci：CI/CD 設定或流程變更
  * revert：還原變更
  * assets：資源檔新增或更新
  * db：資料庫相關變更
  * ui：介面動畫、轉場或視覺互動變更
  * experiment：實驗性變更
  * wip：進行中工作，僅在使用者明確要求時使用

* **動詞開頭、描述動作**：commit message 應以明確動詞開頭，例如「新增」、「修正」、「更新」、「移除」、「重構」、「調整」，避免使用模糊名詞描述

* **精簡第一行**：第一行應維持在 72 個字元以內

* **body 使用時機**：變更原因不明顯、有特殊背景需要說明、或修正了非直覺的 bug 時才加入 body；一般簡單變更不需要 body

* **footer**：從 `git branch --show-current` 的結果，提取符合 `[A-Z]+-\d+` 格式的 issue 編號作為 footer。footer 只放 issue 編號本身，例如 `P26-576`，不加 `Refs:` 或 `Issue:` 前綴。若分支名稱沒有符合格式的 issue 編號，則不加入 footer

* **Emoji 使用規則**：除非使用者明確要求使用 emoji，否則 commit message 預設不使用 emoji

* **Emoji**：若使用者要求使用 emoji，每種 commit 類型可搭配適當 emoji：

  * ✨ feat：新功能
  * 🐛 fix：錯誤修正
  * 📝 docs：文件
  * 💄 style：格式化／樣式
  * ♻️ refactor：程式碼重構
  * ⚡️ perf：效能改善
  * ✅ test：測試
  * 🔧 chore：工具、設定
  * 🚀 ci：CI/CD 改善
  * 🗑️ revert：還原變更
  * 🧪 test：新增失敗測試
  * 🚨 fix：修正 compiler／linter 警告
  * 🔒️ fix：修正安全性問題
  * 👥 chore：新增或更新貢獻者
  * 🚚 refactor：移動或重新命名資源
  * 🏗️ refactor：進行架構調整
  * 🔀 chore：合併分支
  * 📦️ chore：新增或更新編譯後檔案或套件
  * ➕ chore：新增依賴
  * ➖ chore：移除依賴
  * 🌱 chore：新增或更新 seed 檔案
  * 🧑‍💻 chore：改善開發者體驗
  * 🧵 feat：新增或更新多執行緒或並行相關程式碼
  * 🔍️ feat：改善 SEO
  * 🏷️ feat：新增或更新型別
  * 💬 feat：新增或更新文字與常值
  * 🌐 feat：國際化與在地化
  * 👔 feat：新增或更新商業邏輯
  * 📱 feat：處理響應式設計
  * 🚸 feat：改善使用者體驗／可用性
  * 🩹 fix：針對非關鍵問題的簡單修正
  * 🥅 fix：捕捉錯誤
  * 👽️ fix：因外部 API 變更而更新程式碼
  * 🔥 fix：移除程式碼或檔案
  * 🎨 style：改善程式碼結構／格式
  * 🚑️ fix：關鍵 hotfix
  * 🎉 chore：開始專案
  * 🔖 chore：發布／版本標籤
  * 🚧 wip：進行中工作
  * 💚 fix：修正 CI 建置
  * 📌 chore：將依賴固定到特定版本
  * 👷 ci：新增或更新 CI 建置系統
  * 📈 feat：新增或更新分析／追蹤程式碼
  * ✏️ fix：修正錯字
  * ⏪️ revert：還原變更
  * 📄 chore：新增或更新授權
  * 💥 feat：引入破壞性變更
  * 🍱 assets：新增或更新資源
  * ♿️ feat：改善無障礙能力
  * 💡 docs：新增或更新原始碼註解
  * 🗃️ db：執行資料庫相關變更
  * 🔊 feat：新增或更新日誌
  * 🔇 fix：移除日誌
  * 🤡 test：Mock 物件
  * 🥚 feat：新增或更新彩蛋
  * 🙈 chore：新增或更新 `.gitignore` 檔案
  * 📸 test：新增或更新 snapshot
  * ⚗️ experiment：執行實驗
  * 🚩 feat：新增、更新或移除 feature flag
  * 💫 ui：新增或更新動畫與轉場
  * ⚰️ refactor：移除 dead code
  * 🦺 feat：新增或更新驗證相關程式碼
  * ✈️ feat：改善離線支援

## Package Manager 判斷規則

若根目錄存在 `package.json`，依以下順序判斷 package manager：

1. 若存在 `pnpm-lock.yaml`，使用 `pnpm`
2. 若存在 `bun.lockb` 或 `bun.lock`，使用 `bun`
3. 若存在 `yarn.lock`，使用 `yarn`
4. 若存在 `package-lock.json`，使用 `npm`
5. 若沒有 lockfile，依序檢查 `pnpm`、`bun`、`yarn`、`npm` 是否可用，使用第一個可用工具
6. 若無法判斷 package manager，略過 lint / build 檢查，不得自行假設

## Pre-commit 檢查規則

1. 若根目錄不存在 `package.json`，略過 lint / build 檢查

2. 若根目錄存在 `package.json`，先依 package manager 判斷規則取得可用工具

3. 若 `package.json` 存在 `scripts.lint`，執行：

   ```bash
   <package-manager> run lint
   ```

4. 若 `package.json` 存在 `scripts.build`，執行：

   ```bash
   <package-manager> run build
   ```

5. 若不存在對應 script，略過該檢查

6. 若 lint 或 build 失敗，停止 commit，說明失敗原因與需要修正的方向

7. 不得假設專案一定使用 `pnpm`、`npm`、`yarn` 或 `bun`

## 拆分 Commit 的準則

分析 diff 時，請根據以下標準考慮是否拆分 commit：

1. **不同關注點**：變更涉及程式碼庫中不相關的部分
2. **不同變更類型**：混合了功能、修正、重構、文件、測試、設定等不同類型
3. **檔案模式**：變更涉及不同類型的檔案，例如原始碼、文件、測試、設定檔、資源檔
4. **邏輯分組**：分開後更容易理解或審查的變更
5. **大小**：非常大的變更，拆分後會更清楚

## 拆分 Commit 的安全規則

若偵測到多個不同變更：

1. 先列出建議拆分方案

2. 每個拆分項目需包含：

   * commit message
   * 變更目的
   * 建議包含的檔案範圍

3. 等待使用者確認後，才能拆分與分別提交

4. 未經使用者確認，不得自行重排 staged files

5. 未經使用者確認，不得自行建立多個 commit

6. 若使用者拒絕拆分，則建立單一 commit，但 commit message 必須涵蓋主要變更內容

## Commit Message 格式

### 單行格式

```text
<type>: <description>
```

### 含 body 格式

```text
<type>: <description>

<body>
```

### 含 footer 格式

```text
<type>: <description>

<footer>
```

### 含 body 與 footer 格式

```text
<type>: <description>

<body>

<footer>
```

### 格式規則

* `<type>` 必須從 Commit 最佳實務列出的 type 中選擇
* `<description>` 使用繁體中文
* `<description>` 以動詞開頭
* `<description>` 不加句號
* 第一行維持在 72 個字元以內
* body 說明「為什麼」與「重要背景」，不要重複 diff 已經能看出的內容
* footer 只放 issue 編號，例如 `P26-576`
* 除非使用者明確要求，否則不使用 emoji

## 範例

良好的 commit message：

* feat: 新增使用者登入流程
* fix: 修正報表日期區間查詢錯誤
* docs: 更新 API 串接說明文件
* refactor: 簡化表單驗證邏輯
* fix: 修正元件中的 linter 警告
* chore: 調整本地開發環境設定
* feat: 新增交易驗證商業邏輯
* fix: 修正頁首樣式間距不一致問題
* fix: 修補登入流程中的安全性漏洞
* style: 調整元件結構以提升可讀性
* fix: 移除已棄用的舊版程式碼
* feat: 新增註冊表單欄位驗證
* fix: 修正 CI pipeline 測試失敗問題
* feat: 新增使用者行為追蹤事件
* fix: 強化密碼驗證規則
* feat: 改善表單對螢幕閱讀器的支援

包含 body 的 commit message 範例：

```text
feat: 新增使用者登入流程

實作 JWT 認證機制，包含 token 刷新邏輯與登出後清除。

P26-576
```

```text
refactor: 簡化表單驗證邏輯

原本每個欄位各自處理錯誤訊息，改為統一由 useFormValidator composable 管理，減少重複程式碼。

P26-576
```

```text
fix: 修正報表日期區間查詢錯誤

Safari 對 new Date('2024-01-01') 的解析行為與 Chrome 不同，改用 dayjs 統一處理日期轉換。

P26-576
```

包含 footer 的 commit message 範例：

```text
feat: 新增使用者登入流程

P26-576
```

```text
fix: 修正報表日期區間查詢錯誤

P26-576
```

```text
refactor: 簡化表單驗證邏輯

P26-576
```

若使用者明確要求使用 emoji，可使用以下 commit message：

* ✨ feat: 新增使用者登入流程
* 🐛 fix: 修正報表日期區間查詢錯誤
* 📝 docs: 更新 API 串接說明文件
* ♻️ refactor: 簡化表單驗證邏輯
* 🚨 fix: 修正元件中的 linter 警告
* 🧑‍💻 chore: 調整本地開發環境設定
* 👔 feat: 新增交易驗證商業邏輯
* 🩹 fix: 修正頁首樣式間距不一致問題
* 🚑️ fix: 修補登入流程中的安全性漏洞
* 🎨 style: 調整元件結構以提升可讀性
* 🔥 fix: 移除已棄用的舊版程式碼
* 🦺 feat: 新增註冊表單欄位驗證
* 💚 fix: 修正 CI pipeline 測試失敗問題
* 📈 feat: 新增使用者行為追蹤事件
* 🔒️ fix: 強化密碼驗證規則
* ♿️ feat: 改善表單對螢幕閱讀器的支援

拆分 commit 範例：

* 第一個 commit：feat: 新增活動列表篩選條件
* 第二個 commit：docs: 更新活動查詢 API 文件
* 第三個 commit：chore: 更新 package.json 相依套件
* 第四個 commit：feat: 新增活動查詢回應型別
* 第五個 commit：feat: 改善批次任務併發處理
* 第六個 commit：fix: 修正新增程式碼的 lint 問題
* 第七個 commit：test: 新增活動篩選邏輯單元測試
* 第八個 commit：fix: 更新存在安全性風險的相依套件

若使用者明確要求使用 emoji，拆分 commit 可使用以下格式：

* 第一個 commit：✨ feat: 新增活動列表篩選條件
* 第二個 commit：📝 docs: 更新活動查詢 API 文件
* 第三個 commit：🔧 chore: 更新 package.json 相依套件
* 第四個 commit：🏷️ feat: 新增活動查詢回應型別
* 第五個 commit：🧵 feat: 改善批次任務併發處理
* 第六個 commit：🚨 fix: 修正新增程式碼的 lint 問題
* 第七個 commit：✅ test: 新增活動篩選邏輯單元測試
* 第八個 commit：🔒️ fix: 更新存在安全性風險的相依套件

## 指令選項

* `--amend`：修改上一個 commit，而不是建立新的 commit

## 一般 Commit 流程

1. 檢查目前 git 狀態

2. 判斷是否已有 staged files

3. 若沒有 staged files，使用 `git add` 暫存所有已修改與新增檔案

4. 執行 pre-commit 檢查

5. 執行 diff 分析

6. 判斷是否需要拆分 commit

7. 若不需要拆分，產生單一 commit message

8. 若需要拆分，先提出拆分建議並等待使用者確認

9. 產生 commit message 時，依照以下順序：

   * 判斷 type
   * 撰寫繁體中文 description
   * 必要時撰寫 body
   * 從分支名稱提取 issue 編號作為 footer
   * 僅在使用者明確要求時加入 emoji

10. 執行 commit

## --amend 流程

若偵測到 `--amend` 參數，改走以下流程：

1. 執行 `git log -1 --pretty=format:"%s%n%b"` 顯示上一個 commit message
2. 執行 `git diff --cached --stat` 確認是否有新的 staged 變更
3. 若沒有 staged 變更，僅修改上一個 commit message
4. 若有 staged 變更，將 staged 變更合併進上一個 commit
5. 結合現有 commit 內容與 staged 變更，提出修改後的 message 建議
6. 等待使用者確認
7. 使用 `git log --branches --not --remotes --oneline -1` 或其他可用方式判斷上一個 commit 是否已推送至遠端
8. 若上一個 commit 已推送至遠端，必須警告使用者 amend 可能需要 force push，等待確認後才繼續
9. 提交多行 commit message 時，使用多個 `-m` 參數分別傳入 subject、body、footer
10. 執行 `git commit --amend`

### --amend 指令格式

只有 subject：

```bash
git commit --amend -m "<subject>"
```

包含 footer：

```bash
git commit --amend -m "<subject>" -m "<footer>"
```

包含 body 與 footer：

```bash
git commit --amend -m "<subject>" -m "<body>" -m "<footer>"
```

## 重要注意事項

* 如果已有特定檔案被暫存，指令只會提交這些檔案
* 如果沒有任何檔案被暫存，會自動暫存所有已修改與新增的檔案
* commit message 會根據偵測到的變更內容建構
* 不得假設專案一定使用 `pnpm`、`npm`、`yarn` 或 `bun`
* 若根目錄不存在 `package.json`，不得執行 Node.js 專案專用檢查
* 若無法判斷 package manager，略過 lint / build 檢查
* 除非使用者明確要求使用 emoji，否則 commit message 預設不使用 emoji
* 如果使用者明確要求使用 emoji，commit message 才會套用對應的 emoji conventional commit 格式
* commit 前，指令會審查 diff，判斷是否更適合拆成多個 commit
* 如果建議拆分成多個 commit，必須先取得使用者確認
* 一律審查 commit diff，確保 commit message 與變更內容一致
* 若分支名稱沒有符合 `[A-Z]+-\d+` 的 issue 編號，commit message 不加入 footer
* `--amend` 會改寫上一個 commit，若該 commit 已推送至遠端，必須先警告使用者並取得確認
