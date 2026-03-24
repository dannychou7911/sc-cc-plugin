# sc-plugin

團隊共享的 Claude Code plugin 工具集，收錄經過實戰驗證的 skills 與 agents，提升日常開發效率。

## 包含元件

| 類型 | 名稱 | 說明 |
|------|------|------|
| Skill | `spec-recovery` | 從既有程式碼回推 L0-L4 規格文件 |
| Agent | `spec-scorer` | 規格文件品質評分，獨立審閱避免 confirmation bias |
| Skill | `strategic-compact` | 在邏輯斷點建議 context compaction，避免 auto-compaction 在不恰當的時機觸發 |

## 安裝方式

### 本地測試

```bash
claude --plugin-dir /path/to/sc-plugin
```

### 驗證安裝

啟動 Claude Code 後：

- 執行 `/help`，確認看到 `/sc-plugin:spec-recovery` 和 `/sc-plugin:strategic-compact`
- 執行 `/agents`，確認看到 `spec-scorer` agent

## 使用範例

```bash
# 回推專案規格
/sc-plugin:spec-recovery

# 回推單一模組
/sc-plugin:spec-recovery src/modules/auth
```

## 需求

- Claude Code >= 1.0.33
