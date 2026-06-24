# Priority C — Recommended（建議）

當多個選項同樣好時，任選一個以求一致即可。以下是官方建議的預設選擇——你可以在自己的 codebase 做不同選擇，**只要全專案一致且有充分理由**。共 4 條。

---

## C1. component / instance options 固定順序 {#options-order}

主要適用 Options API。建議順序（依類別分組，方便知道新屬性該插哪）：

1. **Global Awareness**：`name`
2. **Template Compiler Options**：`compilerOptions`
3. **Template Dependencies**：`components`、`directives`
4. **Composition**：`extends`、`mixins`、`provide`/`inject`
5. **Interface**：`inheritAttrs`、`props`、`emits`、`expose`
6. **Composition API 進入點**：`setup`
7. **Local State**：`data`、`computed`
8. **Events**：`watch`、生命週期（依呼叫順序：`beforeCreate` → `created` → `beforeMount` → `mounted` → `beforeUpdate` → `updated` → `activated` → `deactivated` → `beforeUnmount` → `unmounted` → `errorCaptured` → `renderTracked` → `renderTriggered` → `serverPrefetch`）
9. **Non-Reactive Properties**：`methods`
10. **Rendering**：`template`/`render`

---

## C2. 元素 attribute 固定順序 {#attribute-order}

元素（含元件）的 attribute 建議順序：

1. **Definition**：`is`
2. **List Rendering**：`v-for`
3. **Conditionals**：`v-if`、`v-else-if`、`v-else`、`v-show`、`v-cloak`
4. **Render Modifiers**：`v-pre`、`v-once`
5. **Global Awareness**：`id`
6. **Unique Attributes**：`ref`、`key`
7. **Two-Way Binding**：`v-model`
8. **Other Attributes**：所有其他綁定與非綁定 attribute
9. **Events**：`v-on` / `@`
10. **Content**：`v-html`、`v-text`

---

## C3. options 間可加空行 {#empty-lines}

當元件變得擁擠難讀時，可在多行屬性之間加一個空行。**why**：方便略讀；某些編輯器（如 Vim）也更好用鍵盤導航。沒加空行也完全可以，只要元件仍易讀易導航。這是彈性建議，不是硬規則。

```js
// Good — Composition API（屬性之間留空行）
defineProps({
  value: { type: String, required: true },

  focused: { type: Boolean, default: false },

  label: String,
  icon: String
})

const formattedValue = computed(() => { /* ... */ })

const inputClasses = computed(() => { /* ... */ })
```

---

## C4. SFC 頂層標籤順序 {#sfc-top-level-order}

SFC 的 `<script>`、`<template>`、`<style>` 順序要一致，且 **`<style>` 永遠放最後**（因為 `<script>` 與 `<template>` 至少有一個一定存在）。**why**：全專案一致的順序降低閱讀切換成本。

```vue-html
<!-- Good（兩種順序皆可，但全專案要一致） -->
<script>/* ... */</script>
<template>...</template>
<style>/* ... */</style>

<!-- 或 -->
<template>...</template>
<script>/* ... */</script>
<style>/* ... */</style>
```
