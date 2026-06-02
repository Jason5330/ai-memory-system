---
name: help
description: List every memory-system command with a detailed explanation of what it does, WHEN to use it, and HOW to confirm it actually worked. Use when the user says "help", "/help", "有哪些指令", "怎麼用", "說明", "這個指令幹嘛", or seems unsure which command to run.
---

# help — All Commands, When to Use Them, How to Confirm Success

Print this guide in the user's language. For each command give three things: **功能（what）**,
**使用時機（when）**, **怎麼確認通關（how to verify it worked）**. Roots:
`PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if you're inside an initialized project).

## 一眼看懂（quick map）

| 指令 | 一句話 | 何時用 |
|------|--------|--------|
| `/capture` | 把這次對話的重點存進記憶 | 聊到值得記的東西、或某工具壞了 |
| `/ingest-sessions` | 回頭把最近 Claude/Codex 會話沒記到的補抓進來 | 怕漏記、或交給每晚自動 |
| `/dream` | 大整理 + 反思 + 提煉準則候選 | 累積幾天對話後（或每晚自動） |
| `/harvest` | 把重複的工作流封裝成 skill | 同一流程做過 ≥2 次 |
| `/review-doctrine` | 逐條批准 Claude 提的行為準則 | `/dream` 說有候選時 |
| `/status` | 唯讀健檢看現況 | 想知道記了多少、進度如何 |
| `/schedule-dream` | 建立/列出/刪除每晚自動整理 | 設一次；或要列/刪排程時 |
| `/reset` | 互動式清空記憶、重新開始 | 存了一堆不想要的記憶 |
| `/help` | 你正在看的這份 | 忘記哪個指令、想確認怎麼驗證 |

---

## 自動記，還是要打 `/capture`？

記憶分三層，從「自動」到「保證」，**你不一定要打 `/capture`**：
- **① 聊天中自動**（免動手）：AI 每輪用 Memory Decision Gate 判信心——**高→當場記**（偏好／人設／知識／壞工具）、**中→存候選**、**低→跳過**。屬「盡力而為」。
- **② `/capture`**（手動保證）：完整掃這段對話、確定一定存進去。重要的就打它。
- **③ 每晚 `/ingest-sessions`**（確定性兜底）：回讀真實會話記錄，把①漏掉的補回來（`/schedule-dream` 設一次即每晚自動跑）。

> **兩條鐵則**：**行為準則／技能永不自動生效**（要 `/review-doctrine`、`/harvest` 批准）；**低信心一律跳過**。

---

## 記憶分類速查（這些英文是什麼）

> 完整版＋例子看框架 repo 的 `記憶名詞對照表.md`。記憶分**兩層**（個人腦 `~/.ai-memory` ⊥ 專案腦
> `<專案>/.claude/memory`）、**四型**（user/feedback/project/reference）。各分類白話：

| 英文 | 中文 | 一句白話 |
|------|------|----------|
| conversations | 對話紀錄 | 每天聊了什麼的流水帳 |
| knowledge | 知識頁 | 可重用的事實/工具用法/人事物（當前狀態＋時間軸） |
| reflection | 反思日誌 | AI 檢討做對/做錯/下次怎麼改 |
| doctrine | 行為準則 | 你批准過、以後一定遵守的規則 |
| doctrine_candidates | 準則候選 | 還沒批准、等你審的提議 |
| feedback_user_style | 偏好 | 你喜歡「任務怎麼做」 |
| persona | 人設 | AI「該怎麼當」（語氣/稱呼/定位） |
| blocked-actions | 壞工具登記 | 哪個工具壞了要硬擋、改用替代 |
| skills | 技能 | 重複工作流封裝成一鍵手冊 |

> 偏好 vs 人設：偏好＝任務怎麼做；人設＝AI 怎麼當。反思 → 準則候選 →（你批准）→ 準則。

---

## 逐指令詳解

### `/capture`
- **功能**：掃描目前對話，把 7 類訊號（決策/知識/偏好/進行中/問題解法/技能失敗/工具失效）存到**對的層**
  （關於你/行為→個人層；關於這個專案→專案層）。會過「知識篩選閘門」（本次產物不當知識存）。
- **聰明記決策**：就算你只回一句「**好 / OK / 就用這個**」，它會**回溯前 3-5 輪**還原你到底拍板了什麼，
  存下決策的**實質**（選了哪個、為什麼、否決了什麼），而不是只存「好」——短但關鍵的決策不會漏。
- **使用時機**：剛聊完一段重要的東西、做了決定、解了問題、講了偏好，想確保不忘 → 打它。發現某個內建
  工具在你環境壞掉（如搜尋一直失敗）也要打它（它會把工具登記起來硬擋）。
- **✅ 怎麼確認通關**：
  - 看它回的報告（寫了哪一層、幾個訊號、建/更新幾個知識頁）。
  - `PROJECT 或 PERSONAL/conversations/今天.md` 應該有今天的紀錄；`MEMORY.md` 索引有更新。
  - 若是**工具失效**：`~/.ai-memory/blocked-actions.json` 應出現該工具一條，且 `~/.ai-memory/MEMORY.md`
    頂部「Environment Limits」段有對應指令。**重啟後**該工具再被呼叫會被擋下。
- **🎭 人設**：你說「以後叫我老闆／講話直接點」這種「AI 該怎麼當」的話 → 存進 `persona.md`（個人層、每次載入），跟「任務偏好」分開。

### `/ingest-sessions`
- **功能**：不靠「當下記得捕捉」，而是**回頭讀最近的 Claude/Codex 會話記錄**（`~/.claude/projects/*.jsonl`、
  `~/.codex/` 的會話檔）＋框架還沒整合的對話 log，把漏掉的訊號補抓進記憶。用 **per-source checkpoint
  （每個來源各記 offset/hash/ts）+ 去重**，所以檔案延遲落盤、被重寫、跨專案時間亂序都不會漏抓或重複。
- **使用時機**：怕某天忘了打 `/capture` 漏記；或**交給每晚自動**（nightly 會先跑它再 dream）。Chronicle 只當線索、要回源頭核實。
- **✅ 怎麼確認通關**：報告列「掃了幾個 session、新建/合併幾筆、幾個來源因無變動跳過」；`~/.ai-memory/cron/ingest-checkpoints.json` 有更新。

### `/dream`
- **功能**：多階段深度整合——實體掃描→修雙向連結→去重/矛盾→**反思寫 reflection.md**→把跨 ≥2 次反思的
  模式提煉成 **doctrine 候選**→技能失敗回寫→同步索引→跑 lint。
- **使用時機**：累積幾天對話後（例如一週一次或睡前），或交給 `/schedule-dream` 每晚自動。
- **✅ 怎麼確認通關**：
  - 報告會列各階段數字；`~/.ai-memory/reflection.md` 多了一則今天的反思。
  - 若有模式，`doctrine_candidates.md` 出現「⏳ pending review」候選，並提示你跑 `/review-doctrine`。
  - 報告末附 `RESULT: X pass, Y warn, Z fail`（memory-lint）——**Z=0（無 fail）才算乾淨通關**。

### `/harvest`
- **功能**：掃歷史找**重複的手動工作流**，產「候選清單」（證據/日期/次數/信心/建議形式），逐條人審後
  **只建高信心、現有沒覆蓋的**。建立技能**一律透過官方 skill-creator** 調用 author，再同時物化到 Claude
  與 Codex。
- **使用時機**：某個流程你重複做過 **≥2 次**（同一天也算）。注意：**一直失敗的內建工具不是工作流**，
  那要走 `/capture` 的硬擋，不是 harvest。
- **輕量 vs 嚴謹**：預設走 skill-creator 的**輕量 author**（直接寫好 SKILL.md，最快）。想要嚴謹可請它
  再跑 **eval/benchmark 迴圈**（測試用例 + 評分 + 比對），但那需要 Python，且 Codex 端建議只用輕量。
  跟它說「嚴謹一點 / 跑評測」就會啟用。
- **✅ 怎麼確認通關**：
  - 先看到候選清單（不會直接建）；你點頭的項目，最後報告列在「Created/extended」。
  - 升格的 skill 應**同時**出現在 `.claude/skills/<名>/SKILL.md` 與 `.agents/skills/<名>/SKILL.md`
    （兩邊內容一致）；下次對話該 skill 可自動觸發。

### `/review-doctrine`
- **功能**：把 `/dream` 提的準則候選**逐條**給你 ✅批准 / ✏️改 / ❌拒 / ⏭️略過；批准的寫進 `doctrine.md`。
- **使用時機**：`/dream` 跑完看到「有 X 條候選等審核」時。
- **✅ 怎麼確認通關**：批准的條目在 `~/.ai-memory/doctrine.md` 以 `### D-XXX` 出現；
  `doctrine_candidates.md` 該條狀態變 `✅ approved`。下次對話啟動就會遵守（兩平台共用同一份 doctrine）。

### `/status`
- **功能**：唯讀儀表板——兩層各自的對話數/知識數/技能數、已批准 doctrine、待審候選、反思則數、
  壞工具數、重複工作流候選、平台技能是否同步。
- **使用時機**：想知道現況、或當作「整體健康確認」工具，隨時可打（不會改任何東西）。
- **✅ 怎麼確認通關**：它**本身就是驗證工具**——能印出完整儀表板即正常；若顯示「平台技能不同步」或
  連結壞掉，照它的建議跑對應指令修。

### `/schedule-dream`
- **功能**：用 **OS 排程器**（Windows 工作排程 / cron）建立/列出/刪除每晚自動 `/dream`+`/harvest-scan`。
  只維護**單一具名排程**（建立=取代，不會越堆越多）。對它說「排程／列出排程／刪除排程」即可，agent 代跑。
- **使用時機**：想讓它每晚自己整理（設一次）；或懷疑排程重複/想停用時（列出、刪除）。
- **✅ 怎麼確認通關**：
  - 建立後對它說「列出排程」→ 應只看到一個 `ai-memory-nightly`。
  - 第一次跑過後，`~/.ai-memory/nightly-last-run.md` 會有當次摘要。
  - （v1 用 Claude 內建 cron 者注意：`CronList` 在 Claude Code CLI 可能不顯示，要去 **VS Code 擴充**看。）

### `/reset`
- **功能**：互動式清空記憶。執行時讓你選**層級**（個人/專案/兩者）+ **種類**（對話/反思/知識/準則/偏好）；
  **一律先備份到 archive、要打 `yes reset` 才動手**，絕不刪唯一副本。`blocked-actions.json` 預設保留。
- **使用時機**：多次 `/capture` 後存了一堆不想要的記憶、想重新開始時。
- **✅ 怎麼確認通關**：報告會給**備份路徑** `archive/reset-時間戳/`（去確認檔案都在裡面）；被清的項目
  變回空/範本狀態。要復原＝把備份檔複製回去。清完**重啟** Claude Code/Codex 讓新索引載入。

### `/help`
- **功能**：你正在看的這份——列出所有指令的功能、使用時機、怎麼確認通關。
- **使用時機**：忘記有哪些指令、不確定該用哪個、想知道怎麼驗證時。

---

## 整體確認「裝好了 / 在運作」（通關總檢）

1. **裝好了嗎**：個人層 `~/.ai-memory/`、入口 `~/.claude/CLAUDE.md` + `~/.codex/AGENTS.md`、
   操作（`~/.claude/commands/` + `~/.agents/skills/`）、hook（`settings.json` / `config.toml`）都在。
2. **健康嗎**：跑 `/status` 看儀表板（含「硬擋健康」——登記簿壞掉或 hook 沒註冊會報紅）；跑 doctor
   `memory-lint`（`~/.ai-memory/memory-lint.ps1` 或 `.sh`）——它現在會檢：連結/死連結、Why+How+source+
   layer、blocked-actions schema、**hook 是否註冊 + self-test**、skill 雙平台是否同步、未整合的舊 log。
   看 `RESULT: X pass, Y warn, Z fail`，**Z（fail）=0** 才算乾淨；fail>0 代表安全網可能掉了，要先修。
   **自動化/CI 或分享給朋友把關**：加 `-Strict`（Win）/`--strict`（Mac/Linux）→ fail>0 時回 **exit 1**（變成擋得住的 gate，不只是報告）。可帶
   專案路徑同時檢兩層）→ 看 `RESULT: X pass, Y warn, Z fail`，**Z=0** 為通關。
3. **在進化嗎**：`reflection.md` 有累積、`doctrine.md` 有你批准的準則、`.claude/skills`＋`.agents/skills`
   有升格技能、壞工具被擋——這四個有動，就代表「外腦」真的在迭代。

## Rules
- 用使用者的語言輸出；簡潔、條列。
- 路徑依層級解析（個人 `~/.ai-memory`、專案 `./.claude/memory`）。
- 只是說明，不修改任何檔案。
