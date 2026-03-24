# Vue 3 專案萃取模式

偵測到 Vue 3 專案時（package.json 含 `vue` ^3.x），載入此文件輔助分析。

---

## SFC 檔案讀取策略

Vue SFC（`.vue`）包含 `<template>`、`<script>`、`<style>` 三個區塊，分析時應優先讀取邏輯相關區塊：

- 優先讀取 `<script>` / `<script setup>` 區塊（用 Grep `<script` 找起始行，再用 `offset` + `limit` 精準讀取）
- `<template>` 僅在分析 UI 行為、條件渲染規則時讀取
- `<style>` 通常可跳過，除非分析動態 class 綁定

---

## 前端分析順序

```
路由表（router/index.ts）→ 頁面清單（views/）→ 逐頁互動行為
→ Store（Pinia / Vuex）→ 表單與驗證
→ 條件渲染規則 → API 呼叫層（services/）
```

---

## 萃取條件渲染規則

搜尋以下 Vue 語法：

```vue
v-if="..."
v-else-if="..."
v-else
v-show="..."
:class="{ 'is-active': condition }"
:disabled="condition"
:style="condition ? styleA : styleB"
```

每個條件轉換為自然語言描述，填入 L2「條件渲染規則」表格。

---

## 萃取使用者操作

| Vue 語法 | 代表的操作類型 |
|---------|--------------|
| `@click` | 按鈕點擊操作 |
| `@input` / `@change` | 輸入/選擇操作 |
| `@submit` / `@validate` | 表單送出 |
| `@keyup.enter` | 鍵盤快捷操作 |
| `watch(...)` 監聽篩選值 | 自動觸發的查詢 |

每個事件追蹤到它呼叫的 function，再追蹤 function 做了什麼（呼叫 store action？呼叫 API？更新 state？導航？）。

---

## 萃取表單驗證規則

### Element Plus

```typescript
const rules = {
  customerName: [
    { required: true, message: '請輸入客戶名稱', trigger: 'blur' },
    { min: 1, max: 50, message: '長度需在 1-50 字元之間', trigger: 'blur' },
  ],
};

// 自訂 validator
const validatePhone = (rule, value, callback) => {
  if (!/^(09\d{8})$/.test(value)) {
    callback(new Error('請輸入正確的手機號碼格式'));
  }
  callback();
};
```

### Vuelidate

```typescript
const rules = computed(() => ({
  name: { required, minLength: minLength(1), maxLength: maxLength(50) },
  email: { required, email },
}));
```

### VeeValidate + Zod/Yup

```typescript
const schema = z.object({
  name: z.string().min(1).max(50),
  email: z.string().email(),
});
```

---

## 萃取資料流

1. 從元件的 `onMounted` / `<script setup>` 頂層開始，追蹤初始載入
2. 追蹤 store action 的呼叫鏈：`action → API service → axios`
3. 追蹤 store state 被哪些 `computed` / `watch` 消費
4. 串起來就是資料流

---

## 萃取 Composable 規格

搜尋 `src/composables/` 或 `use*.ts` 檔案：

```typescript
// 從 composable 的回傳值可以看出它提供什麼能力
export function useOrderActions(orderId: Ref<string>) {
  const loading = ref(false);
  const submit = async () => { ... };
  const cancel = async () => { ... };
  return { loading, submit, cancel };
}
```

記錄：名稱、參數、回傳值、使用位置。

---

## 萃取導航行為

搜尋以下模式：

```typescript
router.push(...)
router.replace(...)
router.go(...)
router.back()
```

以及 `<router-link>` 元件中的 `to` prop。

---

## 萃取依賴關係

掃描 import 語句的模式：

- `import from '@/stores/...'` → store 依賴
- `import from '@/composables/...'` → composable 依賴
- `import from '@/components/...'` → 元件依賴
- `import from '@/services/...'` / `import from '@/api/...'` → API 服務依賴

---

## 萃取隱性規則（Vue 特有）

```typescript
// 模式：非同步依賴
await fetchProducts(); // 必須先取得商品清單
await fetchOrder();     // 才能正確顯示訂單的商品名稱
// ⚠️ 這兩個 API 有順序依賴

// 模式：欄位轉換
payload.delivery_date = dayjs(form.deliveryDate).format('YYYY-MM-DD');
// ⚠️ 前端是 Date 物件，送出時轉為字串

// 模式：靜默截斷
form.note = form.note.slice(0, 500);
// ⚠️ 超過 500 字元時前端直接截斷，不顯示錯誤

// 模式：nextTick 依賴
await nextTick();
formRef.value?.scrollToField('name');
// ⚠️ DOM 更新後才能操作表單
```
