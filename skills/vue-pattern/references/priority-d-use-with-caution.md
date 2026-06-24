# Priority D — Use with Caution（謹慎使用）

Vue 有些功能是為了罕見邊界案例或舊專案遷移而存在。過度使用會讓 code 難維護甚至變成 bug 來源。這些規則點出高風險功能，說明何時與為何該避免。共 2 條。

---

## D1. `scoped` 樣式中避免 element selector {#element-selectors-scoped}

`scoped` 樣式中，偏好 class selector 而非 element selector。**why**：為了 scope，Vue 會在元素上加唯一 attribute（如 `data-v-f3f3eg9`），並把 selector 改寫成 `button[data-v-f3f3eg9]` 這種 attribute selector。大量的「元素 + attribute」selector（如 `button[data-v-f3f3eg9]`）會明顯慢於「class + attribute」selector（如 `.btn-close[data-v-f3f3eg9]`），所以盡量用 class。

```vue-html
<!-- Bad -->
<template><button>×</button></template>
<style scoped>
button { background-color: red; }
</style>

<!-- Good -->
<template><button class="btn btn-close">×</button></template>
<style scoped>
.btn-close { background-color: red; }
</style>
```

---

## D2. 避免隱式父子通訊 {#implicit-parent-child}

父子元件通訊應偏好 **props down / events up**，而非 `this.$parent` 或直接 mutate prop。**why**：理想的 Vue app 是「props 往下、events 往上」，這讓資料流向清晰易懂。雖然在兩個已深度耦合的元件間，mutate prop 或 `this.$parent` 偶爾能簡化 code，但更多時候它只是用「能理解狀態流向」的長期清晰，換取「少寫幾行」的短期方便——不要被誘惑。

```vue
<!-- Bad — Composition API：子元件直接改寫父層擁有的 reactive 物件 -->
<script setup>
const props = defineProps({ todo: { type: Object, required: true } })
function renameTodo() {
  props.todo.text = 'renamed by child'   // 子元件伸手改父層狀態
}
</script>
<template>
  <span>{{ todo.text }} <button @click="renameTodo">rename</button></span>
</template>
```

```vue
<!-- Good — Composition API：emit 出去，由父層擁有更新 -->
<script setup>
const props = defineProps({ todo: { type: Object, required: true } })
const emit = defineEmits(['update:todo'])
function renameTodo() {
  emit('update:todo', { ...props.todo, text: 'renamed by parent' })
}
</script>
<template>
  <span>{{ todo.text }} <button @click="renameTodo">rename</button></span>
</template>
```

```js
// Good — Options API：用 props + emits，不碰 this.$parent
app.component('TodoItem', {
  props: { todo: { type: Object, required: true } },
  emits: ['delete'],
  template: `<span>{{ todo.text }} <button @click="$emit('delete')">×</button></span>`
})
```
