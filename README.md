# AI Memory System（雙平台 × 雙層自我進化記憶）

一套給 **Claude Code 與 Codex** 的持久記憶系統。讓 AI 在不同對話之間記住你的偏好、決策與知識，
透過反思越來越懂你，犯過的錯不再犯，重複的工作流自動封裝成技能。

A portable, self-evolving memory system for **Claude Code and Codex**.
Remembers across sessions, reflects to understand you better, hard-blocks known-broken tools, and
turns repeated workflows into skills.

---

## 核心理念

```
每次對話
  → /capture 把有價值的訊號存到「對的層」（個人 vs 專案）
  → /dream 反思 → 提煉行為準則候選 → 你 /review-doctrine 批准 → 永久遵守
  → /harvest 把重複 ≥2 次的工作流封裝成 skill（透過官方 skill-creator）
  → 壞掉的工具自動硬擋、改用替代
下次對話：自動載入記憶＋準則，不丟魂，越來越懂你
```

**變的不是模型權重，是「外腦」（memory + skill + doctrine）在迭代。核心是 audit + reflect + restore 閉環。**

## 兩個關鍵設計

- **雙層**：個人腦 `~/.ai-memory`（doctrine／偏好／反思，跨所有專案共用、**永不進專案 git**）＋
  每專案腦 `<專案>/.claude/memory`（這個專案的知識／對話）。
- **雙平台（一份來源、雙物化）**：Claude 與 Codex 用相同的 `SKILL.md` 格式，一份內容物化到兩邊路徑。
  入口 `~/.claude/CLAUDE.md`＋`~/.codex/AGENTS.md`；硬擋 hook 同時註冊到 Claude `settings.json` 與
  Codex `config.toml`。

> ⚠️ Codex 技能在 `.agents/skills/`（**不是** `.codex/skills/`）。

## 安裝（兩步）

```powershell
# 1) 每台電腦一次：在框架資料夾裡跑（建立個人腦 + 接上兩平台；會自動遷移舊的 ~/.claude/memory）
.\install-personal.ps1            # Windows
./install-personal.sh             # Mac/Linux

# 2) 每個新專案一次：進到那個專案資料夾再跑
cd C:\path\to\我的新專案
C:\path\to\ai-memory-system\init-project.ps1
```
裝完**重啟 Claude Code / Codex**。新手請看 [`新手指南.md`](新手指南.md)。

## 九個指令

| 指令 | 功能 |
|------|------|
| `/capture` | 把這次對話的訊號存進記憶（自動分層；含 🎭 人設；工具失效會登記硬擋）|
| `/ingest-sessions` | 回頭讀近期 Claude/Codex 會話記錄補抓漏記（per-source checkpoint、冪等；每晚先跑）|
| `/dream` | 多階段整合：實體掃描→修連結→去重→反思→失敗回寫→同步索引→lint |
| `/harvest` | 把重複 ≥2 次的工作流封裝成 skill（透過官方 **skill-creator**）|
| `/review-doctrine` | 逐條批准/修改/拒絕 doctrine 候選 |
| `/status` | 唯讀健檢（個人＋專案兩層）|
| `/schedule-dream` | 建立/列出/刪除每晚自動整理（OS 排程，單一具名、不亂堆）|
| `/reset` | 互動式記憶重置（選層級＋種類；先備份、要確認）|
| `/help` | 列出所有指令的功能、使用時機、**怎麼確認通關** |

> 在 Claude Code 打 `/指令`；在 Codex 用同名技能（講觸發語即可）。詳細打 `/help`。

## 文件

| 檔案 | 內容 |
|------|------|
| [新手指南.md](新手指南.md) | 👈 **先看這個**：白話快速上手 |
| [記憶名詞對照表.md](記憶名詞對照表.md) | 🔤 看不懂 conversations/doctrine/persona…？英文名詞中文白話對照（含例子）|
| [DUAL-PLATFORM-GUIDE.md](DUAL-PLATFORM-GUIDE.md) | 完整說明（架構／雙層／雙平台／驗證）|
| [生活化測試流程.md](生活化測試流程.md) | 親手走一遍、驗收每個機制（約 15 分鐘）|
| [TECHNICAL_GUIDE.md](TECHNICAL_GUIDE.md) | 機制技術詳解 |
| [MEMORY_GUIDE.md](MEMORY_GUIDE.md) | 完整使用說明 |
| [安裝行為說明.md](安裝行為說明.md) | 安裝器動到哪些檔案 |
| [CHANGELOG.md](CHANGELOG.md) / [ROADMAP.md](ROADMAP.md) | 變更歷程 / 延後工作 |

## 系統需求
- [Claude Code](https://claude.ai/code) 或 [Codex](https://developers.openai.com/codex)（VS Code）。
- 不需要資料庫、不需要 API Key。

## 誠實說明限制
- 記憶與準則多為**軟約束**（約 95% 靠 AI 遵守）；**例外是硬擋層**——登記在 `blocked-actions.json` 的
  工具由 PreToolUse hook 物理擋下。**在 registry 為有效 JSON 且 hook 已註冊時，這是硬保證**（重啟後生效）；
  hook 在解析失敗時採 fail-open（壞掉的 registry 不會癱掉所有工具），且 `doctor`/`/status` 會在安全網掉時**報紅**。
- **無向量搜尋**（關鍵字 + `MEMORY.md` 索引；規模大可選接 qmd，見 ROADMAP）。
- 建立技能一律透過官方 [skill-creator](https://github.com/anthropics/skills)；完整評測迴圈需 Python。

## License
MIT
