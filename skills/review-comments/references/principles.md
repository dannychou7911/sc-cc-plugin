# 程式註解聖經：8 大核心原則

> 好的程式碼自己會說話，但好的註解能賦予它靈魂。
> 關鍵在於：**不要解釋「做什麼（What）」，而是解釋「為什麼（Why）」與「脈絡（Context）」。**

---

## 原則一：解釋「為什麼」，而不是「做什麼」

不要重複程式碼本身就能表達的直覺行為。註解應用來解釋背後的商業邏輯或不直覺的決策。

❌ 糟糕：
```javascript
// 檢查使用者年齡是否大於 18 歲
if (user.age > 18) {
  grantAccess(user);  // 允許進入系統
}
```

✅ 良好：
```javascript
// 根據 2026 年最新個資法與合規性要求，未滿 18 歲之用戶必須阻擋其進入敏感資料專區
if (user.age > 18) {
  grantAccess(user);
}
```

---

## 原則二：解釋「魔法數字」與「特殊黑科技（Hacks）」

在維護老舊系統、解決特定平台 Bug 或處理外部 API 對接時，常不得不寫出看起來很瞎但其實是為了解決問題的程式碼（Workaround）。這時候註解是後人的救命稻草。

❌ 糟糕：
```javascript
setTimeout(() => {
  fetchData();
}, 300); // 延遲 300 毫秒
```

✅ 良好：
```javascript
// 這裡必須刻意延遲 300ms，是為了等待舊版第三方套件（Legacy Widget）在 DOM 初始化完成。
// 若直接呼叫會觸發 Race Condition 導致畫面崩潰。詳見系統追蹤 Issue #1422。
setTimeout(() => {
  fetchData();
}, 300);
```

---

## 原則三：提防陷阱（Caveats）與效能考量

如果某段程式碼有潛在的副作用（Side Effect），或因特殊考量而刻意不用常見做法，一定要寫出來，防止未來工程師自以為聰明去重構，結果踩到地雷。

✅ 良好：
```python
def process_large_log_file(file_path):
    # 注意：這裡必須使用 generator 逐行讀取，而非使用方便的 readlines()。
    # 因為生產環境的日誌檔通常大於 10GB，直接一次性載入記憶體會導致 OOM 崩潰。
    with open(file_path, 'r') as file:
        for line in file:
            yield parse_line(line)
```

---

## 原則四：善用標準標籤（TODO / FIXME）並建立追蹤機制

良好的註解具備「可搜尋性」。使用國際標準標籤，並附上工作看板編號。

- **`TODO:`** 預計要做的功能、待優化的效能或結構。
- **`FIXME:`** 已知有問題、暫時用髒辦法解決，必須回頭修正的地方。

❌ 糟糕：
```javascript
// TODO: fix this later
return data;
```

✅ 良好：
```java
public double calculateTax(Order order) {
    // FIXME: 這裡暫時寫死 5% 營業稅以利趕上週五上線。等 PM 確認跨國稅率邏輯後需立刻修正。 (Jira-1082)
    // TODO: 考慮將此邏輯抽離至獨立的策略模式（Strategy Pattern）類別中以利未來擴充。
    return order.getTotalPrice() * 0.05;
}
```

---

## 原則五：公共介面（Public API）必須說明「合約與邊界」

當函式或類別要當作模組給團隊其他人或未來的自己呼叫時，JSDoc / JavaDoc / Docstring 就是官方使用說明書。必須涵蓋：輸入（型別與限制）、輸出、例外情況（Edge Cases）。

✅ 良好：
```typescript
/**
 * 根據使用者 ID 與優惠券代碼計算折扣後的最終金額。
 *
 * @param userId - 8 位數的用戶唯一識別碼（UUID）
 * @param couponCode - 優惠券代碼，若無優惠券則傳入 null 或空字串
 * @returns 回傳折扣後的總金額，最低金額保底為 0 元
 *
 * @throws {UserNotFoundError} 當資料庫找不到該 userId 時拋出
 * @throws {CouponExpiredError} 當優惠券已過期時拋出
 *
 * @example
 * const price = calculateFinalPrice("usr_12345", "SUMMER50");
 */
export function calculateFinalPrice(userId: string, couponCode: string | null): number {
  // ...
}
```

---

## 原則六：記錄「未採納的方案」（Why Not）

優秀的註解不僅記錄了「我們做了什麼」，更記錄了「我們嘗試過什麼但失敗了」。這能阻止後來的工程師重蹈覆轍。

✅ 良好：
```go
func SyncUserData(userId string) {
    // 【注意】這裡刻意不使用 Redis 分散式鎖，而是直接在資料庫層級使用 SELECT FOR UPDATE。
    //
    // 歷史教訓：
    // 2025/11/12 曾嘗試引入 Redis 鎖來提升併發效能，但在高併發網路波動時，
    // Redis 與 DB 的狀態可能不一，導致用戶餘額計算錯誤（詳見 Post-Mortem #88）。
    // 目前 DB 效能仍在可接受範圍內，除非大幅改動架構，否則請勿輕易改回 Redis 鎖。
    tx := db.Begin()
    // ...
}
```

---

## 原則七：連結外部脈絡（產品需求、法規、第三方 API）

程式碼往往受到 PRD、第三方 API 規格書、甚至政府法規的限制。與其在程式碼裡寫長篇大論，不如直接附上延伸閱讀的連結。

✅ 良好：
```python
def check_invoice_eligibility(amount):
    # 針對特定免稅商品與海外代購之二聯式發票，其課稅別計算邏輯有所不同。
    # 詳細規則與邊界條件請參考：
    # 1. 財政部公告：https://einvoice.nat.gov.tw/example-link
    # 2. 團隊 Confluence 文件：https://confluence.company.com/pages/viewpage.action?pageId=987654
    if amount <= 0:
        return False
```

---

## 原則八：保持註解的「新鮮度」（與程式碼同步更新）

「過期的錯誤註解，比沒有註解更可怕。」因為它會直接誤導開發者，引導去錯誤的方向修 Bug。

❌ 糟糕（程式碼改了，註解忘了更新）：
```javascript
// 取得使用者購物車總金額（注意：此金額已經包含 60 元基本運費）
function getCartTotal(items) {
  // 兩年前修了 Bug，運費改由路由層獨立計算，這裡其實只算商品總價
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

✅ 良好：
```javascript
// 取得購物車內所有商品的純商品總價（不含運費、亦不包含任何優惠折抵）。
function getCartTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

---

## 終極心法：能用程式碼自釋，就不要寫註解

「最好的註解，就是想辦法用『重構程式碼』來取代註解。」

在動手寫註解前，先思考能否透過：
- 把變數名稱改得更精準
- 把大函式拆成有意義的小函式

讓程式碼本身解釋意圖。

- **低階作法**：寫了一段複雜的巢狀 `if-else`，然後在上面寫 10 行中文註解解釋流程。
- **高階作法**：把這段 `if-else` 抽成 `isUserEligibleForFreeShipping(user, cart)`。連一行註解都不用寫。

**註解不是用來掩蓋爛程式碼的化妝品，而是用來傳遞程式碼本身無法表達的意圖與歷史故事。**
