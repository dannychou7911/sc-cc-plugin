# Interview Questions

當原始碼不可用時（僅口述或截圖），使用本問題庫進行延伸訪談。

---

## 1. Project Identity

- 專案名稱是什麼？解決什麼問題？
- 主要使用者是誰？（內部團隊 / 終端客戶 / 兩者都有）
- 開發多久了？目前有幾位工程師維護？
- 是否有任何現有文件？（Confluence、README、wiki、Notion）

## 2. Tech Stack

- 使用什麼語言和框架？
- 使用什麼資料庫？
- 部署在哪裡？（AWS、GCP、self-hosted 等）
- 是否有 CI/CD pipeline？使用什麼工具？

## 3. Architecture

- 是 monolith、microservices、還是混合型？
- 專案怎麼組織？（按 feature、按 layer、還是混合？）
- 前後端怎麼通訊？（REST、GraphQL、gRPC）
- 是否有 message queue 或 event system？

## 4. Feature Inventory

- 能列出主要功能/模組嗎？（即使只是名稱也好）
- 哪些功能對業務最關鍵？
- 哪些功能目前最常修改？
- 是否有已棄用但還在 codebase 中的功能？

## 5. Authentication & Authorization

- 使用者怎麼登入？
- 有哪些角色/權限？
- 權限怎麼執行？
- 是否有多租戶架構？

## 6. Data Model

- 主要的實體/資料表有哪些？
- 實體之間的關鍵關係是什麼？
- 是否有複雜的業務規則在資料驗證上？
- 是否有軟刪除、版本控制、或稽核軌跡？

## 7. Integrations

- 整合了哪些外部服務？
- 是否有 webhook？
- 是否有排程任務或 cron job？

## 8. Pain Points

- 哪些部分的 code 最讓人困惑？
- 有什麼已知的 bug 或技術債？
- 如果只能選 3 個模組寫文件，會選哪 3 個？
- 有哪些部分需要 tribal knowledge 才能理解？

---

## 使用方式

- 每次問 3-5 題，按章節分批。
- 跳過使用者明顯無法回答的章節。
- 用答案建構規格結構，所有項目標記為 `[使用者提供]`。
- 訪談結束後，按 spec template 產出規格。
