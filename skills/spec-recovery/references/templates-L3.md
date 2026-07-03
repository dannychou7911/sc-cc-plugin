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
> **分析基準**：{git short SHA}
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
> **分析基準**：{git short SHA}
> **用途**：記錄前後端之間的隱性假設與已知差異

| API               | 差異描述                              | 風險等級 | 處理方式     |
| ----------------- | ------------------------------------- | -------- | ------------ |
| {API 路徑}        | {差異描述}                            | 高/中/低 | {如何處理}   |
```

---

## 模板 D：權限矩陣

> 檔案：`L3-api/permission-matrix.md`。每個模組完成 Phase 4 後**增量更新**同一份檔案。
> 資料全部來自既有 L2/L3 文件（L2 進入條件、L3 角色限制），純彙整、成本趨近於零。
> 最大價值：矩陣拼合後，前後端權限不一致會自動浮現。

```markdown
# 權限矩陣

> **層次**：L3 — API 規格
> **最後更新**：{YYYY-MM-DD}
> **分析基準**：{git short SHA}

## 頁面 × 角色

（來源：各 L2 文件的進入條件）

| 頁面 | {角色A} | {角色B} | 備註 |
|------|---------|---------|------|
| {頁面名} | ✓ | ✗ | {條件式描述，如「僅自己的資料」} |

## API × 角色

（來源：L3 各 API 的角色限制）

| API | {角色A} | {角色B} | 備註 |
|-----|---------|---------|------|
| {方法 路徑} | ✓ | ✗ | |

## 前後端權限不一致

（矩陣拼合後浮現的不一致，列入隱性規則並標 [待確認]）

| # | 不一致描述 | 風險 | 狀態 |
|---|-----------|------|------|
| 1 | {如：頁面 X 允許 editor 進入，但其主要 API 僅限 admin} | 🔴 | [待確認] |
```

---

## 產出指引

### Swagger 比對模式（Phase 0 掃到後端 API 文件時）

以 swagger/openapi 為後端契約的 source of truth，工作從「反推」變成「比對」：

1. 列出前端實際呼叫的端點與假設（使用的參數、假設的必填性、消費的回應欄位）
2. 與 swagger 宣告逐一比對，找出：前端用了未宣告的欄位、前端假設必填但宣告為選填、命名/格式差異
3. 差異填入模板 C「前後端契約差異追蹤表」

### OpenAPI 反推產出（無 swagger 時可選）

從前端反推的 API 規格僅覆蓋「前端實際使用的子集」，且參數/回應為呼叫端推斷，可能與後端實際定義有落差（後端可能接受更多可選參數、回傳更多欄位）。若產出 OpenAPI YAML，`info.description` 必須標註：

> 由前端呼叫端反推，非後端宣告，僅代表前端消費的子集。

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
