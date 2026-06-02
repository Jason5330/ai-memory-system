# 機制技術詳解（v2：雙平台 × 雙層 × contract-first）

> 適合對象：想深入了解系統如何運作的開發者。使用說明見 `新手指南.md` / `DUAL-PLATFORM-GUIDE.md`；
> 完整路徑規則見 `canonical/PATHS.md`。

## 一、架構總覽（contract-first）

所有東西在框架 `canonical/` 裡**寫一份來源**，由安裝器**物化**到各平台/各層。修一處、兩邊同步。

```
canonical/
  PATHS.md            路徑與分層的單一真相
  entry/              CLAUDE.md / AGENTS.md（個人 + 專案入口範本）
  operations/*.md     8 個操作（frontmatter 同時當 Codex SKILL.md；body 同時當 Claude 指令）
    _routing.md       訊號 → 層級 路由（capture/dream 共用）
    _materialize-skill.md  技能雙平台複製
  hooks/              block-failed-actions.{ps1,sh}（PreToolUse 硬擋）
  cron/ lint/ templates/
skills/skill-creator/ 官方 Anthropic skill-creator（安裝器部署到兩平台）
install-personal.*    每台機器一次
init-project.*        每個專案一次
```

## 二、兩層（個人 ⊥ 專案）

| 層 | 位置 | 內容 | 共用 | 進專案 git |
|----|------|------|------|-----------|
| 個人 | `~/.ai-memory` | doctrine、偏好、反思、壞工具登記、個人知識/技能 | ✅ 跨所有專案 | ❌ 永不 |
| 專案 | `<專案>/.claude/memory` | 這個專案的知識/對話/索引 | ❌ 每專案 | 可（個人層不混入）|

訊號分層由 `_routing.md` 決定：「關於我/行為/壞工具/反思」→ 個人；「關於這個專案」→ 專案；沒專案 → 全進個人。

## 三、兩平台（一份來源、雙物化）

Claude 與 Codex 用**相同 `SKILL.md` 格式**。物化目標：

| 東西 | Claude | Codex |
|------|--------|-------|
| 入口 | `~/.claude/CLAUDE.md`、`<專案>/CLAUDE.md` | `~/.codex/AGENTS.md`、`<專案>/AGENTS.md` |
| 操作 | `~/.claude/commands/<op>.md` | `~/.agents/skills/<op>/SKILL.md` |
| 技能 | `~/.claude/skills`、`<專案>/.claude/skills` | `~/.agents/skills`、`<專案>/.agents/skills` |
| 硬擋註冊 | `~/.claude/settings.json` | `~/.codex/config.toml` |

> Codex 技能在 `.agents/skills/`（非 `.codex/skills/`，已查證官方文件）。

## 四、九個操作的機制

- **capture**：掃對話訊號（決策/知識/偏好/🎭人設/進行中/問題解法/技能失敗/工具失效）→ 知識篩選閘門
  （本次產物不存）→ 依 `_routing.md` 分層寫入（人設→`persona.md`、偏好→`feedback_user_style.md`）→
  工具失效走 Step 2.5 三層強制 → 重複 ≥2 次的工作流提議 /harvest。知識頁強制 Why + How to Apply。
- **ingest-sessions**：回頭讀近期 Claude(`~/.claude/projects/*.jsonl`)/Codex(`~/.codex/`) 會話 + 未整合
  log，抽訊號補沉澱；**浮水印 + 去重**故可重放；Chronicle 僅線索。nightly 會先跑它再 dream。
- **dream**：實體掃描 → 修雙向連結 → 去重/矛盾 → 反思寫 `reflection.md` → 跨 ≥2 次反思提煉 doctrine
  候選 → 技能失敗回寫 SKILL.md 的 `Known Limitations & Fallbacks`（並 re-materialize 到 Codex twin）→
  同步 MEMORY.md → 跑 memory-lint。
- **harvest**：蒐證（對照現有技能去重）→ 候選清單（證據/次數/信心/形式）→ 逐條人審 →
  **透過官方 skill-creator** author SKILL.md（完整 eval/benchmark 選用）→ `_materialize-skill.md` 雙物化。
- **review-doctrine**：逐條 ✅✏️❌⏭️ → 批准寫 `doctrine.md`（`### D-XXX`）；入口檔只指向 doctrine，永不膨脹。
- **status**：唯讀雙層儀表板；偵測平台技能是否同步。
- **schedule-dream**：OS 排程器（Task Scheduler / cron）建立/列出/刪除**單一具名排程**（建立=取代，
  不亂堆）；agent 代跑指令。
- **reset**：互動式選層級+種類 → **先備份到 archive/reset-時間戳 → 要 `yes reset` 才清**，絕不刪唯一副本。
- **help**：逐指令的功能/時機/怎麼確認通關 + 整體健康總檢。

## 五、硬擋層（兩平台 100% 技術保證）

`block-failed-actions.{ps1,sh}` 讀 `~/.ai-memory/blocked-actions.json`，命中即 `exit 2` + stderr（Claude
與 Codex 都支援）。以 **catch-all matcher** 註冊（Claude `*` / Codex `.*`），由登記簿 gate——**加一條
登記即可，不必改 matcher**；條目含 `platform` 欄位。重啟後生效。資料驅動：封鎖新工具不必改程式。

## 六、反思進化迴路（越來越懂你）

```
capture → conversations/*.md
  → dream 反思寫 reflection.md → 跨 ≥2 次模式 → doctrine 候選
  → review-doctrine 批准 → doctrine.md
  → 下次對話入口檔載入 doctrine → 行為自動調整、不再犯同樣錯
```
**變的是「外腦」（memory + skill + doctrine），不是模型權重。**

## 七、確定性健檢（doctor）

`memory-lint.{ps1,sh}`（即 doctor）可帶多個 root，檢查：MEMORY 連結/**死連結**、knowledge frontmatter
（name/type/kind/**layer**/first_seen/last_updated）、**Why（Summary）+ How to Apply 是否齊全**、
Timeline 是否附 source、kebab 檔名、doctrine D-XXX 唯一、**未整合的舊 log（>7 天）**、專案層**隱私洩漏**
啟發式；以及**全域接線**：blocked-actions schema、**hook 是否註冊（Claude settings.json / Codex
config.toml）+ hook self-test**、skill-creator 兩平台、**升格 skill 雙平台是否同步**。輸出
`RESULT: X pass, Y warn, Z fail`，**fail>0 = 安全網可能掉了**。dream 末會自動跑。
預設 exit 0（報告用）；**加 `-Strict`/`--strict` 變 CI gate**：fail>0 → exit 1（擋得住壞狀態，符合 Harness）。

## 八、夜間排程加固（nightly）

`nightly.{ps1,sh}` 不只把 prompt 丟給 `claude -p`/`codex exec`，還有：**單一 `memory.lock`**（防並發 dream
弄壞記憶；逾 6 小時自動清陳舊鎖）、**run-id**、每階段 **JSON audit**（`~/.ai-memory/cron/audit.jsonl`）、
**`--dry-run`**（只報告不寫）。流程是 **ingest-sessions → dream → harvest 掃描**，只產候選、不自動批准/建技能。
（註：實際 .md 寫檔在 agent 端，逐檔 atomic 由操作負責，wrapper 只保證序列化 + 可審計。）

## 九、技術限制（誠實說明）

| 限制 | 說明 |
|------|------|
| 無向量搜尋 | 關鍵字 + MEMORY.md 索引；規模大可選接 qmd（見 ROADMAP）|
| 依賴 AI 判斷 | 記憶/準則約 95% 軟約束；**例外**：blocked-actions hook 為 100%（重啟後生效）|
| 無背景程序 | 整合在對話中或 OS 排程的 headless 執行；不開 IDE 的自動跑需 `claude`/`codex` CLI |
| 技能評測依賴 | skill-creator 完整 eval/benchmark 需 Python + subagents（Codex 走輕量 author）|
