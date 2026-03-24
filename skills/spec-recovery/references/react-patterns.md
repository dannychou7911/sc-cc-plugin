# React 專案萃取模式

偵測到 React 專案時（package.json 含 `react`），載入此文件輔助分析。

---

## 前端分析順序

```
路由定義（react-router / Next.js pages / App Router）→ 頁面清單
→ 逐頁互動行為 → State 管理（Redux / Zustand / Context）
→ 表單與驗證 → 條件渲染規則 → API 呼叫層
```

---

## 萃取條件渲染規則

搜尋以下 JSX 模式：

```tsx
{condition && <Component />}
{condition ? <A /> : <B />}
className={clsx('base', { 'is-active': condition })}
style={{ display: condition ? 'block' : 'none' }}
disabled={condition}
```

---

## 萃取使用者操作

| React 語法 | 代表的操作類型 |
|------------|--------------|
| `onClick` | 按鈕點擊操作 |
| `onChange` | 輸入/選擇操作 |
| `onSubmit` | 表單送出 |
| `onKeyDown` / `onKeyUp` | 鍵盤操作 |
| `useEffect` 依賴篩選值 | 自動觸發的查詢 |

---

## 萃取表單驗證規則

### React Hook Form + Zod

```typescript
const schema = z.object({
  name: z.string().min(1, '必填').max(50),
  email: z.string().email('格式不正確'),
});

const { register, handleSubmit } = useForm({
  resolver: zodResolver(schema),
});
```

### Formik + Yup

```typescript
const validationSchema = Yup.object({
  name: Yup.string().required('必填').max(50),
  email: Yup.string().email('格式不正確').required('必填'),
});
```

---

## 萃取資料流

1. 從元件的 `useEffect([], ...)` 開始，追蹤初始載入
2. 追蹤 dispatch / action 的呼叫鏈
3. 追蹤 selector / derived state 的消費
4. 注意 React Query / SWR 的 cache key 和 invalidation 策略

---

## 萃取 Custom Hook 規格

搜尋 `use*.ts` / `use*.tsx` 檔案：

```typescript
export function useOrderActions(orderId: string) {
  const [loading, setLoading] = useState(false);
  const submit = useCallback(async () => { ... }, [orderId]);
  return { loading, submit };
}
```

記錄：名稱、參數、回傳值、使用位置。

---

## 萃取導航行為

```typescript
// react-router v6
const navigate = useNavigate();
navigate('/path');
navigate(-1);

// Next.js
const router = useRouter();
router.push('/path');
router.replace('/path');

// <Link> / <NavLink> 元件
<Link to="/path">...</Link>
```

---

## 萃取隱性規則（React 特有）

```typescript
// 模式：useEffect 的清理函式
useEffect(() => {
  const timer = setInterval(fetchData, 5000);
  return () => clearInterval(timer);
}, []);
// ⚠️ 有 5 秒 polling 機制

// 模式：依賴陣列陷阱
useEffect(() => {
  fetchData(filters);
}, [filters.status]); // 只監聽 status，不監聽其他 filter
// ⚠️ 部分 filter 變更不會觸發重新查詢

// 模式：memo 化暗示效能瓶頸
const expensiveList = useMemo(() =>
  items.filter(complexFilter).sort(complexSort),
  [items]
);
// ⚠️ 資料量大到需要 memo 化
```
