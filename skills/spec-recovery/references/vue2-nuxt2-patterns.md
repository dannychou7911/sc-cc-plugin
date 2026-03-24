# Vue 2 / Nuxt 2 萃取模式

> 適用於使用 Vue 2 + Nuxt 2 的專案。涵蓋路由、Options API、Vuex、Plugins、Mixins 的分析策略。

---

## 路由分析（Nuxt 2 檔案式路由）

Nuxt 2 使用 `pages/` 目錄自動生成路由，不需要手動路由設定檔。

**掃描方式**：

```
Glob: pages/**/*.vue → 頁面清單
```

**路由對應規則**：

| 檔案路徑 | 路由 | 說明 |
|---------|------|------|
| `pages/index.vue` | `/` | 首頁 |
| `pages/login.vue` | `/login` | 靜態路由 |
| `pages/member/_id.vue` | `/member/:id` | 動態路由 |
| `pages/member/index.vue` | `/member` | 巢狀路由的 index |

**注意事項**：
- `middleware` 屬性定義路由守衛（寫在元件內或 `nuxt.config.js`）
- `layout` 屬性指定佈局（預設為 `layouts/default.vue`）
- `asyncData` / `fetch` 為 SSR 資料載入鉤子

**隱性規則偵測**：
- 🔴 `middleware` 中的認證/權限判斷 — 影響路由可達性
- 🟡 `layout` 指定 — 影響頁面外觀但不影響邏輯

---

## Options API 萃取

Vue 2 使用 Options API，關鍵萃取點：

### 生命週期鉤子

```
Grep: "mounted\s*\(" | "created\s*\(" | "beforeDestroy\s*\("
```

| 鉤子 | 關注重點 |
|------|---------|
| `created` | API 呼叫、初始化邏輯 |
| `mounted` | DOM 操作、第三方庫初始化 |
| `beforeDestroy` | 清理（Timer、EventListener、Subscription） |
| `watch` (immediate) | 等同 created 時觸發 |

### 計算屬性（computed）

搜尋 `computed:` 區塊，這些通常包含條件渲染邏輯和資料轉換。

### Methods

搜尋 `methods:` 區塊，結合模板中的事件綁定（`@click`、`@input`、`@change`）追蹤互動行為。

---

## Vuex Store 分析

**目錄結構**：通常在 `store/` 下，Nuxt 2 自動註冊。

```
Glob: store/**/*.js → Store 模組清單
```

**關鍵結構**：

| 區塊 | 萃取重點 |
|------|---------|
| `state` | 應用狀態的資料結構 |
| `mutations` | 同步狀態變更（命名揭示行為） |
| `actions` | 非同步操作（API 呼叫、業務邏輯） |
| `getters` | 衍生狀態（條件渲染依據） |

**搜尋模式**：

```
Grep: "commit\(" → 找出所有 mutation 呼叫點
Grep: "dispatch\(" → 找出所有 action 呼叫點
Grep: "mapState\|mapGetters\|mapActions\|mapMutations" → 找出元件與 Store 的綁定
```

**隱性規則偵測**：
- 🔴 `mutations` 中的資料轉換/合併邏輯 — 如 `Object.assign` 的覆蓋順序
- 🔴 `actions` 中的 API 呼叫順序依賴
- 🟡 `getters` 中的複雜計算邏輯

---

## Plugins 分析

Nuxt 2 的 `plugins/` 目錄包含全域擴展。

```
Glob: plugins/**/*.js → Plugin 清單
```

**常見模式**：

| 模式 | 說明 | 萃取重點 |
|------|------|---------|
| `inject` | 注入全域方法（`$xxx`） | 被注入的方法名稱與用途 |
| Axios interceptor | 請求/回應攔截器 | 認證、錯誤處理、Token 刷新 |
| Router guard | 路由守衛 | 認證、權限檢查 |
| 第三方初始化 | 如 i18n、analytics | 設定方式與依賴 |

**`nuxt.config.js` 中的 Plugin 設定**：

```
Grep: "plugins:" → 查看 plugin 載入順序與 SSR/Client 模式
```

- `mode: 'client'` — 僅客戶端載入
- `mode: 'server'` — 僅伺服端載入
- 無指定 — SSR + Client 都載入

**隱性規則偵測**：
- 🔴 Plugin 載入順序 — 某些 plugin 依賴其他 plugin 先初始化
- 🔴 SSR vs Client 模式 — 錯誤的模式會導致 hydration mismatch 或 runtime error

---

## Mixins 分析

Vue 2 大量使用 Mixins 做程式碼重用。

```
Glob: mixins/**/*.js | **/mixin*.js → Mixin 清單
Grep: "mixins:\s*\[" → 找出使用 Mixin 的元件
```

**萃取重點**：

| 項目 | 說明 |
|------|------|
| 注入的 data | Mixin 提供的響應式資料 |
| 注入的 methods | Mixin 提供的方法 |
| 注入的 computed | Mixin 提供的計算屬性 |
| 生命週期鉤子 | Mixin 和元件的鉤子會**合併執行**（Mixin 先） |
| 命名衝突 | 元件自身的屬性會覆蓋 Mixin 同名屬性 |

**隱性規則偵測**：
- 🔴 Mixin 與元件的命名衝突 — 元件覆蓋 Mixin 可能是刻意的也可能是 bug
- 🔴 多個 Mixin 之間的交互作用 — Mixin A 依賴 Mixin B 注入的 data
- 🟡 Mixin 中的生命週期鉤子 — 閱讀元件時容易遺漏

---

## Nuxt 2 特殊功能

### asyncData / fetch

```
Grep: "asyncData\s*\(" → SSR 資料載入
Grep: "fetch\s*\(" → 可在 SSR 和 Client 執行的資料載入
```

- `asyncData`：回傳值會合併到 `data()`，僅在 page 元件可用
- `fetch`：可在任何元件使用，透過 `this` 存取狀態

### Server Middleware

```
Glob: server/middleware/**/* | serverMiddleware/**/*
```

Nuxt 2 的 `serverMiddleware` 在 `nuxt.config.js` 中設定，用於 API 路由或代理。

### 環境變數

```
Grep: "process\.env\." → 所有環境變數引用
Grep: "env:" → nuxt.config.js 中的環境變數設定
```

Nuxt 2 透過 `nuxt.config.js` 的 `env` 和 `publicRuntimeConfig` / `privateRuntimeConfig` 注入環境變數。
