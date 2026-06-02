# 完整使用說明（記憶庫結構與運作）

> 適合對象：想知道「記憶到底存在哪、每個檔是什麼、怎麼運作」的人。
> 快速上手看 `新手指南.md`；完整架構看 `DUAL-PLATFORM-GUIDE.md`；機制看 `TECHNICAL_GUIDE.md`。

## 這是什麼？

每次開新對話，AI 什麼都不記得。這套系統讓 **Claude Code / Codex** 跨對話記住你的偏好、決策、知識，
並透過反思越來越懂你。記憶分**兩層**：個人腦（跨專案共用）＋專案腦（每專案）。

```
沒有記憶系統：你 →「幫我做 X」→ AI（不知道你是誰）
有記憶系統：  你 →「幫我做 X」→ AI 讀記憶 → 知道你是誰、你的偏好、上次做到哪 → 更準
```

## 記憶存在哪裡

### 個人腦（`~/.ai-memory`，跨所有專案共用、永不進專案 git）
```
~/.ai-memory/
├── MEMORY.md                ← 個人索引（每次對話載入；頂部「環境限制」指令區）
├── feedback_user_style.md   ← 你的偏好（任務怎麼做）
├── persona.md               ← AI 的人設/語氣/定位（AI 怎麼當）
├── reflection.md            ← 反思日誌（自動累積）
├── doctrine.md              ← 已批准的永久行為準則
├── doctrine_candidates.md   ← 待審核準則候選
├── blocked-actions.json     ← 失效工具登記簿（hook 讀它硬擋）
├── knowledge/               ← 個人（跨專案）知識頁
├── conversations/           ← 個人/非專案對話（含 archive）
├── guides/                  ← 操作引用的指南（PATHS / _routing / _materialize-skill）
├── hooks/  cron/  memory-lint.*  project-templates/
```

### 專案腦（`<專案>/.claude/memory`，每專案、可隨專案 git 分享）
```
<專案>/.claude/memory/
├── MEMORY.md      ← 這個專案的索引
├── knowledge/     ← 這個專案的知識頁
└── conversations/ ← 這個專案的對話（含 archive）
```
另外 `init-project` 還建 `<專案>/{CLAUDE.md,AGENTS.md}`、`.claude/skills`、`.codex/config.toml`、`.agents/skills`。

## 知識頁格式（compiled-truth + timeline）
```markdown
---
name: <實體名稱>
type: reference | project
kind: tool | person | concept | project
layer: personal | project
first_seen / last_updated: YYYY-MM-DD
---
## Current State   ← 覆寫區：永遠是最新真相，先讀這裡
## How to Apply / ## Known Issues / ## Relations（[[其他實體]]）
## Timeline        ← 只追加；每行附 (source: 來源)
```
**先讀 Current State（現在的真相），需要歷史才翻 Timeline。** 記憶分 4 type：user / feedback / project / reference。

## 九個指令（速覽，詳細打 `/help`）

| 指令 | 做什麼 |
|------|--------|
| `/capture` | 存這次對話的訊號（自動分層；含 🎭 人設；工具失效登記硬擋）|
| `/ingest-sessions` | 回頭讀近期 Claude/Codex 會話記錄補抓漏記（浮水印+去重；每晚先跑）|
| `/dream` | 整合 + 反思 + 提煉準則候選 + 失敗回寫 + lint |
| `/harvest` | 重複 ≥2 次的工作流 → skill（透過官方 skill-creator）|
| `/review-doctrine` | 逐條批准 doctrine 候選 |
| `/status` | 唯讀健檢（兩層）|
| `/schedule-dream` | 建/列/刪每晚自動整理（OS 排程、單一）|
| `/reset` | 互動式清空（先備份、要確認）|
| `/help` | 所有指令 + 怎麼確認通關 |

## 運作迴路

```
對話 → /capture 存訊號（個人 vs 專案分層）
     → /dream 反思 → doctrine 候選 → /review-doctrine 批准 → doctrine.md（永久遵守）
     → /harvest 重複工作流 → skill（雙平台）
     → 壞工具 → blocked-actions.json + hook 硬擋
下次對話：入口檔自動載入個人 MEMORY+doctrine、再讀專案 MEMORY → 不丟魂
```

## 溢出保護（不會無限長大）
`/dream` 自動：對話 > 30 個檔 → 封存最舊；知識頁 > 200 行 → 封存最舊 Timeline（Current State 永不封存）；
doctrine > 80 條 → 合併語意重複。

## 常見問題
- **怎麼確認在運作？** `/status` 或 `/help`（每指令有「怎麼確認通關」）。
- **存了不想要的？** `/reset`（選層級+種類、先備份、要 `yes reset`）。
- **規矩誰決定？** 一定要你 `/review-doctrine` 批准才生效。
- **換電腦？** 複製 `~/.ai-memory`（個人腦）；專案腦跟著專案走。
- **資料外傳？** 不會，全部本機純文字檔。
