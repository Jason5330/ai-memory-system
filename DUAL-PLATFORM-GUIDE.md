# 雙平台 × 雙層自我進化記憶框架（v2 指南）

> 這套框架的權威說明（雙平台 × 雙層）。**安裝用 `install-personal` + `init-project`**（見下）。
> 快速上手看 [`新手指南.md`](新手指南.md)，機制看 [`TECHNICAL_GUIDE.md`](TECHNICAL_GUIDE.md)。

## 它解決什麼

讓你每天用 **Claude Code 或 Codex**（VS Code）對話時，有價值的經驗自動沉澱成記憶、犯過的錯不再犯、
重複的工作流可被封裝成技能——而且**越來越懂你**。分享給朋友也適用：每人各自有自己的「個人腦」。

三套引擎（沿用並升級 v1）：
1. **反思層** — `/dream` 寫 `reflection.md` → 跨 2 次模式 → doctrine 候選 →（人審）→ `doctrine.md`。
2. **記憶沉澱** — 按 type 分桶、kebab-case、Why/How、`MEMORY.md` 索引每次注入。
3. **技能自更新** — `/harvest` 把重複工作流封裝成 `SKILL.md`；`/dream` 把失敗回寫「Known Limitations & Fallbacks」。

核心：**audit + reflect + restore 閉環，重啟不丟魂。變的不是模型權重，是「外腦」（memory + skill + doctrine）。**

## 兩個關鍵設計（v2 新增）

### 雙層（個人 ⊥ 專案）
- **個人層** `~/.ai-memory/`：doctrine、偏好、跨專案反思、壞工具登記、個人知識/技能。**所有專案共享**、
  **永不進任何專案 git**。這是「越來越懂你」的所在。
- **專案層** `<專案>/.claude/memory/`：這個專案的知識、決策、對話。可隨專案 git 分享；個人層不混入。

### 雙平台（一份來源、雙物化）
Claude Code 與 Codex 用**相同的 `SKILL.md` 格式**，所以一份內容物化到兩邊路徑即可。

| 東西 | Claude 讀 | Codex 讀 |
|---|---|---|
| 個人入口 | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| 專案入口 | `<專案>/CLAUDE.md` | `<專案>/AGENTS.md` |
| 操作 | `~/.claude/commands/<op>.md` | `~/.agents/skills/<op>/SKILL.md` |
| 個人技能 | `~/.claude/skills/` | `~/.agents/skills/` |
| 專案技能 | `<專案>/.claude/skills/` | `<專案>/.agents/skills/` |
| 硬擋 hook 註冊 | `~/.claude/settings.json` | `~/.codex/config.toml` |

> ⚠️ **重要**：Codex 的技能在 `.agents/skills/`，**不是** `.codex/skills/`。`.codex/` 只放
> `config.toml`/`hooks.json`。（已查證 developers.openai.com/codex/skills，2026-06。）

## 安裝（兩步）

### 1) 個人層（每台機器一次）
在框架資料夾裡跑：
```powershell
.\install-personal.ps1      # Windows
```
```bash
./install-personal.sh        # Mac/Linux
```
做了什麼：建 `~/.ai-memory/`（並把既有 `~/.claude/memory/*` **遷移**進來，copy-if-missing、不刪原檔）、
物化入口/操作/個人技能/hook/cron 到 Claude + Codex + `~/.agents/skills`、註冊兩平台的 PreToolUse 硬擋
（catch-all matcher，由登記簿 gate）。**冪等**，升級重跑即可。

### 2) 每個專案（用前先建專案，再初始化）
在新專案資料夾裡跑：
```powershell
.\init-project.ps1           # Windows（或傳路徑）
```
```bash
./init-project.sh            # Mac/Linux
```
建：`CLAUDE.md`、`AGENTS.md`、`.claude/memory/`、`.claude/skills/`、`.codex/config.toml`、`.agents/skills/`，
並在 `.gitignore` 加防外洩守則。冪等。

之後**重啟 Claude Code / Codex** 生效。

## 五個操作（Claude 打 `/op`；Codex 用同名技能、講觸發語）

| 操作 | 功能 |
|---|---|
| `capture` | 把這次對話的訊號存到「對的層」（個人 vs 專案）；含 🎭 人設→`persona.md`、短決策回溯 |
| `ingest-sessions` | 回頭讀近期 Claude/Codex 會話記錄補抓漏記的訊號（浮水印+去重，nightly 會先跑它） |
| `dream` | 多階段整合：實體掃描→修連結→去重→反思→失敗回寫→同步索引→**doctor 健檢** |
| `harvest` | 掃歷史找重複工作流 → 證據候選清單 → 人審 → 只建高信心缺失項，雙物化 |
| `review-doctrine` | 逐條批准/修改/拒絕 doctrine 候選 |
| `status` | 唯讀健檢（個人 + 專案兩層） |
| `reset` | 互動式記憶重置：執行時選層級（個人/專案/兩者）+ 種類（對話/反思/知識/準則/偏好）；**一律先備份到 archive、要打 `yes reset` 才動手**，絕不刪唯一副本 |
| `help` | 列出所有指令的功能、使用時機、**怎麼確認通關**（逐指令驗證 + 整體健康檢查）；忘記怎麼用就打它 |

每晚自動：對 `/schedule-dream` 說「排程 / 列出排程 / 刪除排程」即可——它用 OS 排程器（Windows 工作排程 /
cron）維護**單一具名排程 `ai-memory-nightly`**（建立 = 取代，**不會越堆越多**），headless 跑
dream + harvest-scan，留候選給你隔天人審。agent 會幫你跑指令，你不必記 cron 語法。

> 重複工作流：門檻是**出現 ≥2 次（同一天也算，不必跨 3 天）**；偵測到就主動提議跑 `/harvest`。
> 但**一直失敗的內建工具不是 skill**——那是工具失效，會走硬擋（`blocked-actions.json` + hook）擋掉、
> 改用替代工具，而不是做成技能。
>
> 建立技能**一律透過官方 skill-creator**（github.com/anthropics/skills）：安裝器把它部署到
> `~/.claude/skills/skill-creator` 與 `~/.agents/skills/skill-creator`，`/harvest` 調用它來 author
> SKILL.md（要嚴謹可再跑它的 eval/benchmark 迴圈），再雙物化到兩平台。

## 訊號分層路由（capture/dream 自動判斷）
- 「關於**我**怎麼工作 / 行為準則 / 壞工具 / 跨專案反思」→ **個人層**。
- 「關於**這個專案**的知識/決策/對話」→ **專案層**。
- 沒在專案裡 → 全進個人層，照常運作。

## 硬擋層（兩平台都 100% 技術保證）
`capture` 偵測到內建工具在此環境壞掉 → 寫進 `~/.ai-memory/blocked-actions.json`。PreToolUse hook 在
Claude（`settings.json`）與 Codex（`config.toml`）都以 **catch-all matcher** 註冊、由登記簿 gate，
命中即 `exit 2`/`deny` 物理擋下並提示替代工具。**加一條登記即可，不必改 matcher**；重啟後生效。
登記簿是 machine-specific，分享框架時是空的，不會誤傷朋友。

## 誠實說明限制（平台差異）
- **記憶/準則仍多為軟約束**（~95% 靠 agent 遵守）；**例外是硬擋層**，兩平台皆 100%（重啟後生效）。
- **無向量搜尋**：關鍵字 + `MEMORY.md` 索引（規模上百頁後可選接 qmd，見 v1 ROADMAP）。
- **Codex 技能路徑**是 `.agents/skills/`（非 `.codex/skills/`）——這是 Codex 的真實約定。
- **每晚 cron** 走 OS 排程（非某 agent 內建排程），需 `claude` 或 `codex` CLI 在 PATH。
- **個人腦在 `~/.ai-memory`**（平台中立）；只用 Codex 的朋友也不需要 `~/.claude/`。

## 與三套理念的對應
- Harness（repo 即真相、入口檔當路由、外部化驗證、乾淨狀態、診斷迴路）。
- GBrain（dream cycle、實體頁 compiled-truth+timeline、friction 回寫、contract-first 一份來源多面、
  brain⊥source 兩軸＝這裡的個人⊥專案、fail-closed 信任邊界＝硬擋層）。
- LLM Wiki（markdown 即真相、index+log、LLM 做簿記、探索成果歸檔回 wiki＝harvest 把工作流封裝回技能）。
