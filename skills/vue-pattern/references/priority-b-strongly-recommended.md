# Priority B — Strongly Recommended（強烈建議）

這些規則能改善可讀性與開發體驗。違反不會讓 code 跑不起來，但應屬罕見且要有充分理由。共 15 條。

---

## B1. 一個元件一個檔案 {#component-files}

只要 build system 能拼接檔案，每個元件就該放在自己的檔案裡。**why**：要編輯或查看某元件用法時，能更快找到它。

```
// Good
components/
|- TodoList.vue
|- TodoItem.vue
```

避免在單一檔案中用 `app.component('TodoList', {...})`、`app.component('TodoItem', {...})` 連續註冊多個元件。

---

## B2. SFC 檔名 casing：全 PascalCase 或全 kebab-case {#filename-casing}

整個專案的 SFC 檔名要嘛一律 `PascalCase.vue`，要嘛一律 `kebab-case.vue`，不要混用。**why**：PascalCase 與編輯器自動補全、JS/template 中的引用方式一致；但在不分大小寫的檔案系統上混用大小寫會出問題，所以 kebab-case 也完全可接受。重點是**一致**。

```
// Bad
mycomponent.vue
myComponent.vue

// Good（擇一，全專案一致）
MyComponent.vue
my-component.vue
```

---

## B3. Base 元件加固定前綴 {#base-component-names}

套用 app 層級樣式與慣例的基礎元件（presentational / dumb / pure component）應以固定前綴開頭，如 `Base`、`App` 或 `V`。**why**：這類元件只含 HTML 元素、其他 base 元件、第三方 UI 元件，**永不含全域狀態（如 Pinia store）**。固定前綴讓它們在編輯器中按字母排序時聚在一起，也方便用 glob 全域註冊。

```
// Bad
components/
|- MyButton.vue
|- VueTable.vue
|- Icon.vue

// Good（三種前綴擇一）
BaseButton.vue / AppButton.vue / VButton.vue
BaseTable.vue  / AppTable.vue  / VTable.vue
BaseIcon.vue   / AppIcon.vue   / VIcon.vue
```

---

## B4. 緊耦合子元件以父元件名為前綴 {#tightly-coupled-names}

只在單一父元件脈絡下才有意義的子元件，名稱應以父元件名為前綴。**why**：讓耦合關係從名稱上一目了然；編輯器按字母排序時相關檔案也會相鄰。比用巢狀資料夾更好——巢狀會產生大量同名檔（`index.vue`）且增加瀏覽成本。

```
// Bad
components/
|- TodoList.vue
|- TodoItem.vue
|- TodoButton.vue

// Good
components/
|- TodoList.vue
|- TodoListItem.vue
|- TodoListItemButton.vue
```

---

## B5. 元件名由「最高層級」到「修飾詞」排序 {#order-of-words}

元件名稱應以最高層級（通常最一般）的字開頭，以描述性修飾字結尾。**why**：編輯器按字母排序時，同類元件會自然聚在一起，關係一目了然。「最高層級」是相對於你的 app 脈絡而言的。

```
// Bad
ClearSearchButton.vue
RunSearchButton.vue
SearchInput.vue
TermsCheckbox.vue

// Good
SearchButtonClear.vue
SearchButtonRun.vue
SearchInputQuery.vue
SettingsCheckboxTerms.vue
```

---

## B6. 無內容元件用 self-closing {#self-closing}

在 SFC、字串模板、JSX 中，沒有內容的元件用 self-closing；**但 in-DOM 模板絕不可以**。**why**：self-closing 明確表達「這元件本就不該有內容」，也讓 code 更乾淨。HTML 不允許自訂元素 self-closing，只有 Vue 編譯器能在進 DOM 前處理掉。

```vue-html
<!-- Bad（SFC / 字串模板 / JSX 中多餘的閉合） -->
<MyComponent></MyComponent>
<!-- Bad（in-DOM 模板不能 self-close） -->
<my-component/>

<!-- Good（SFC / 字串模板 / JSX） -->
<MyComponent/>
<!-- Good（in-DOM 模板） -->
<my-component></my-component>
```

---

## B7. template 中元件名的 casing {#casing-in-templates}

多數專案中，SFC 與字串模板裡的元件名一律 PascalCase；**in-DOM 模板因 HTML 不分大小寫，必須用 kebab-case**。**why**：PascalCase 可自動補全、與單字 HTML 元素視覺上差異更明顯、與非 Vue 的 web component 區隔。若團隊已大量投資 kebab-case，**全專案都用 kebab-case 也可接受**。

```vue-html
<!-- Good（SFC / 字串模板） -->
<MyComponent/>
<!-- Good（in-DOM 模板） -->
<my-component></my-component>
```

---

## B8. JS/JSX 中元件名的 casing {#casing-in-js}

JS/JSX 中的元件名一律 PascalCase；只有「僅透過 `app.component` 做全域註冊」的簡單 app 才建議在字串中用 kebab-case。**why**：JS 慣例中 PascalCase 代表可有實例的東西（class、建構式），Vue 元件也有實例。

```js
// Bad
app.component('myComponent', {})
import myComponent from './MyComponent.vue'
export default { name: 'my-component' }

// Good
app.component('MyComponent', {})         // 或全域註冊用 'my-component'
import MyComponent from './MyComponent.vue'
export default { name: 'MyComponent' }
```

---

## B9. 元件名用完整單字，不縮寫 {#full-word-names}

偏好完整單字而非縮寫，尤其避免不常見的縮寫。**why**：編輯器自動補全讓長名稱成本極低，但清晰度價值極高。

```
// Bad
SdSettings.vue
UProfOpts.vue

// Good
StudentDashboardSettings.vue
UserProfileOptions.vue
```

---

## B10. prop 宣告用 camelCase {#prop-name-casing}

prop **宣告**時一律 camelCase。in-DOM 模板中使用時必須 kebab-case；SFC 模板與 JSX 中 kebab-case 或 camelCase 皆可，但**全專案要一致，不要混用**。**why**：與 JS 變數命名慣例一致。

```js
// Bad
props: { 'greeting-text': String }                 // Options
const props = defineProps({ 'greeting-text': String })  // Composition

// Good
props: { greetingText: String }
const props = defineProps({ greetingText: String })
```

```vue-html
<!-- Good：SFC 模板（擇一一致） -->
<WelcomeMessage greeting-text="hi"/>
<WelcomeMessage greetingText="hi"/>
<!-- Good：in-DOM 模板必須 kebab-case -->
<welcome-message greeting-text="hi"></welcome-message>
```

---

## B11. 多屬性元素一行一個屬性 {#multi-attribute-elements}

有多個 attribute 的元素應跨多行，一行一個。**why**：與 JS 中多屬性物件換行同理，可讀性更好。

```vue-html
<!-- Bad -->
<MyComponent foo="a" bar="b" baz="c"/>

<!-- Good -->
<MyComponent
  foo="a"
  bar="b"
  baz="c"
/>
```

---

## B12. 模板只放簡單表達式 {#simple-expressions}

複雜表達式應抽到 computed property 或 method。**why**：模板應描述「該顯示什麼」(what)，而非「怎麼算出來」(how)；抽出後也可重用、可測試。

```vue-html
<!-- Bad -->
{{ fullName.split(' ').map(w => w[0].toUpperCase() + w.slice(1)).join(' ') }}

<!-- Good -->
{{ normalizedFullName }}
```

```js
// Options API
computed: {
  normalizedFullName() {
    return this.fullName.split(' ')
      .map(w => w[0].toUpperCase() + w.slice(1)).join(' ')
  }
}
// Composition API
const normalizedFullName = computed(() =>
  fullName.value.split(' ')
    .map(w => w[0].toUpperCase() + w.slice(1)).join(' ')
)
```

---

## B13. 複雜 computed 拆成多個簡單 computed {#simple-computed}

**why**：小而具名的 computed 更易測試、易讀（每個值都被迫取個描述性名字）、更能適應需求變動。

```js
// Bad — Composition API
const price = computed(() => {
  const basePrice = manufactureCost.value / (1 - profitMargin.value)
  return basePrice - basePrice * (discountPercent.value || 0)
})

// Good — Composition API
const basePrice = computed(() => manufactureCost.value / (1 - profitMargin.value))
const discount  = computed(() => basePrice.value * (discountPercent.value || 0))
const finalPrice = computed(() => basePrice.value - discount.value)
```

```js
// Good — Options API
computed: {
  basePrice() { return this.manufactureCost / (1 - this.profitMargin) },
  discount() { return this.basePrice * (this.discountPercent || 0) },
  finalPrice() { return this.basePrice - this.discount }
}
```

---

## B14. 非空 attribute 值加引號 {#quoted-attributes}

非空的 HTML attribute 值一律加引號（單雙引號擇一，與 JS 不衝突即可）。**why**：不加引號會誘使人避免使用空格，反而降低可讀性。

```vue-html
<!-- Bad -->
<input type=text>
<AppSidebar :style={width:sidebarWidth+'px'}>

<!-- Good -->
<input type="text">
<AppSidebar :style="{ width: sidebarWidth + 'px' }">
```

---

## B15. directive 縮寫全用或全不用 {#directive-shorthands}

`:`（`v-bind:`）、`@`（`v-on:`）、`#`（`v-slot:`）這些縮寫，要嘛總是用、要嘛總是不用，**不要在同類 directive 間混用**。**why**：一致性。可以 `v-bind` 全部用縮寫、`v-on` 全部用全寫——只要同一種 directive 內部一致即可。

```vue-html
<!-- Bad（同為 v-bind 卻一個縮寫一個全寫） -->
<input v-bind:value="text" :placeholder="hint">

<!-- Good -->
<input :value="text" :placeholder="hint">
<!-- 或全寫 -->
<input v-bind:value="text" v-bind:placeholder="hint">
```
