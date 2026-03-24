# L3 — API 規格模板

> **目標讀者**：前端工程師、後端工程師、QA
> **更新頻率**：API 變更時即時更新
> **篇幅**：依 API 數量而定

---

## 模板 A：API 總表

```markdown
# API 規格總表

> **層次**：L3 — API 規格
> **最後更新**：{YYYY-MM-DD}
> **狀態**：初版 / 已驗證 / 待更新

## Base URL

| 環境        | URL                          |
| ----------- | ---------------------------- |
| Development | {URL}                        |
| Staging     | {URL}                        |
| Production  | {URL}                        |

## 認證方式

{描述認證機制，如 Bearer Token / JWT / Cookie / API Key}

## 共通錯誤回應格式

```json
{
  "error": {
    "code": "{ERROR_CODE}",
    "message": "{人類可讀訊息}",
    "details": {}
  }
}
```

## 共通 HTTP 狀態碼

| 狀態碼 | 意義           | 前端處理方式       |
| ------ | -------------- | ------------------ |
| 200    | 成功           | 正常處理           |
| 201    | 建立成功       | 正常處理           |
| 400    | 驗證失敗       | 顯示欄位錯誤       |
| 401    | 未認證         | 導向登入頁         |
| 403    | 權限不足       | 顯示錯誤訊息       |
| 404    | 資源不存在     | 顯示 404 頁面      |
| 409    | 狀態衝突       | 顯示錯誤並重新載入 |
| 422    | 語義錯誤       | 顯示錯誤訊息       |
| 500    | 伺服器錯誤     | 顯示通用錯誤       |

## API 清單

| 方法   | 路徑              | 認證 | 角色     | 說明         | 詳細規格         |
| ------ | ----------------- | ---- | -------- | ------------ | ---------------- |
| {方法} | {路徑}            | {有/無}| {角色} | {一句話說明} | [連結](./xxx.md) |
```

---

## 模板 B：單支 API 詳細規格

```markdown
## {HTTP_METHOD} {path} — {API 名稱}

**說明**：{功能描述}
**權限**：{認證需求 + 角色}

### Request

#### Path Parameters（如適用）

| 參數   | 型別   | 說明         |
| ------ | ------ | ------------ |
| {name} | {type} | {說明}       |

#### Query Parameters（如適用）

| 參數   | 型別   | 必填 | 預設值 | 說明         |
| ------ | ------ | ---- | ------ | ------------ |
| {name} | {type} | 是/否| {值}   | {說明}       |

#### Request Body（如適用）

```typescript
interface {RequestTypeName} {
  {field}: {type};  // {說明}
}
```

#### Request 範例

```json
{
  "field": "value"
}
```

### Response

#### 成功回應：{status code}

Response Body：

```typescript
interface {ResponseTypeName} {
  {field}: {type};  // {說明}
}
```

#### 成功回應範例

```json
{
  "field": "value"
}
```

#### 錯誤回應

| 狀態碼 | 情境           | error.code         |
| ------ | -------------- | ------------------- |
| {code} | {觸發情境}     | {ERROR_CODE}       |

### 前後端契約注意事項

（使用 🔴/🟡 分級標記，標準見 references/implicit-rules-standard.md）

🔴 **{注意事項}**：{描述}

🟡 **{注意事項}**：{描述}
```

---

## 模板 C：前後端契約差異追蹤表

```markdown
# 前後端契約差異追蹤

> **最後更新**：{YYYY-MM-DD}
> **用途**：記錄前後端之間的隱性假設與已知差異

| API               | 差異描述                              | 風險等級 | 處理方式     |
| ----------------- | ------------------------------------- | -------- | ------------ |
| {API 路徑}        | {差異描述}                            | 高/中/低 | {如何處理}   |
```

---

## 產出指引

### 從 API 層反推 API 規格

當只有前端或後端 code 時，從以下來源反推：

#### 來源 1：API Service / Client 檔案

從 HTTP client 的呼叫中萃取：HTTP method、path、request 型別、response 型別。

#### 來源 2：型別定義

TypeScript interface / Python dataclass / Go struct 等型別定義通常就是最精確的 request/response 規格。

#### 來源 3：HTTP Client Interceptors / Middleware

全域的 request/response 攔截器揭示了認證方式和全域錯誤處理策略。

#### 來源 4：後端 Controller / Route Handler

從 controller 的裝飾器、middleware、guard 中萃取認證、角色、驗證規則。

### 常見的前後端契約陷阱

| 陷阱 | 如何偵測 |
|------|---------|
| camelCase / snake_case 轉換 | 看 interceptor 或 serializer 的命名轉換 |
| 分頁資訊位置不一致 | 看是從 response headers 還是 body 取得 |
| 日期格式差異 | 搜尋日期格式化呼叫（dayjs / moment / date-fns / strftime） |
| 空值表示方式 | `null` vs `undefined` vs `""` vs 不傳 |
| 陣列為空時 | `[]` vs `null` vs 不包含此欄位 |
| 數字精度 | 搜尋 `toFixed`、`Math.round`、`DECIMAL`、`BigDecimal` |
| 檔案上傳 | 是否用 `FormData` / `multipart` |
| 大小寫敏感的 enum | 前端 `'Draft'` vs 後端 `'draft'` |
