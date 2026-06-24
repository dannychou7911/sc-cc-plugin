---
name: vue-pattern
description: Vue 官方 Style Guide 的規則知識庫，涵蓋 Priority A–D 共 26 條規則（多字元件命名、詳細 prop 定義、keyed v-for、避免 v-if 與 v-for 同元素、scoped 樣式、元件檔案組織與命名 casing、self-closing、多屬性換行、模板簡單表達式、computed 拆分、options/屬性順序、避免隱式父子通訊等），Composition API 與 Options API 範例並陳。撰寫或修改 Vue/Nuxt 程式碼時用來讓產出一開始就符合規範；審查既有 .vue 元件時用來找出違規。只要使用者在新增、修改、重構或審查 Vue 單檔元件（SFC）、template、props、v-for、元件命名、emit/事件、SFC 樣式時，就主動使用本 skill——即使使用者沒有明講「style guide」「規範」「best practice」。涉及 Vue 元件的 code review 也應納入本 skill 的檢查項目。
---

# Vue Pattern — Vue 官方 Style Guide 知識庫

這是 Vue 官方 Style Guide 的可操作版本，用途有兩種：**寫 code 時當規範**、**review code 時當檢查清單**。兩種用途共用同一套規則。

規則分四個優先級（沿用官方分類）。**優先級代表「該多嚴格遵守」，不是「該先讀哪個」**：

| 優先級 | 含義 | 違反的後果 |
|--------|------|-----------|
| **A — Essential** | 防止錯誤 | 可能直接導致 bug，幾乎不該違反 |
| **B — Strongly Recommended** | 可讀性與維護性 | code 仍能跑，但違反應屬罕見且有充分理由 |
| **C — Recommended** | 多個等價選項中取其一以求一致 | 自由選擇，但同一專案內要一致且有理由 |
| **D — Use with Caution** | 高風險功能 | 容易變成 bug 溫床或維護負擔 |

> 官方明言：沒有任何 style guide 適合所有團隊。**若專案既有慣例或 ESLint 設定與本指南衝突，以專案慣例為準**——但要在輸出中指出這個落差，讓使用者知道。

## 兩種使用模式

### 模式一：寫／改 Vue code

產生或修改 `.vue` 元件、template、`<script setup>` 時，把規則當成內建習慣，讓第一版產出就符合規範。重點順序：

1. **先確保 Priority A 全中**（下方有完整內容）——這些是防 bug 底線。
2. 命名、prop、template 寫法照 Priority B（見 `references/priority-b-strongly-recommended.md`）。
3. 程式碼順序、SFC 標籤順序照 Priority C（見 `references/priority-c-recommended.md`）。
4. 避免 Priority D 的高風險寫法（見 `references/priority-d-use-with-caution.md`）。

不需要在輸出裡逐條報告「我遵守了哪條」——直接寫出符合規範的 code 即可。只有在**刻意偏離**某條規則時，才用一句註解或說明點出原因。

### 模式二：Review 既有 Vue code

逐一比對使用者提供的 `.vue` 檔案 / template / diff。建議流程：

1. 讀完 Priority A（inline）後，依需要載入 B/C/D 的 reference 檔。
2. 找出違規，**按優先級排序**回報（A 最優先）。
3. 每條違規給出：違反哪條規則、為什麼有問題（why）、修正寫法。
4. 用下方「審查輸出格式」呈現。

> 注意：環境中可能另有 `vue-style-guide-reviewer` agent。若使用者要的是**完整、獨立的元件審查報告**，優先用那個 agent；本 skill 適合**在一般對話／code review 流程中**順帶套用規則，或當作該 agent 的規則來源。

## 審查輸出格式

review 時用這個結構，讓使用者一眼看出嚴重度與位置：

```
## Vue Style Guide 審查結果

### 🔴 Priority A（必須修正）
- **[規則名稱]** `檔案:行號`
  - 問題：<一句話說明違反什麼、為什麼是問題>
  - 修正：<簡短的正確寫法或方向>

### 🟠 Priority B（強烈建議）
...

### 🟡 Priority C / D（建議 / 謹慎使用）
...

### ✅ 做得好的地方
- <值得肯定的寫法，避免報告只有負面>
```

沒有違規的優先級可省略該區塊。若整體良好，明說「未發現 Priority A/B 違規」，不要硬湊問題。

---

# Priority A — Essential（防止錯誤）

這五條最重要，幾乎不該違反。完整保留於此，寫 code 與 review 都要先過這關。

## A1. 元件名稱用多個單字 {#multi-word-names}

使用者定義的元件名稱一律用多個單字（root `App` 例外）。**why**：所有 HTML 元素都是單字，多字命名可避免與現有及未來的 HTML 元素衝突。

```vue-html
<!-- Bad -->
<Item />          <!-- 預編譯模板 -->
<item></item>     <!-- in-DOM 模板 -->

<!-- Good -->
<TodoItem />
<todo-item></todo-item>
```

## A2. prop 定義要詳細 {#detailed-prop-definitions}

正式提交的 code，prop 至少要標型別。**why**：prop 定義是元件的 API 文件；開發時 Vue 也會對格式錯誤的 prop 發出警告，幫你提早抓到 bug。只有 prototype 階段能用陣列簡寫。

```js
// Bad（只在打草稿時可接受）
// Options API
props: ['status']
// Composition API
const props = defineProps(['status'])
```

```js
// Good — Options API
props: {
  status: {
    type: String,
    required: true,
    validator: (value) =>
      ['syncing', 'synced', 'version-conflict', 'error'].includes(value)
  }
}

// Good — Composition API
const props = defineProps({
  status: {
    type: String,
    required: true,
    validator: (value) =>
      ['syncing', 'synced', 'version-conflict', 'error'].includes(value)
  }
})
```

## A3. `v-for` 一律加 `key` {#keyed-v-for}

`v-for` 用在元件上時 `key` **必填**（維持子樹內部狀態）；用在一般元素上也建議一律加。**why**：排序、刪除、`<transition-group>` 動畫、保持 `<input>` focus 等情境下，`key` 讓 Vue 行為可預測，避免重用到錯誤的 DOM 節點。一律加，就永遠不用煩惱這些邊界案例。

```vue-html
<!-- Bad -->
<li v-for="todo in todos">{{ todo.text }}</li>

<!-- Good -->
<li v-for="todo in todos" :key="todo.id">{{ todo.text }}</li>
```

## A4. 不要在同一元素上同時用 `v-if` 和 `v-for` {#avoid-v-if-with-v-for}

**why**：Vue 3 中 `v-if` 優先級高於 `v-for`，`v-if` 會先求值，此時迭代變數還不存在而報錯。兩種常見動機各有正解：

- **想過濾清單**（`v-for="u in users" v-if="u.isActive"`）→ 改用 computed 回傳過濾後的清單（`activeUsers`）。
- **想整段隱藏清單**（`v-if="shouldShow"`）→ 把 `v-if` 移到外層容器（`<ul>`），或用 `<template v-for>` 包住。

```js
// Good — 用 computed 過濾
// Options API
computed: { activeUsers() { return this.users.filter(u => u.isActive) } }
// Composition API
const activeUsers = computed(() => users.value.filter(u => u.isActive))
```

```vue-html
<!-- Good -->
<ul>
  <li v-for="user in activeUsers" :key="user.id">{{ user.name }}</li>
</ul>

<!-- 或用 template 包裹 -->
<ul>
  <template v-for="user in users" :key="user.id">
    <li v-if="user.isActive">{{ user.name }}</li>
  </template>
</ul>
```

## A5. 元件樣式要 scoped {#scoped-styling}

除了 top-level `App` 與 layout 元件可用 global style，其餘元件的樣式都該侷限在元件內。**why**：避免樣式外洩污染其他元件，尤其在大型專案、多人協作或引入第三方 HTML/CSS 時。

侷限的手段不限 `scoped` attribute——也可用 CSS Modules（`<style module>`）或 BEM 等 class 命名策略。**元件庫（component library）應偏好 class 策略而非 `scoped`**，方便使用者覆寫內部樣式。

```vue-html
<!-- Bad：全域 class，容易撞名外洩 -->
<template><button class="btn btn-close">×</button></template>
<style>.btn-close { background-color: red; }</style>

<!-- Good：scoped -->
<template><button class="button button-close">×</button></template>
<style scoped>.button-close { background-color: red; }</style>
```

---

# Priority B / C / D — 依需要載入

完整規則與 Composition + Options 範例放在 references/，避免本檔過長。**review 時建議全部載入；寫 code 時依當下情境查閱對應檔案**：

- **`references/priority-b-strongly-recommended.md`**（15 條，最常用）：元件檔案組織、SFC 檔名 casing、Base 元件前綴、緊耦合元件命名、命名由大到小排序、self-closing、template/JS 中的元件名 casing、完整單字命名、prop 名 casing、多屬性換行、模板只放簡單表達式、computed 拆分、屬性值加引號、directive 縮寫一致性。
- **`references/priority-c-recommended.md`**（4 條）：component/instance options 順序、元素 attribute 順序、options 間空行、SFC 頂層 `<script>`/`<template>`/`<style>` 順序。
- **`references/priority-d-use-with-caution.md`**（2 條）：`scoped` 下避免 element selector（用 class）、避免隱式父子通訊（偏好 props down / events up，勿 mutate prop 或用 `this.$parent`）。

## 各 reference 檔的規則速查

寫 code 或 review 前，可先用這份索引判斷該翻哪一條：

| 規則 | 優先級 | 檔案 |
|------|--------|------|
| 一個元件一個檔案 | B | priority-b |
| SFC 檔名 PascalCase 或 kebab-case（擇一一致） | B | priority-b |
| Base/共用元件加 `Base`/`App`/`V` 前綴 | B | priority-b |
| 緊耦合子元件以父元件名為前綴 | B | priority-b |
| 元件名由「最高層級」到「修飾詞」排序 | B | priority-b |
| 無內容元件用 self-closing（in-DOM 模板除外） | B | priority-b |
| template/JS 中元件名 PascalCase（in-DOM 用 kebab-case） | B | priority-b |
| prop 宣告用 camelCase | B | priority-b |
| 元件名用完整單字、不縮寫 | B | priority-b |
| 多屬性元素一行一個屬性 | B | priority-b |
| 模板只放簡單表達式（複雜的搬到 computed/method） | B | priority-b |
| 複雜 computed 拆成多個簡單 computed | B | priority-b |
| 非空 attribute 值加引號 | B | priority-b |
| directive 縮寫（`:` `@` `#`）全用或全不用 | B | priority-b |
| component/instance options 固定順序 | C | priority-c |
| 元素 attribute 固定順序 | C | priority-c |
| 多行屬性間可加空行 | C | priority-c |
| SFC 頂層標籤順序（`<style>` 放最後） | C | priority-c |
| `scoped` 下用 class selector，避免 element selector | D | priority-d |
| 偏好 props down / events up，避免 mutate prop、`this.$parent` | D | priority-d |
