# Changelog — Claude Memory System

本檔記錄框架的修改歷程：每次改了什麼、為什麼改、改在哪裡。

---

## 2026-06-03 — install-personal：Claude settings.json 被鎖也容錯（與 Codex 對稱）

上次只對 Codex `config.toml` 被鎖容錯；這次把 Claude `settings.json`（第 7a 步）也包 try/catch——
萬一 Claude Code 開著鎖住 settings.json，**印 `[7a] DEFERRED` 並照常裝完**，關掉 Claude Code 重跑一次補上。
驗證：無鎖時 7a 正常註冊、走到 complete、settings.json 有效（3/3）。

---

## 2026-06-03 — 修 /status 與 doctor 對「技能不同步」的誤報（用戶回報）

用戶在 Codex 跑 /status 得到「Needs cleanup：個人層技能不同步」，但那其實正常：
- 9 個**操作**（capture/dream/.../status）在 **Claude 是指令、Codex 是技能＝設計如此**，必然顯示「Codex only」。
- 其餘像 cheat-*/internal-check/pdf-to-excel/pptx 是**用戶自己之前裝的技能**；`/harvest` 升格的技能一律
  **原子物化到兩平台**，所以單平台的技能＝用戶自己的＝**不是問題**。

修正（純提示詞 + doctor 腳本）：
- `status.md`：比對技能同步時**排除操作名**；單平台技能標為「你自己的、純資訊」，**不據此判 Needs cleanup**。
  「Needs cleanup」只留給真問題（死連結、硬擋掛掉、層級溢出）。全新安裝、計數全 0 且硬擋正常＝**Healthy**。
- `memory-lint.{ps1,sh}`：原本 `WARN promoted skills diverge` → 改為 **PASS（資訊）**：「N on both；
  one-platform-only（your own, not a problem）：…」。

驗證：本機 doctor 該行由 WARN → **PASS**（cheat-* 列為「你自己的」），其餘不受影響。

---

## 2026-06-03 — Codex 也有斜線指令（/capture 等，用戶要求）

查證 Codex 支援 custom prompts：`~/.codex/prompts/<name>.md` → 檔名即指令名（`capture.md`→`/capture`）。
官方標為 deprecated、建議用 skills（框架本就用 skills），但**目前仍可用**。應用戶要求補上，讓 Codex 兩種並存：
- 安裝器 `install-personal.{ps1,sh}`：操作改成**三物化**——Claude `commands/`、Codex `~/.agents/skills/<op>/`
  （意圖觸發）、**Codex `~/.codex/prompts/<op>.md`（斜線 `/capture`）**。同一份 operation .md 來源。
- 入口檔 `AGENTS.md`：Operations 段說明 Codex 可「打 `/capture` 斜線」或「講意圖」兩種觸發，並註明 prompts 屬 deprecated 但可用。

驗證：隔離安裝 → `~/.codex/prompts/` 出現 9 個 op、技能並存（5/5）；部署到本機 9 個斜線指令就位。
來源：developers.openai.com/codex/custom-prompts、/cli/slash-commands。

---

## 2026-06-03 — 新手指南加「Codex / VS Code 一行安裝」小節

把「自動找框架夾、一行跑 install+init、無視帳號名/專案名」的無腦安裝法寫進 `新手指南.md`，
附 Codex 後續 3 步（批准 hook、重載、講意圖）與容錯說明（Codex 開著也會裝完、印 DEFERRED）。
這樣分享給朋友只要丟新手指南連結即可，不必每次複製指令。

---

## 2026-06-03 — install-personal 對「Codex 開著鎖住 config.toml」容錯（用戶回報）

朋友首次安裝時，因 Codex 正開著鎖住 `~/.codex/config.toml`，第 7b 步 `Add-Content` 拋 IOException，
配上 `$ErrorActionPreference='Stop'` 導致**整個安裝中斷**。改成 try/catch：被鎖時**印 `[7b] DEFERRED`
清楚說明（記憶＋技能已裝好、只差 Codex 硬擋 hook、關掉 Codex 重跑即可），安裝照常走到 complete**。
不誤寫、不毀既有設定。驗證：模擬獨占鎖 → 仍 complete、印 DEFERRED、config.toml 原樣保留（5/5）。

---

## 2026-06-03 — 更新 4 份文件跟上新功能（Saved Tools 等）

確認 5 份使用者文件是否跟上最近功能；`機制與工具總覽.md` 本就最新，其餘 4 份補上：
- **安裝行為說明.md**：安裝物清單補 `lib/{memory-write,detect-repeats,tool}`、`reset/`、`tools/tools.json`、
  guides 的 `_memory-gate.md`（先前少列了這幾樣）。
- **記憶名詞對照表.md**：新增 `saved tools`（存起來的程式）、`repeat candidates`（重複候選）兩個名詞，
  並把 skills 的說明改為「判斷型工作流」以對比 tool。
- **新手指南.md**：「幾個重點」加一條 🧰 Saved Tool（固定機械程式存起來下次直接跑）。
- **記憶機制白話說明.html**：流程「重複的事」那步補上「固定機械程式 → 存起來下次直接跑」。

驗證：4 份新內容就位、零殘留斷連結（指向已刪文件）。

---

## 2026-06-03 — Codex 可見性修正（功能本就支援，修文件＋doctor 檢查）

Codex 第 5 輪：功能上已支援 Codex，要補的是**文件與 doctor 的 Codex 可見性**。4 條全採納：
- **#1 根目錄 `AGENTS.md`**：第 3 行原寫「Claude Code loads」（這是 Codex 讀的 repo 指引）→ 改「**Codex**
  loads；Claude 雙生是 `./CLAUDE.md`」。（亂碼連結已於上輪文件瘦身一併修為 `機制與工具總覽.md`。）
- **#2 `canonical/entry/AGENTS.md`**：Codex 範例（detector / Saved Tools）原本 `.sh` 在前 →
  改 **`.ps1`（Windows）在前、`.sh`（Mac/Linux）在後**，避免 Windows 上的 Codex 照抄錯腳本。
- **#3 doctor 檢查入口檔**：`memory-lint.{ps1,sh}` 新增——`~/.claude/CLAUDE.md` 與 `~/.codex/AGENTS.md`
  是否存在且含 `AI-MEMORY` block；缺了該平台開場就不載入記憶 → **WARN**（補上 Codex 入口的紅旗）。
- **#4 `機制與工具總覽.md`**：檔案樹的「開場載入」只寫 CLAUDE.md → 補上「Codex 由 `AGENTS.md` 載入」。

> 維持：Codex skill 走 `.agents/skills/`（**非** `.codex/skills/`）。
> 驗證：doctor 入口檢查正向 2 PASS、負向（缺 block／缺檔）各 WARN；隔離安裝 14 pass/0 fail；bash -n 乾淨。

---

## 2026-06-03 — 文件瘦身：刪 4 份重疊／過時技術文件（8 → 4）

文件太多且重疊、技術類又跟不上最近功能（Saved Tools／detect-repeats／memory-write）。整併：
- **刪除**：`TECHNICAL_GUIDE.md`、`MEMORY_GUIDE.md`、`DUAL-PLATFORM-GUIDE.md`、`生活化測試流程.md`
  ——都與 `機制與工具總覽.md` 重疊且過時。
- **保住獨特內容**：刪 `MEMORY_GUIDE` 前，把其「記憶檔案結構（檔案在哪）」樹狀圖併進 `機制與工具總覽.md`
  （含「只有 MEMORY.md 會被召回、對話 log 不會」的提醒）。
- **修連結**：README 文件表移除 4 列；`CLAUDE.md`/`AGENTS.md`/`ROADMAP.md`/`安裝行為說明.md`/`新手指南.md`
  的引用改指向 `機制與工具總覽.md`。掃描確認零殘留斷連結（CHANGELOG 歷史除外）。
- **保留的使用者文件（4）**：`新手指南.md`（用）、`記憶名詞對照表.md`（名詞）、`機制與工具總覽.md`（技術全覽）、
  `安裝行為說明.md`（安裝改動）。

---

## 2026-06-03 — 修「捕捉到個人層卻像失憶」（用戶回報 recall bug）

用戶回報：兩個資料夾問同樣問題 + `/capture`，一個進個人層、一個進專案層；**個人層那筆再打開像失憶，
專案層正常**。根因：① 路由只看 `./.claude/memory` 是否存在（跑過 `init-project` 才有專案層），所以兩夾去不同層；
② **開場只自動載入各層 `MEMORY.md`（+doctrine/persona），`conversations/*.md` 不會載入**——所以只落在
對話 log、沒進 `MEMORY.md` 索引的捕捉，開場讀不到＝像失憶。

`capture.md` 三項強化（純提示詞）：
- **#1 報告講清楚**：寫到哪層、**有沒有進 `<層>/MEMORY.md` 索引**、以及「個人層每次載入／專案層開該專案才載入」。
- **#2 個人知識強制建索引**：Step 5 改為「索引進**內容自己那層**的 MEMORY.md」，並明訂**想被 recall 的必須是
  knowledge 頁＋MEMORY.md 一行指標，不能只丟對話 log**（log 不自動載入，要 `/dream` 才會升格）。
- **#3 非初始化資料夾提醒**：偵測 `./.claude/memory` 不存在時，主動說「已存個人層（全域），要專案本地記憶請跑 `init-project`」。

驗證：3 條規則就位；示範證明「進 MEMORY.md 索引→開場載得到；只進對話 log→載不到」。

---

## 2026-06-03 — README 補「上下文紀律」核心段（繁中文件更新）

- `README.md` 新增〈上下文紀律：什麼該記／壓縮／清理〉一節，把 A–D 的精神（完整保留高訊號＋原文 identifier、
  結構化壓縮、signal-density 篩選、compaction 前安全網）寫成核心理念，並連到 `機制與工具總覽.md`。CHANGELOG
  的 A–D 細節見下一筆。

## 2026-06-03 — Context engineering 紀律（A–D）：what to keep / compress / clean

讀完 4 份 context-engineering 技能（fundamentals / compression / optimization / memory-systems）+ Codex
分析後，補上「對話沉澱成記憶」時的上下文管理紀律。核心觀念：**context 是有限的注意力預算、不是倉庫**——
低訊號記憶會稀釋高訊號記憶。骨架本來就對（index/detail 分離、compiled-truth+timeline、信心分層、dream
整合），這次補的是**寫入/壓縮的紀律規則**（純提示詞、零依賴）：

- **A. identifier 原文保留**：捕捉/壓縮時，路徑/函式名/error code/SHA/API 參數/指令**一律原文，不可改寫**
  （`config/redis.ts` 不可寫成「那個設定檔」）。改 `capture.md` Step 2.0、`dream.md` Phase 3d、`_memory-gate.md`。
- **B. 結構化摘要壓縮**：`dream.md` 溢出守衛封存/裁切前，先產 `Intent/Decisions/Files-IDs/Current state/
  Next steps` 結構化摘要再搬原文——不再「保留 N 行」式盲裁，避免無聲丟掉「為什麼」。
- **C. 利化保留判準（signal-density test）**：知識閘門/Gate 加「**拿掉它，AI 下一步會不會做錯？不會就不留**」。
  改 `capture.md` Step 2.0、`_memory-gate.md`。
- **D. compaction 前安全網**：入口檔 `CLAUDE.md`/`AGENTS.md` 加規則——長對話/階段轉換/視窗快滿時，
  **主動 `/capture` 當前任務+決策+下一步+原文 identifier**，再讓 harness 壓縮；不重造 runtime mask/compaction
  （那是 harness 的層）。

刻意不做：① 不在框架內重造 runtime context 的 mask/compaction（harness 職責）；② 不現在上向量檢索
（ROADMAP 項目 6，等知識頁破百再說）。

驗證：4 條規則在 7 個已部署檔點全部就位、doctor 0 fail。

---

## 2026-06-03 — 修 bug：/reset 沒有重置 MEMORY.md 索引（用戶回報）

用戶回報「reset 後記憶還在」——因為腳本清了內容檔（conversations/knowledge…），但**沒清每次載入的
索引 `MEMORY.md`**，它還列著已被刪的條目。舊流程要再跑 `/dream` 才會重建索引，不直覺。

- `reset.{ps1,sh}` 清除成功後**自動剪枝 `MEMORY.md`**：移除「連結指向已不存在 .md 檔」的索引行
  （剛清掉的對話/知識），保留標題、Environment-Limits 區段、以及仍存在檔案的連結。確定性、支援部分重置。
- `reset.md` Step 4/5 更新：`/dream` 現在只在想「完整重建索引」時才需要。
- 驗證：清 conversations+knowledge → 對話/知識索引行被剪、doctrine 連結+標題+非連結行保留（ps1 6/6、sh 4/4）。

---

## 2026-06-03 — Codex 第 4 輪建議：採納 3 條、延後 2 條

- **#2 memory-write 壞 registry 不再重建空檔（安全 bug）**：`block-tool` 讀到**存在但壞掉**的
  `blocked-actions.json` 時，原本退回空物件→會把既有壞工具洗掉（安全網本身）。改成**拒絕寫入、保留原檔、
  退出碼 5**，提示手動修。`.ps1`+`.sh` 都改；`.ps1` 順手改 UTF-8 明讀。檔案不存在才 seed 空檔。
- **#1 doctor 檢查 lib backbone**：`memory-lint` 新增——`memory-write`/`detect-repeats`/`tool` 的
  `.ps1`+`.sh` 是否齊全、`.ps1` parse-clean（`.sh` 由 Mac/Linux 端 doctor 用 `bash -n` 驗，Windows 端
  不跑 bash 避免 CRLF/路徑假錯）。
- **#5 doctor 記憶內容安全掃描**：掃 MEMORY.md/knowledge/conversations 是否含 prompt-injection /
  exfiltration 句型（ignore previous instructions、exfiltrate、reveal system prompt…），命中 **WARN**
  （人審；記憶可能合法引用這類字）。是「記憶當 data」規則的確定性兜底。
- **延後（ROADMAP 項目 7、8）**：#3 session-end auto-capture（要 SessionEnd hook 子系統，較大；
  /ingest+nightly 已補漏）、#4 saved-tool 驗證中繼資料（YAGNI，沒消費者前先不加空殼）。

### 驗證
```
memory-write：壞 registry → exit 5、原檔保留、修好後既有+新工具都在 → 3/3 PASS
doctor：lib backbone present(PASS)、memory content clean(PASS)、注入語句→SECURITY WARN(命中)
        修掉 Windows 端 bash -n 假錯後 → 12 pass / 0 warn / 0 fail；bash -n 兩腳本乾淨
```

---

## 2026-06-02 — 新增「機制與工具總覽」文件 + README 更新

- 新增 `機制與工具總覽.md`（+ `.html`）：把所有 `lib/` 確定性腳本（`memory-write`／`detect-repeats`／
  `tool`）與其他腳本（hook／reset／doctor／nightly）、所有機制（Memory Decision Gate／two-step write／
  重複偵測分流／Saved Tools／硬擋／注入防護／雙層／雙平台）整理成一張地圖，附 CLI/退出碼速查、三條
  「省你重寫」lane（tool/skill/automation）對照、以及踩過的 PS 5.1 環境雷清單。
- `README.md` 更新：核心理念加入「重複偵測 → Saved Tool／skill 分流」與 `lib/` 確定性腳本說明；
  文件表加入總覽連結；首段介紹補上「機械程式存成工具直接跑」。

---

## 2026-06-02 — 新增「Saved Tools」：存起來的程式，下次直接跑（不重寫、也不變 skill）

解決一種情境：請 AI「截屏到桌面」這類**固定機械動作**，AI 每次都重寫程式很煩。這不適合 skill
（playbook）也不適合 automation（排程）——該是「**第一次寫好就存、下次同樣請求直接執行**」。

- **新增 `canonical/lib/tool.{ps1,sh}`**（裝到 `~/.ai-memory/lib/`）：`list` / `run <slug> [args]` /
  `add <slug> --desc --triggers --script` / `path`。`add` 把能用的程式複製進 `~/.ai-memory/tools/<slug>.{ps1,sh}`
  並寫進註冊表 `tools/tools.json`（trigger 語 → 程式）；`run` 直接執行存好的程式、不重寫。
- **兩條規則寫進入口檔 `CLAUDE.md`/`AGENTS.md`**：① **寫程式前先查** saved tools，命中就直接 `run`；
  ② **第一次寫好且看似會重複**，主動問「要不要存起來下次直接跑？」存檔+註冊。Saved tools 屬個人層、跨專案。
- `/help` 加「Saved Tool vs Skill」對照；`/status` 顯示已存幾支；安裝器建 `tools/` + 空註冊表 + 部署 lib/tool。

### 修正
- PS 5.1 用 ANSI 讀回無 BOM 的 JSON（trigger 含中文）→ `tool.ps1` 的 `Load()` 解析失敗、list 顯示空。
  改用 `[IO.File]::ReadAllText(..., UTF8)` 明讀。驗證：add/list/run/idempotent 全過、中文 trigger 正確存讀、
  run 真的執行存好的程式；隔離安裝部署 + 空註冊表就位。

---

## 2026-06-02 — 重複計次「不分時間地點」：即時打標籤、單一 session 內也算

延續上一筆的重複偵測器。原本標籤是 `/capture` 跑時才補，所以**同一 session 內**的重複在跑 capture 前
不會被數到。改成**即時、每次都打**：

- `capture.md` Step 4 + 入口檔 `CLAUDE.md`/`AGENTS.md` 自動擷取段：**每做完一次重複工作流就當下立刻打**
  `- 🔁 repeat:<slug>` 到今天 log——**包含同一 session 的第 2、3 次**，不等 `/capture`；一旦某 slug ≥2×
  且無 skill，**session 中途就主動提醒**「要不要 /harvest 生成 skill？」。
- 計次明定 **time- and place-agnostic**：同 session／同天／跨 session／跨層一律累加（偵測器本就數所有標籤、
  含同一檔多筆）。
- 驗證：偵測器對「單一檔 3 筆」數成 3；模擬同一 session 連做 3 次、全程沒打 `/capture`，第 2 次當下即跨門檻提醒 → 4/4 PASS。

---

## 2026-06-02 — 重複工作流「主動偵測＋提醒生成 skill」（確定性偵測器）

框架本來就會在 `/capture`、`/dream` 時 offer「seen N× → 要不要 /harvest 變 skill」，但計次靠 AI
當下記得、且只在那兩個指令跑時才提。補上**確定性偵測 + 主動提醒**：

- **新增 `canonical/lib/detect-repeats.{ps1,sh}`**（裝到 `~/.ai-memory/lib/`）：掃兩層 `conversations/*.md`
  的 `🔁 repeat:<slug>` 標籤精準計次、排除「已有同名 skill」、列出 **seen ≥ 門檻且尚無 skill** 的工作流。
  read-only、退出碼恆 0、支援 `-Threshold`/`-Json`。
- **標籤格式**：capture/dream/ingest 改成每次出現都打 `- 🔁 repeat:<slug> — <desc>`（穩定 kebab slug、
  跨天重用），讓計次可確定化。
- **主動提醒**：入口檔 `CLAUDE.md`/`AGENTS.md` 的「On session start」加第 5 步——**一開 session 就跑偵測器**，
  若有 ≥2× 無 skill 的工作流，主動說「我發現你做過 X N 次，要不要用 /harvest 生成 skill？」（提一次、不嘮叨）。
- `/status` 也改用偵測器列出這些候選。安裝器部署兩個 lib 腳本。

### 修正（實作時踩到並驗證）
- PS 5.1 把**無 BOM 的 .ps1 內非 ASCII 字面**當 cp950 誤解碼 → 破壞腳本解析。偵測器**輸出改純 ASCII**，
  中文提醒語改放在入口檔/markdown（由 AI 講），不放在 .ps1。
- regex 加 `$` 錨點配 em-dash 比對失敗 → `md-to-html` 被回溯切成 `md-to`。改用 `repeat:` ASCII token、
  去掉尾錨點，slug 完整。
- 驗證：偵測器計次/排除已有skill/低門檻排除全對；隔離安裝部署 + session-start 提醒鏈通過；bash -n OK。

---

## 2026-06-02 — 吸收 GBrain / Harness / Hermes 的記憶處理（自主記憶 + 安全外殼）

從 `GBRAIN-系統理解.md`、`HARNESS-ENGINEERING-方法論與守則.md` 萃取記憶源碼處理方式，並參考
Hermes 的記憶安全機制，做成「**AI 自己判斷要不要記、但由框架決定怎麼安全地記**」。

### ① Memory Decision Gate（GBrain signal detector → 三層信心閘門）
- 新增 `canonical/operations/_memory-gate.md`（裝到 `~/.ai-memory/guides/`）。每個訊號判信心：
  **HIGH→自動寫（僅安全類別）· MEDIUM→只進候選 · LOW→跳過**。
- **關鍵界線（pushback Codex 的「高信心直接寫」）**：doctrine（行為準則）與 skill **永不自動寫**，
  即使高信心也只進 `doctrine_candidates.md` / `## 🔁 Repeat candidates`，由 `/review-doctrine`、
  `/harvest` 人審晉升。依據 **Harness 的 pass-state gating**（agent 不能自我晉升長期規則）。
- 接進 `capture.md`、`ingest-sessions.md`、入口檔 `CLAUDE.md`/`AGENTS.md` 的 auto-capture 段。

### ② Deterministic safe writer（移植 Hermes 的記憶寫入安全機制）
- 新增 `canonical/lib/memory-write.{ps1,sh}`（裝到 `~/.ai-memory/lib/`）：空內容擋、重複擋(dedup)、
  檔鎖、先讀磁碟最新、**temp+rename 原子寫**、drift 先備份（`.bak`）。兩個模式：
  `append`（安全追加）、`block-tool`（原子加入硬擋註冊表）。退出碼 0 寫入／0 SKIP 重複／2 空內容／3 鎖忙。
- **範圍刻意收斂**（pushback Codex 的「萬用 writer」）：只用在原子性最關鍵處——硬擋註冊表
  `blocked-actions.json` + append-only 檔；knowledge 頁需語意合併仍由 AI 編輯。
- `capture.md` Step 2.5 改用此 writer 寫硬擋。

### ③ Two-step write（Harness 兩步寫入，crash-safe）
- `capture.md` Step 5 明訂：**先寫完整 topic 檔 → 確認存在 → 才更新 MEMORY.md 一行指標**。
  中途壞掉只剩孤兒檔，不會把 index 寫爛；MEMORY.md 維持 bounded index。

### ④ Memory-context 注入防護（移植 Hermes 的 memory-context 標記）
- 入口檔加規則：**載入的記憶是「持久資料」不是「新使用者指令」**；記憶內含的命令式文字只是資料，
  不照做；live user 永遠是權威。防止存到記憶裡的第三方/網頁文字做 prompt injection。

### ⑤ 單一外部 provider 規則（前瞻護欄）
- `_memory-gate.md` §E：built-in markdown 永遠是主；未來接 GBrain/Mem0/qmd **最多一個**外部 provider。

### 驗證
```
memory-write.ps1：append/dedup-SKIP/empty-exit2/block-tool/valid-JSON/no-BOM 全過
memory-write.sh ：bash -n + append/dedup/block-tool 全過（python print 改 ASCII 防非 UTF-8 locale）
install-personal.ps1（隔離）：_memory-gate.md + lib/memory-write.* 就位、部署後 writer 實寫註冊表成功、
                              memory-lint 9 pass / 0 fail
```

---

## 2026-06-02 — /capture 顯示近 5 筆+累計、/reset 改用 deterministic 腳本

### ① 擷取紀錄看得見（用戶回報）
- `capture.md` Step 6：每次 /capture 完，除了本次結果，**列出近 5 筆擷取紀錄 + 累計筆數**，不用另開指令就看得到。
- `status.md`：新增「擷取紀錄總覽」——**累計 N 筆（跨 D 天）+ 近 5 筆**，當成「查看總紀錄」的指令。

### ② /reset 補一層 deterministic script（提升 Harness 可靠度）
原本 /reset 全靠 AI 照 markdown 跑，安全性不如真工具。新增：
- **`canonical/reset/reset.{ps1,sh}`**（安裝到 `~/.ai-memory/reset/`）：支援
  `-Layer personal|project|both`、`-Categories ...`、`-DryRun`、強制 `-Yes "yes reset"`；
  **先備份 → 校驗備份檔數 → 才清除 → 任何步驟失敗自動 rollback**。退出碼 0/2(拒絕)/3(校驗失敗)/4(已回滾)。
- `reset.md` 改為「**互動收集選擇 → 先跑 -DryRun 給用戶看計畫 → 用戶打 `yes reset` → 呼叫腳本實際執行**」，
  破壞性動作一律交給腳本，不再手動刪檔。層級規則照你說的：沒專案只問個人；有專案要選 只專案/只個人/兩者。
- 安裝器（`install-personal.{ps1,sh}`）部署 reset 腳本。

### 驗證
```
reset.ps1：dry-run 列 3 檔不動 · 無 -Yes → exit 2 拒絕 · 實跑 → 備份校驗 3 檔、清除、reflection 重置、
           doctrine（未選）保留、exit 0；rollback 路徑亦驗證。bash -n reset.sh / install-personal.sh ✓
```

---

## 2026-06-02 — 讓用戶看懂記憶名詞（中文對照表 + 索引雙語 + /help 速查）

### 背景
這套有很多英文分類名（conversations/reflection/knowledge/doctrine/preferences/persona…），用戶（尤其朋友）
容易看不懂。三管齊下讓「中文解釋」在用框架時隨處可見。

### 修改
- **新建 `記憶名詞對照表.md`（+ `.html`）**：兩層、四型、逐名詞「中文＋白話＋存哪＋例子」、「我這句話會分到哪」情境表。
- **MEMORY.md 索引標題雙語**：個人/專案範本的區段標題改中英並排（`## User 用戶`、`## Reference 參考`、
  `## Conversations 對話紀錄`…），用戶一打開記憶就看得懂。並改 `dream` Phase 4 / `capture` Step 5 也用雙語標題，
  避免整理後又被改回英文。
- **`/help` 加「記憶分類速查」**：打 /help 當場有中英對照小表。
- README / 新手指南 連結到對照表（新手指南 FAQ 也加一條「英文看不懂怎麼辦」）。

### 取捨
- 詞表**不**裝進 `~/.ai-memory`、MEMORY.md 也**不**用連結指它——避免「中文檔名當 PowerShell 5.1 字串字面值會解析錯」
  與「doctor 死連結」兩個雷。改為 `/help` 內含速查、repo 有完整詞表。

### 驗證
```
隔離安裝 → MEMORY.md 雙語標題齊全；doctor 無死連結、0 fail；bash -n install-personal.sh ✓
```

---

## 2026-06-02 — 文件同步收尾（硬擋措辭 + 白話版補 persona）

逐檔確認後，把上一輪「硬擋 100%」修正補到漏掉的文件：
- `DUAL-PLATFORM-GUIDE.md`：硬擋段標題與限制段 2 處「100% 技術保證」→「registry 有效且 hook 註冊時為硬保證；fail-open；doctor 報紅」。
- `TECHNICAL_GUIDE.md`：同上 2 處改寫，並補 doctor 跑「實際註冊指令」self-test 的說明；重生 `TECHNICAL_GUIDE.html`。
- `記憶機制白話說明.html`：抽屜補 **🎭 人設桶**；「邊聊邊記」補一句「忘了存也會回頭補抓最近對話」。
- 已確認 `README.md`、`MEMORY_GUIDE.html`、`新手指南.html` 本來就是最新（HTML 的 `100%` 僅 CSS `width:100%`，非內文）。

---

## 2026-06-02 — Codex 第三輪 review（2 項，皆成立）

**① ingest-sessions 殘留 "watermark" 字樣 → 統一為 checkpoint**
- `ingest-sessions.md` 的 description、標題、Step 1、Rules 仍寫 watermark，易讓 AI 以為還是「單一全域
  浮水印」。已改為 per-source checkpoint 用語（line 26 保留——那是在解釋「為何全域 watermark 太粗」的反例）。

**② doctor 是「報告工具」非「CI gate」→ 加 `-Strict`**
- `memory-lint.{ps1,sh}` 原本 `Exit 0 always`。新增 **`-Strict`（Win）/`--strict`（Mac/Linux）**：
  fail>0 → **exit 1**，讓它能當自動化/分享把關的 gate（符合 Harness「檢查要真的擋得住壞狀態」）。
  預設仍 exit 0（人看報告）。help / TECHNICAL_GUIDE 補說明；TECHNICAL_GUIDE.html 重新產生。

### 驗證
```
memory-lint -Strict：clean → exit 0；壞 registry → exit 1 ✓
ingest-sessions 僅剩 line 26 的反例 watermark；bash -n memory-lint.sh ✓
```

---

## 2026-06-02 — 採納 Codex 第二輪 review（5 項可靠性收尾，全部成立）

逐條對照程式碼驗證，5 項皆成立（都是我引入的缺口），依 reviewer 優先序修：

**① 入口檔 / README 同步 9 操作**
- `canonical/entry/CLAUDE.md` + `AGENTS.md` 的操作清單原本只列 5 個 → 補成 **9 個**（加
  ingest-sessions / schedule-dream / reset / help），恢復「入口即路由器」並讓補抓會話流程被新 session 看見。
- `README.md`：「八個指令」→「九個指令」，加 `/ingest-sessions`。

**② ingest-sessions：單一 watermark → per-source checkpoint**
- `ingest-sessions.md` Step 2/6 改為 `~/.ai-memory/cron/ingest-checkpoints.json`，每來源記
  `{session_id,last_event_ts,last_offset,content_hash}`。解決 transcript 延遲落盤 / 被重寫 / 跨專案
  mtime 亂序導致的漏抓（呼應 LLM Wiki raw-source 累積、GBrain source-aware）。

**③ nightly `-DryRun` 改成「真 dry-run」**
- 原本仍寫 audit/lock 且仍啟動 `claude -p`（靠 prompt 要求不寫）＝軟約束。改為**plan-only**：偵測 CLI +
  列出會處理的 scope + 印計畫即結束，**不啟動 agent、不寫 audit/lock/memory**。驗證：claude 在 PATH 仍不被呼叫。

**④ doctor hook self-test：執行「實際註冊的指令」**
- 原本只比對 settings.json/config.toml 是否含字串、self-test 跑 canonical 腳本（舊路徑/錯指令仍可能顯示通過）。
  改為**解析實際註冊的 command 並執行它**（Claude 從 settings.json JSON、Codex 從 config.toml）→ 證明真正被
  平台呼叫的那條指令可運作。驗證：`Codex hook registered command runs (self-test exit 0)`。

**⑤ 「硬擋 100%」文案修正**
- `README.md` + 入口檔：改為「**registry 為有效 JSON 且 hook 已註冊時為硬保證**；hook 解析失敗時 fail-open
  （壞 registry 不癱掉所有工具），doctor/`/status` 會報紅」。

### 驗證
```
nightly -DryRun → plan-only：不啟動 agent、audit.jsonl/memory.lock 皆未寫 ✓
doctor（隔離安裝）→ Codex 自我測試跑「實際註冊指令」PASS；10 pass 0 fail（Claude WARN 為沙箱 settings.json 限制）
bash -n nightly.sh / memory-lint.sh ✓
```

---

## 2026-06-02 — 文件補最新功能 + 產生 HTML 版

### 修改
- `新手指南.md`：指令表 8→9（加 `/ingest-sessions`），補「🎭 AI 人設」「怕漏記用 ingest」兩條白話重點。
- `MEMORY_GUIDE.md`：指令表加 ingest-sessions；個人腦檔案清單加 `persona.md`（AI 怎麼當 vs 偏好怎麼做）。
- `安裝行為說明.md`：8→9 操作（含 ingest-sessions）；copy-if-missing 清單加 `persona.md`。
- `TECHNICAL_GUIDE.md`：上一輪已補（9 ops、persona、doctor、nightly 加固）。
- **產生 HTML 版**：用自寫的 `md2html.py`（無外部依賴）把上述 4 份轉成自帶 CSS、可離線開的
  `*.html`（與 `記憶機制白話說明.html` 同放 repo 根目錄）。

---

## 2026-06-02 — 輸出語言預設繁體中文（指令檔維持英文）

### 背景
朋友機器的 `/review-doctrine` 截圖（EE.png）顯示指令輸出是英文。需求：**指令（操作檔本身）維持英文，
但 AI 的所有回覆/指令輸出/動作說明一律繁體中文**。

### 修改
- **入口檔加全域規則**：`canonical/entry/CLAUDE.md` + `AGENTS.md` 新增「Reply language (global)」——
  所有對使用者的輸出用繁體中文（除非使用者明顯用其他語言）；**指令檔本身維持英文，只有輸出是繁中**。
- 把語言指令**集中在入口檔一處**，不逐一翻譯各 `operations/*.md`（先前誤加到 8 檔已還原）。
- 旁註：截圖中朋友路徑為 `~/.claude/memory`（舊 v1）→ 需重跑 `install-personal` 升 v2 才會吃到此設定。

---

## 2026-06-02 — 採納 Codex code review（6 項）+ persona 桶

### 背景
Codex 對 v2 做了 code review，提 6 點。逐條對照程式碼驗證後處理（不盲從）：

**① ingest-sessions（自動沉澱不再只靠 agent 自覺）— 新增**
- 新建 `canonical/operations/ingest-sessions.md`：回頭讀 `~/.claude/projects/*.jsonl`、`~/.codex/` 會話
  記錄 + 未整合 log，抽訊號補沉澱。**浮水印（`cron/ingest-watermark.txt`）+ 去重**故可重放冪等；
  Chronicle 僅當線索、要回源頭核實。註冊進兩安裝器；**nightly 流程改為 ingest → dream → harvest 掃描**。

**② nightly 加固 — 改寫**
- `nightly.{ps1,sh}` 新增：單一 **`memory.lock`**（防並發 dream 弄壞記憶；逾 6h 自動清陳舊鎖）、
  **run-id**、每階段 **JSON audit**（`cron/audit.jsonl`）、**`--dry-run`**（只報告不寫）。
- **回應 reviewer 的「atomic write」**：實際 .md 寫檔在 agent 端（`claude -p`），wrapper 無法保證逐檔
  atomic；故只做「序列化 + 可審計」，不誇大 atomicity（文件已誠實標註）。

**③ doctor（lint 升級）— 改寫**
- `memory-lint.{ps1,sh}` 升級為 doctor：加查 死連結、Why+How+source+layer、Timeline source、
  未整合舊 log、專案層隱私洩漏啟發式、blocked-actions schema、**hook 是否註冊 + hook self-test**、
  skill-creator 兩平台、**升格 skill 雙平台同步**（已修「操作=Claude 指令 vs Codex 技能」造成的假分歧）。
- 隱私洩漏標明為**啟發式**（best-effort），不誇大成保證。

**④ hard-block 矛盾與 fail-open**
- **修矛盾**：`blocked-actions.json` 範本註解原本還說「要加 matcher」，與 capture「catch-all matcher
  不必改」衝突 → 已統一為「加登記即可」。
- **fail-open：保留並說明（pushback）**。安全 hook 若改 fail-closed，一個壞掉的 registry 會擋下**所有**
  工具呼叫、把 agent 弄癱——可用性上 fail-open 才對。改為**加可見性**：doctor/`/status` 對「registry 壞掉
  或 hook 沒註冊」**報紅（FAIL）**，並加 hook self-test，讓安全網掉了會被看見。

**⑤ schema — 採最小化 + persona（依你選擇）**
- 新增 **persona 桶**（type:user / kind:persona）：`canonical/templates/personal/persona.md`（AI 的
  人設/語氣/定位/邊界），入口檔每次載入、capture 路由 🎭 訊號進去。**persona = AI 怎麼當**，與
  **preference = 任務怎麼做** 分開。
- **強制 Why + How to Apply**：知識頁 Summary(=Why) 與 How to Apply 改為必填，doctor 檢查缺漏。
- 依你選擇**不加** confidence/privacy/review_after/last_used 等欄位（避免填寫摩擦，符合 ROADMAP 觸發式）。

### 改動檔案（重點）
`canonical/operations/{ingest-sessions(新),capture,status}.md`、`canonical/entry/{CLAUDE,AGENTS}.md`、
`canonical/templates/personal/{persona(新),MEMORY}.md`、`canonical/templates/blocked-actions.json`、
`canonical/operations/_routing.md`、`canonical/lint/memory-lint.{ps1,sh}`、`canonical/cron/nightly.{ps1,sh}`、
`install-personal.{ps1,sh}`、`help/DUAL-PLATFORM-GUIDE/TECHNICAL_GUIDE`。

### 驗證
```
doctor（隔離安裝後跑）→ 10 pass, 0 fail；hook self-test PASS；blocked-actions schema PASS；
  promoted-skill 同步假分歧已修（PASS）。
nightly -DryRun → run-id + dry_run:true + lock 取得/釋放 + JSON audit 三行齊全，lock 已釋放。
bash -n memory-lint.sh / nightly.sh / install-personal.sh → 全 OK。
```

---

## 2026-06-01 — capture 回溯短決策（「OK / 好」也能抓到關鍵拍板）

### 背景
用戶想法：使用者打一個簡短確認（「OK」「好」）就 `/capture` 時，那句話本身沒內容、容易被「跳過 routine
Q&A」濾掉——但它常常是**對前幾輪討論的最終拍板**。漏掉就丟了「短但關鍵」的決策。

### 修改
- `canonical/operations/capture.md` Step 1：新增規則——當使用者訊息是簡短確認/選擇（OK／好／就這樣／
  用 A／同意／對／不要／先這版…），**不要跳過**；回溯**前 3-5 輪**還原「到底拍板了什麼」（選了哪個、
  立場、被否決的選項+原因），把**還原後的決策實質**存成 💡 Insight/Decision（存實質、不是存「OK」）。
  純粹打招呼/無實質的確認才跳過。
- `canonical/entry/CLAUDE.md`＋`AGENTS.md` 的自動捕捉段也補同一條，讓**不打 /capture 的自動偵測**也適用。

### 效果
既保留「智慧過濾」（routine 還是跳過），又不漏掉用一句「好」敲定的關鍵決策。單一真相在 capture，
物化後 Claude 與 Codex 兩平台一致。

---

## 2026-06-01 — 收斂為 v2-only（準備上傳 GitHub）

### 背景
要上傳 GitHub 給所有人用，決定**只留 v2**，停止雙版維護（避免每次改動兩邊、避免新手困惑）。
v2 的 `install-personal` 會自動把舊 `~/.claude/memory` 遷進 `~/.ai-memory`，所以舊用戶重跑一次即可升上來。

### 刪除（v1 原始檔）
`install.ps1`、`install.sh`、`memory-lint.ps1`、`memory-lint.sh`、`commands/`、`hooks/`、`memory/`
（這些是 v1 全域安裝的來源；v2 改用 `canonical/` + `install-personal`/`init-project`）。
另清掉測試殘留的 `@{...}` 假檔，並在 `.gitignore` 加守則。

### 保留
`canonical/`、`install-personal.*`、`init-project.*`、`skills/skill-creator/`（官方版，v2 部署用）、
所有 docs、CHANGELOG/ROADMAP。

### 文件改為 v2-native（移除 v1 install.ps1 / 單層指引）
- `README.md`：重寫為 v2 首頁（兩步安裝、8 指令、雙層/雙平台、限制）。
- `CLAUDE.md`（repo 根）：原為 v1 入口範本（孤兒）→ 改為**貢獻者指南**（contract-first、改 `canonical/`、驗證）。
- `新手指南.md`：重寫為 v2 白話版（移除 v1 install.ps1 與 5 指令深講）。
- `MEMORY_GUIDE.md`：重寫為 v2「記憶庫結構」參考。
- `TECHNICAL_GUIDE.md`：重寫為 v2 機制詳解。
- `安裝行為說明.md`：重寫為 v2 兩安裝器逐檔行為。
- `DUAL-PLATFORM-GUIDE.md`：移除「舊版 README 是 v1」參照。
- `ROADMAP.md` / `生活化測試流程.md`：個人層家路徑 `~/.claude/memory` → `~/.ai-memory`、`install.ps1` →
  `install-personal`、hook 路徑改 `~/.ai-memory/hooks/...`、memory-lint 改 `~/.ai-memory/memory-lint.ps1`。
- `canonical/operations/schedule-dream.md`：移除指向 v1 的備註。
- `CHANGELOG.md`：保留 v1 歷史條目（那是歷史，不刪）。

### 驗證
```
install-personal.ps1（隔離 temp profile）→ [6]/[6b]/[7a]/[7b] 全綠；ops=8；skill-creator 兩平台 ✅
repo 根目錄只剩 v2 + 共享檔，無 v1 殘留、無 install.ps1 引用（CHANGELOG 歷史除外）。
```

---

## 2026-06-01 — 技能創建一律走官方 skill-creator（v2 接上）

### 背景
要求：創建 skill **必須透過官方 skill-creator**（github.com/anthropics/skills/.../skill-creator）的調用，
所以該技能要先裝進框架。經查證：框架資料夾 `skills/skill-creator/` 內的 `SKILL.md` 與官方 `main` 分支
**逐字一致**（含 `scripts/` `agents/` `references/` `assets/` `eval-viewer/` `LICENSE.txt`）——官方版**早已
內建於框架**。真正的缺口是 v2 沒把它部署出去、也沒讓 /harvest 走它。

### 修改
- **v2 安裝器部署 skill-creator 到兩平台**：`install-personal.ps1`/`.sh` 新增 step 6b，把
  `skills/skill-creator/` 複製到 `~/.claude/skills/skill-creator/` 與 `~/.agents/skills/skill-creator/`
  （copy-if-missing）。（v1 `install.ps1`/`.sh` 本來就會裝到 `~/.claude/skills/`。）
- **v2 /harvest 改為透過 skill-creator 創建**：`canonical/operations/harvest.md` Step 7 由「自行手寫
  SKILL.md」改為「**調用 skill-creator**（Claude 用 Skill 工具 / `~/.claude/skills/skill-creator`；Codex
  讀 `~/.agents/skills/skill-creator/SKILL.md`）走其 Creating-a-skill 流程 author，再雙物化」。完整 eval/
  benchmark 迴圈為選用（要嚴謹才跑）。
- `_materialize-skill.md` 補註：authoring 走 skill-creator，本 helper 只負責雙平台複製。
- v1 capture/dream 本來就調用 skill-creator（`Skill` 工具），維持不變。

### 驗證
```
install-personal.ps1 → [6b] skill-creator deployed；
  ~/.claude/skills/skill-creator/SKILL.md ✅、~/.agents/skills/skill-creator/SKILL.md ✅、scripts/package_skill.py ✅
bash -n install-personal.sh ✅；v1 install.sh 仍含 skill-creator 部署
```

### 文件同步（順手更新使用者文件）
- `新手指南.md`：新增「v2 比 v1 多了哪些指令」段（`/harvest`/`/reset`/`/help` + ≥2 門檻 + skill-creator
  輕量/嚴謹 + 工具失敗走硬擋 + 排程列/刪）。
- `help.md`（v1+v2）：/harvest 補「透過 skill-creator、輕量 vs 嚴謹（eval/benchmark）」說明。
- `README.md` / `TECHNICAL_GUIDE.md` 橫幅：補列 `/reset`/`/help`、skill-creator、≥2 門檻。
- `DUAL-PLATFORM-GUIDE.md`：操作表含 8 指令、skill-creator、≥2、排程管理。
- `MEMORY_GUIDE.md`：本體新增「v2 補充：新指令與行為變更」段（/harvest/reset/help + ≥2 + skill-creator
  + 排程列刪 + 分層），並修正「≥3 天升格」FAQ。
- `安裝行為說明.md`：本體新增「v2 安裝行為（install-personal + init-project）」逐檔段（含 skill-creator
  部署、reset/help 物化、兩平台 hook、專案層結構、不碰清單）。

---

## 2026-06-01 — 新增 `/help` 指令（功能 / 使用時機 / 如何確認通關）— v1 + v2

### 背景
新用戶（朋友）不知道有哪些指令、何時用、以及「怎麼確認有沒有成功」。新增自我說明指令。

### 修改
- 新建 `canonical/operations/help.md`（v2）與 `commands/help.md`（v1）。逐指令給三件事：
  **功能 / 使用時機 / ✅ 怎麼確認通關**（每個指令各有驗證方式，如 capture→檢查 conversations+
  blocked-actions、dream→reflection 多一則 + lint RESULT Z=0、harvest→skill 雙邊各一份、reset→備份路徑等），
  最後加「整體通關總檢」（/status + memory-lint Z=0 + 反思/準則/技能/硬擋四者有動）。
- 四個安裝器 op 清單加 `help`。`DUAL-PLATFORM-GUIDE.md` 操作表加 `help` 列。
- 驗證：install-personal 隔離安裝 → `help` 同時物化到 `~/.claude/commands/help.md` 與
  `~/.agents/skills/help/SKILL.md`；8 個 op 全到位。

---

## 2026-06-01 — 朋友回報三項修正（skill 門檻 / /reset / 排程管理）— v1 + v2 同步

### 背景

分享給朋友實用後回報三個問題：

1. **重複失敗卻沒生 skill**：朋友用同一方式網路搜尋連失敗 7-8 次、每次都 `/capture`，但因舊規則
   「同主題要跨 **3 個不同日期**」才升格，所以一直沒有 skill。**根因有二**：(a) 升格門檻以「天數」
   計算太嚴；(b) 更關鍵——「搜尋工具一直失敗」其實是**工具失效**，該走硬擋（擋掉壞工具），不是做一個
   「怎麼搜尋」的 skill（skill 修不好壞掉的工具）。
2. **想重置記憶**：多次 `/capture` 後存了一些不想要的記憶，希望有指令能「清空重來」。
3. **排程會越堆越多**：建立排程後沒有刪除方式，重複建立會產生多個排程 → 多個 dream 進程同時跑 →
   可能弄壞 memory。而且一般用戶不知道要用 `CronCreate/CronList/CronDelete`；且 **`CronList` 在
   Claude Code CLI 不顯示排程、在 VS Code 擴充才看得到**。

### 修改（v1 與 v2 都改）

**① skill 門檻：天數 → 次數，並把重複工具失敗導向硬擋**
- 升格判準由「跨 ≥3 天」改為「**出現 ≥2 次（同一天多次也算）**」。
- capture 明確區分：**同一工具/行為失敗 ≥2 次 = 工具失效 → Step 2.5 硬擋**（登記 `blocked-actions.json`
  + hook 擋掉、改用替代），**不是** skill 候選；「第 2 次失敗就升級硬擋，別再一直存普通記憶」。
- v2 的 capture 還會在偵測到 ≥2 次重複工作流時**主動提議**「要不要現在跑 /harvest 變成 skill」，
  不再被動等用戶自己記得。
- 檔案：`commands/capture.md`、`commands/dream.md`（v1）；`canonical/operations/capture.md`、
  `canonical/operations/dream.md`（v2）。

**② 新增 `/reset` 互動式記憶重置**
- 新建 `commands/reset.md`（v1）與 `canonical/operations/reset.md`（v2）。
- **執行時讓用戶選**（不寫死）：v2 先選層級（個人 / 專案 / 兩者），再選種類（對話+反思 / 含知識 /
  含準則+偏好 / 逐項）；v1 選種類。
- **一律先備份到 `archive/reset-YYYYMMDD-HHMMSS/` 再清、且要打「yes reset」確認才動手、絕不刪唯一副本**。
- `blocked-actions.json`（壞工具登記）預設**保留**（那是機器事實，不是雜訊），除非用戶明講才清。
- 四個安裝器的 op 清單都加入 `reset`（`install.ps1`/`install.sh`/`install-personal.ps1`/`install-personal.sh`）。

**③ 排程可列出/刪除 + 冪等不亂堆 + 抽象化**
- v2 `schedule-dream.md`：改為 **create / list / delete 三動作**；只維護**單一具名排程
  `ai-memory-nightly`**，建立用 `Register-ScheduledTask -Force` / cron `grep -v` 先除舊再寫——
  **永遠只有一個，不會重複堆疊**；list/delete 用 `Get-ScheduledTask`/`Unregister-ScheduledTask` 與
  `crontab`；**由 agent 代跑指令**，用戶用自然語言「列出/刪除排程」即可。
- v1 `schedule-dream.md`：加 list/delete（`CronList`/`CronDelete`）、建立前先刪舊（單一 `ai-memory-dream`）、
  並**明確標註 `CronList` 在 Claude Code CLI 不顯示、要去 VS Code 看**，附 OS 排程 fallback。
- 兩版都加：發現多個排程時，提議「全刪 → 重建一個」修「排程跑很多次」。

### 設計取捨

- **為什麼工具失敗不做成 skill**：skill 是「重複的工作流手冊」；一個壞掉的內建工具需要的是「停止呼叫它、
  改用替代」，那是硬擋層的事。把它做成 skill 既不會觸發、也修不好問題。
- **為什麼 /reset 互動而非寫死**：採用用戶「選擇權留給使用者」的意見——層級與種類在執行當下由用戶決定，
  降低「誤清個人腦 / 誤清準則」風險；且一律 archive-first 可救回。
- **為什麼排程改單一具名 + 代跑**：根治「重複建立 → 多進程做夢 → memory 壞掉」，並免去用戶記 cron 指令。

### 測試驗證

```
install-personal.ps1（隔離 temp profile）→ reset 同時物化到 ~/.claude/commands/reset.md 與
                                            ~/.agents/skills/reset/SKILL.md；7 個 op 全到位
bash -n install.sh / install-personal.sh → 皆 OK
```

---

## 2026-06-01 — v2 大改版：雙平台（Claude Code + Codex）× 雙層（個人 + 專案）× contract-first

### 背景與原因

v1 的「進化引擎」（反思→doctrine 審核 gate、GBrain dream cycle、實體頁、失敗回寫、PreToolUse 硬擋、
memory-lint、知識篩選閘門）本身合格，但有兩個與實際部署不符的硬假設，使既定目標無法達成：

1. **只支援 Claude Code**：入口靠 `CLAUDE.md`、指令靠 `~/.claude/commands/`、升格靠 Claude 的 `Skill`
   工具、排程靠 `CronCreate`、硬擋靠 Claude 的 `settings.json` hook——**Codex 使用者拿到的是沒有記憶、
   沒有反思、沒有硬擋的空殼**。
2. **全域家目錄安裝**：`install.ps1` 寫死 `~/.claude/`，不認識「每個人用前先建新專案、專案下建
   `.claude`/`.codex`」的流程，且全域單一腦在分享專案時會把個人 doctrine/偏好洩漏進別人的 repo。

此外，用戶的「核心提示詞」（掃歷史找重複工作流 → 證據候選 → 分形式封裝）在 v1 只有一個粗糙替代物
（同主題 ≥3 天就自動升格），缺證據審核 gate、缺形式選擇、缺對照現有資產去重。

### 已鎖定決策（3 輪 AskUserQuestion）

| 決策 | 選擇 | 理由 |
|------|------|------|
| 記憶拓樸 | **雙層混合** | 個人層全域共享（越來越懂你）、專案層隔離；個人層不進專案 git（解外洩）。對應 GBrain brain⊥source。 |
| 技能跨平台 | **單一真相 + 雙物化** | 一份 `SKILL.md` 物化到兩平台路徑。對應 GBrain contract-first，杜絕漂移。 |
| Codex 硬擋 | **接同樣硬擋** | 研究證實 Codex 有等價 PreToolUse hook（見下），不必退而求其次只做軟約束。 |
| Codex 技能路徑 | **跟 Codex 真實路徑** | Codex 在 `.agents/skills/`（repo）+ `~/.agents/skills/`（user）發現技能，**非** `.codex/skills/`；修正用戶原本的心智圖。 |

### 關鍵事實（WebSearch/WebFetch 查證 developers.openai.com/codex，2026-06）

- Codex 讀 `AGENTS.md`（專案 + `~/.codex/AGENTS.md` 全域）→ 雙入口可行。
- Codex Agent Skills 用**與 Claude 相同的 `SKILL.md` + `name`/`description` frontmatter** → 雙物化＝同檔寫兩處。
- Codex 有 `PreToolUse` hook（`~/.codex/config.toml` 內聯 `[[hooks.PreToolUse]]`，stdin 給 `tool_name`，
  以 `permissionDecision:"deny"` 或 **`exit 2`+stderr** 封鎖）→ 與現有 hook 的 `exit 2` 機制相容。

### 設計（contract-first：一份 canonical 來源 → 物化到各平台/各層）

```
個人層（全域、不進專案 git）  ~/.ai-memory（平台中立，Codex-only 朋友也不需 ~/.claude）
   入口  ~/.claude/CLAUDE.md ＋ ~/.codex/AGENTS.md（內容對等）
   操作  ~/.claude/commands/*.md（Claude）＋ ~/.agents/skills/<op>/SKILL.md（Codex）
   技能  ~/.claude/skills/ ＋ ~/.agents/skills/
   硬擋  settings.json（Claude）＋ config.toml（Codex），同一腳本＋同一登記簿
專案層（每專案）  <proj>/.claude/memory（知識/對話）、.claude/skills ＋ .agents/skills、.codex/config.toml
```

訊號分層路由：「關於我/行為/壞工具/跨專案反思」→ 個人層；「關於這個專案」→ 專案層；沒在專案裡 → 全進個人層。

### 修改清單（逐檔，全部新增於 `canonical/` 與框架根；v1 舊檔保留作回溯）

| 檔案 | 動作 | 內容 / 為什麼 |
|------|------|------|
| `canonical/PATHS.md` | **新建** | 路徑與分層的單一真相；定義個人/專案根解析、各平台物化目標、Codex 用 `.agents/skills` 的更正。 |
| `canonical/operations/_routing.md` | **新建** | capture/dream 共用的訊號→層級路由表（含隱私守則：個人記憶永不寫進專案 git）。 |
| `canonical/operations/_materialize-skill.md` | **新建** | 技能雙物化規程：同 `SKILL.md` 寫到兩平台、Claude 端為 canonical、失敗回寫後再鏡像。 |
| `canonical/entry/CLAUDE.md`／`AGENTS.md` | **新建** | 個人層雙入口（內容對等）：session start 先讀 `~/.ai-memory` 個人層、再讀專案層；含環境限制區與 Enforcement 說明。 |
| `canonical/entry/project-CLAUDE.md`／`project-AGENTS.md` | **新建** | 專案層入口範本（init-project 用），含 `{{PROJECT_NAME}}`。 |
| `canonical/operations/capture.md` | **改寫** | 由 v1 layer-unaware 改為層級感知；保留知識篩選閘門/實體頁格式/三層強制；Step 2.5 因 catch-all matcher 簡化為「加登記即可、不必改 matcher」；升格改為「丟 /harvest 評估」而非自動建。 |
| `canonical/operations/dream.md` | **改寫** | 雙層跑各 phase；移除粗糙「≥3 天自動升格」改為候選 roll-up 指向 /harvest；Phase 3.6 失敗回寫後**再物化到 Codex twin**；reflection/doctrine 固定走個人層。 |
| `canonical/operations/harvest.md` | **新建** | **落實核心提示詞**：蒐證（含對照現有資產去重）→ 行動標準 → 候選清單（證據/日期/頻率/信心/形式）→ 逐條人審 gate（複用 review-doctrine UX）→ 只建高信心缺失項、雙物化 → 盤點「已建/跳過/待更多證據」。 |
| `canonical/operations/review-doctrine.md`／`status.md`／`schedule-dream.md` | **改寫** | review-doctrine 固定個人層、批准一次覆蓋兩平台；status 雙層健檢 + 平台技能同步偵測；schedule-dream 改為**註冊 OS 排程**（Win 工作排程/cron）取代 CronCreate。 |
| `canonical/hooks/block-failed-actions.{ps1,sh}` | **新建** | 移植自 v1：改讀 `~/.ai-memory/blocked-actions.json`、接受 platform 參數、honor 條目 `platform` 欄位；`exit 2`+stderr 兩平台通用。 |
| `canonical/cron/nightly.{ps1,sh}` | **新建** | OS 級每晚 headless 跑 dream + harvest-scan（偵測 `claude`/`codex` CLI），匯整 reflections→doctrine 候選，**不自動批准/不自動建技能**（保留人審）。 |
| `canonical/lint/memory-lint.{ps1,sh}` | **新建** | 改為吃 root 參數、可同時檢個人層+專案層；檢 MEMORY/frontmatter(含 layer)/kebab/Current State+Timeline/doctrine id/blocked-actions JSON。 |
| `canonical/templates/personal/*`、`templates/project/MEMORY.md`、`templates/blocked-actions.json` | **新建** | 個人/專案層初始範本；blocked-actions 加 `platform` 欄位、ships 空。 |
| `install-personal.{ps1,sh}` | **新建** | 個人層安裝器：建 `~/.ai-memory`（**遷移**既有 `~/.claude/memory`，copy-if-missing 不刪原檔）、物化入口/操作/技能/hook/cron/lint、註冊兩平台 catch-all PreToolUse hook、staging `project-templates`。冪等。 |
| `init-project.{ps1,sh}` | **新建** | 每專案初始化：建 `CLAUDE.md`/`AGENTS.md`/`.claude/memory`/`.claude/skills`/`.codex/config.toml`/`.agents/skills` + `.gitignore` 防外洩守則。讀 `~/.ai-memory/project-templates`，故依賴先跑 install-personal。冪等。 |
| `DUAL-PLATFORM-GUIDE.md` | **新建** | v2 權威說明（雙層/雙平台/路徑/安裝兩步/誠實平台差異）。 |
| `README.md` | **編輯** | 頂部加 v2 橫幅指向新指南，標明舊內容為 v1 參考。 |

### 設計取捨（為什麼這樣改）

- **平台中立的個人腦 `~/.ai-memory`**（而非沿用 `~/.claude/memory`）：讓只用 Codex 的朋友不需要 `~/.claude/`。
- **catch-all matcher**（Claude `*`／Codex `.*`）+ 登記簿 gate：消除 v1「加工具還要手動編 matcher」的摩擦與「忘了加 matcher」的 bug 類。
- **升格改為證據式 /harvest**：v1「同主題被提到 N 天」會既過度升格（提到≠工作流）又漏抓（同工作流不同字眼）；改以「穩定輸入+可復現步驟+明確輸出」為判準，且人審後才建。
- **OS 級 cron 取代 CronCreate**：真正每晚自動、跨平台、不開 IDE 也能跑（對齊用戶「輕量 cron 每晚」原意）。

### 測試驗證（隔離 temp profile + 覆寫 USERPROFILE）

```
install-personal.ps1   全 7 步物化 OK（Claude 指令 + Codex ~/.agents/skills + guides/hook/cron/lint/templates）；冪等重跑 OK
Codex config.toml      正確產生 [[hooks.PreToolUse]] 區塊
Claude settings.json   合併邏輯產出有效、無 BOM JSON（first byte 123='{'）+ catch-all matcher + hook 指令
init-project.ps1       CLAUDE/AGENTS/.claude/memory/.claude/skills/.codex/.agents/skills/.gitignore 全到位
memory-lint（雙層）     RESULT: 6 pass, 0 warn, 0 fail
硬擋 hook              命中 WebSearch → exit 2 + 正確訊息；未命中 Read → exit 0
bash 語法檢查           install-personal/init-project/nightly/memory-lint/block-failed-actions 全 5 個 bash -n OK
```

### 注意 / 已知限制

- **沙箱假象（非 bug）**：測試時覆寫 `USERPROFILE` 指向 temp，本沙箱會保護 `<USERPROFILE>/.claude/settings.json`，
  導致該檔在測試環境落不了地（同夾 CLAUDE.md/commands/skills 都正常）。已用「寫到非 USERPROFILE 的 `.claude/settings.json`」
  單獨驗證合併+寫檔邏輯正確——**真實機器上會正常寫入**。
- 無法在沙箱真開 Claude Code/Codex 跑互動 session；操作是 agent 讀的 markdown，已正確物化，執行需在 IDE。
- 硬擋兩平台皆 100%（重啟後生效）；其餘記憶/準則仍為軟約束（~95%）。無向量搜尋（規模大可選接 qmd，見 ROADMAP）。

### 保留不動（明確復用 v1）

反思四維迴路、doctrine 審核 gate、實體頁 compiled-truth+timeline 格式、三層溢出保護、知識篩選閘門、
memory-lint 確定性健檢、誠實限制說明的精神——只做「層級/雙平台」適配，不重寫。

### 安裝流程（v2）

```
1) 每台機器一次（框架資料夾）：  .\install-personal.ps1   /  ./install-personal.sh
2) 每個新專案（進專案夾）：      .\init-project.ps1       /  ./init-project.sh
3) 重啟 Claude Code / Codex；每晚自動 → /schedule-dream
```

---

## 2026-05-31 — 防呆：把「內建工具失效」與「技能失敗」明確分開

### 背景

朋友的實況截圖顯示：WebSearch 失效被 `/capture` 記成了 **🛠️ Skill Failures**（技能失敗），
結果完全沒用、WebSearch 照樣被呼叫。根因是**歸錯類**：
- 技能失敗機制是給「會自動觸發的 skill 給錯答案」用的，教訓會寫進某個 `SKILL.md` 的
  `## Known Limitations & Fallbacks`，且**只在該 skill 觸發時才讀**。
- 但 WebSearch 是**內建工具**：沒有 SKILL.md 可寫、也不會那樣觸發 → 記了等於丟黑洞、照樣呼叫。

上一版雖已新增「⚙️ Environment/Tool Failure」信號與三層強制，但信號表同時並存「Skill Failure」
與「Tool Failure」兩列，Claude 仍可能重蹈覆轍把工具失效誤判成技能失敗。本次補防呆把歧義堵死。

### 修改清單（逐檔）

| 檔案 | 動作 | 內容 |
|------|------|------|
| `commands/capture.md` | **編輯** | 在 skill-failure 偵測段後加一條明確排除：內建工具壞掉（WebSearch 400／API key 未設／指令在此 OS 失敗）**不是** skill 失敗 → 一律走 Step 2.5；並說明為何記成 skill 失敗會「等於沒記」。 |
| `README.md` | **編輯** | 「失效行為強制層」段末加區分提示（工具失效 ≠ 技能失敗兜底）。 |
| `TECHNICAL_GUIDE.md` | **編輯** | 第六節「與 skill-failure 的分工」強化為「常見誤區」，點明內建工具無 SKILL.md。 |
| `MEMORY_GUIDE.md` | **編輯** | /capture 流程後加「兩者別記錯」提示框。 |
| `新手指南.md` | **編輯** | WebSearch FAQ 補「靠硬攔截不是筆記」；新增一條 FAQ 解釋「記成技能失敗為何沒用」。 |

### 效果

`/capture` 現在會把內建工具失效穩定導向 Step 2.5（MEMORY.md 指令 + blocked-actions.json + hook 硬擋），
不再誤入技能失敗的被動筆記路徑。文件五處同步說明這個區分，避免使用者（與 Claude）重蹈覆轍。

---

## 2026-05-31 — 修兩個朋友回報的真實 bug：/capture 過度捕捉 + 失效行為強制層

### 背景

朋友實際使用後回報兩個問題，兩個都是**機制設計缺陷**（不是用法錯）：

1. **/capture 把工作產物當知識存**：寫一個俄羅斯方塊後跑 /capture，它把 `tetris.html`
   當成「專案實體」建了知識頁。根因：Step 2 實體偵測對每個具名實體無差別建頁，缺「這是不是
   真知識」的篩選。
2. **記憶記了卻照樣重蹈覆轍**：環境的 WebSearch 已失效並寫進記憶，但下次搜尋它仍呼叫
   WebSearch、再次報錯。根因三疊：(a) 只有 MEMORY.md 每次載入、失效細節躺在不會被讀的
   knowledge 頁；(b) 記的是「(失效)」這種標籤而非「禁用 X、改用 Y」的可執行指令；(c) 完全
   沒有強制層，軟提醒擋不住模型的反射動作。框架原有的 skill-failure → `Known Limitations`
   回寫機制也屬被動，無法物理阻止重犯。

### 設計

**問題 1 — 知識篩選閘門**：capture Step 2 之前加 Step 2.0 閘門。黑名單（本次對話產物
／一次性任務名／暫存路徑絕不建頁）+ 真知識三問（跨對話？可重用事實？附帶實質內容？）+
判斷捷徑「三個月後另一個專案我會想翻這頁嗎」。

**問題 2 — 失效行為三層強制（資料驅動）**：
```
第1層 可執行指令  MEMORY.md 頂部「⚠️ Environment Limits & Blocked Tools」段（每次載入）
第2層 硬攔截      blocked-actions.json 登記簿 + PreToolUse hook → 物理擋下失效工具
第3層 行為準則    非單一工具的壞習慣 → doctrine_candidates → doctrine（每次當規則遵守）
```
核心：**hook 是「笨」且通用的——它不認識任何特定工具，只讀登記簿**。日後任何工具失效，
/capture 寫進登記簿即自動被擋，無需改任何程式碼。

### 修改清單（逐檔）

| 檔案 | 動作 | 內容 |
|------|------|------|
| `hooks/block-failed-actions.ps1` | **新建** | Windows PreToolUse 強制層。讀登記簿，命中工具 → exit 2（Claude Code 擋下並把 stderr 餵回），告知替代工具。fail-open（解析失敗不阻擋）。 |
| `hooks/block-failed-actions.sh` | **新建** | Mac/Linux 版，用 python3 解析（jq 不保證有）。邏輯同上。 |
| `memory/blocked-actions.json` | **新建（範本）** | 失效登記簿，安裝時佈署為空 `{"blocked_tools": []}`（machine-specific，朋友裝到的是空的）。 |
| `commands/capture.md` | **編輯 ×4** | 信號表加「⚙️ Environment/Tool Failure」列；新增 Step 2.0 知識篩選閘門；新增 Step 2.5 失效→三層強制；Rules 補「寧缺勿濫／產物不建頁／失效寫成指令+硬擋」。 |
| `memory/MEMORY.md`（範本） | **編輯** | 頂部新增 `## ⚠️ Environment Limits & Blocked Tools` 段（最高優先、每次載入、可執行指令）。 |
| `CLAUDE.md`（範本） | **編輯 ×2** | session-start 指示「Environment Limits 段是指令不是參考，逐條遵守」；新增「Enforcement Layer」段說明 hook 的硬保證。 |
| `install.ps1` | **編輯** | [1/4]→[1/5]：建 `hooks/`、佈署 hook、blocked-actions.json 納入範本、**用原生 ConvertFrom/To-Json 安全合併 settings.json 的 PreToolUse**（保留既有設定、idempotent、無 BOM 寫回）。 |
| `install.sh` | **編輯** | 同上，settings.json 合併改用 python3（無 python3 時印出手動指引）。 |

### 為什麼不新增指令

偵測屬 capture、強制屬 hook+CLAUDE.md、準則屬 doctrine——全部融入既有分工，維持 5 指令對
beginner 友善（與先前 skill-failure 機制的取捨一致）。

### 測試驗證

```
install.ps1  隔離安裝（覆寫 USERPROFILE，預置含 model+permissions 的 settings.json）
             → 合併後 model/permissions 完整保留 + 正確加入 PreToolUse hook；
               hooks/blocked-actions/commands/CLAUDE.md 全到位；範本登記簿 0 條。
hook(.ps1)   端對端（-File + stdin，比照 Claude Code 實呼叫）：
             WebSearch→exit 2 + 正確訊息；WebFetch→0；Read→0。
install.sh   bash -n 語法 OK；hook(.sh) bash -n OK；
             python 合併：保留既有 model+permissions + 加 hook，二次執行 idempotent skip。
```

### 注意

- hook 於**重啟 Claude Code 後**生效（開機載入 hooks）。
- 預設 matcher 為 `WebSearch`（最常見失效工具，開箱即用）；要硬擋其他工具，/capture 會提示
  把工具名以 `|` 補進 settings.json 的 matcher。
- 登記簿為**本機專屬**；分享框架時佈署的是空範本，朋友 WebSearch 正常則 hook 不會誤擋。

---

## 2026-05-31 — 保證機制補強（採納 Codex review：P1 + P2）

### 背景

Codex review 指出：框架概念閉環已到位，但仍是「prompt 驅動」，缺少「保證機制」。
本輪補上 4 項，讓它更接近可靠系統（不只靠 Claude 每次乖乖照做）。

### ① Skill 路徑標準化（真 bug 修復）

升格的技能原本被寫到 `~/.claude/commands/<name>/SKILL.md`——那既不是合法 slash 指令
（指令是扁平 `.md`）、也不在 skills 目錄，**Claude 根本不會自動辨識**。經查證你機器實況，
正確位置是 `~/.claude/skills/<name>/SKILL.md`（50+ 內建技能都在這）。

- `capture.md` / `dream.md` / `status.md` / `TECHNICAL_GUIDE.md`：升格、定位、索引、技術圖
  全部由 `commands/<name>/` 改為 `skills/<name>/`。
- `install.ps1` / `install.sh`：新增 `SKILLS_PATH`、建立 `~/.claude/skills`、**安裝 bundled
  skill-creator** 到 `~/.claude/skills/skill-creator/`（框架自帶，不再依賴環境既有的）；
  移除無用的 `memory/skills`。
- README / MEMORY_GUIDE 結構圖：skills/ 移出 memory，改列在 `~/.claude/` 下。

### ② memory-lint 確定性健康檢查器（最高價值）

`/status` 是 prompt 不是檢查器。新增 `memory-lint.ps1` + `memory-lint.sh`，用程式檢查
8 項不變量：MEMORY.md 連結是否存在、knowledge frontmatter（type/kind/first_seen/
last_updated）、kebab-case 檔名、Current State + Timeline 區塊、doctrine 候選狀態、
doctrine D-XXX 格式、skill fallback 去重、對話檔名 YYYY-MM-DD。退出碼 0=無 FAIL、1=有。

- 安裝器把它複製到 `~/.claude/`（固定路徑，dream 與用戶都找得到）。
- `dream.md` 新增 **Phase 6：Lint**，整合後自動跑並把 `RESULT` 附在報告。
- README / 新手指南 / TECHNICAL_GUIDE 都加了它的位置與用法。

### ③ /schedule-dream 的 CronCreate fallback

`CronCreate` 不一定存在於每個 Claude Code 環境。`schedule-dream.md` 新增 Step 2b：
無此工具時改用 OS 排程（Windows `schtasks` / Mac-Linux `cron`），或誠實告知用戶手動跑
`/dream`，並把 config 標 `⚠️ manual`。也明說：排程只能「提醒」，真正跑 /dream 需 Claude Code 開著。

### ④ Source attribution（每條知識可溯源）

Timeline 每行結尾強制附 `(source: 對話/檔案/URL)`，回答「這條記憶從哪來」；不確定的
Current State 事實可標 `(confidence: low)`。改在 `capture.md` 格式與規則、`dream.md`
Phase 3a、`TECHNICAL_GUIDE.md` 兩個格式區塊。

### 未納入（已在 ROADMAP 或已做）

3 層記憶＝已做的 4-type 分桶；git/restore 與 qmd 向量搜尋＝ROADMAP 觸發式延後項；
dream 分階段＝已是多階段（Phase 1/2/3/3.5/3.6/4/5/6）。

### 測試驗證

見最末測試小節（安裝回歸 + 對 populated memory 實跑 memory-lint）。

---

## 2026-05-31 — 知識頁雙層結構 + 記憶 type 分桶（中優先 Gap 3 + Gap 4）

### 背景與原因

- **Gap 3（llm-wiki 理論）**：舊知識頁的 `## 最新更新` 是純追加，頁面長大後 AI 要讀完整段歷史才知道「現在的狀態」。
- **Gap 4（目標④）**：全域記憶定義 4 種 type（user/feedback/project/reference），但框架結構沒對齊，知識頁也沒帶 why / how-to-apply。

兩者都改到同一個「entity 知識頁」，故合併為**一個統一新格式**一次解決。

### 設計

```
雙層結構（Gap 3）：## Current State（覆寫，當前真相，先讀）+ ## Timeline（只追加，歷史）
type 分桶（Gap 4）：frontmatter type: user|feedback|project|reference
                   + ## How to Apply（actionable）+ 摘要即 why + 索引按 type 分組
```

**決策：採邏輯分桶（type frontmatter + 索引分組），不用實體子資料夾。**
原因：beginner 友善、降低 capture「檔案是否存在 / 路徑解析」的複雜度與出錯風險；
grep + 索引即可達到同樣檢索效果。實體子資料夾列為後續可選。

| type | 存放位置 | 是什麼 |
|------|---------|--------|
| `user` | `feedback_user_style.md` | 用戶是誰 |
| `feedback` | `doctrine.md`（+candidates/reflection）| Claude 該怎麼做（why = 反思來源）|
| `project` | `knowledge/*.md` (type: project) | 正在做的事 |
| `reference` | `knowledge/*.md` (type: reference) | 工具/概念/人物 |

### 修改清單（逐檔）

| 檔案 | 動作 | 內容 |
|------|------|------|
| `commands/capture.md` | 編輯 ×2 | Step 2 改為 type-bucket resolver + 新的 compiled-truth/timeline 格式（含 `type`/`kind`/`last_updated`/Current State/How to Apply/Relations/Timeline）；找到既有頁改為「更新 Current State + 追加 Timeline」；Step 5 索引按 type 分組。 |
| `commands/dream.md` | 編輯 ×5 | Phase 1 建頁用新格式；Phase 2 `Relations`（`[[wikilink]]` 雙向）；Phase 3a 合併改為「刷新 Current State + 追加 Timeline」；Phase 3d 溢出保護改為「封存最舊 Timeline、Current State 永不封存」；Phase 4 索引按 type 分組。 |
| `CLAUDE.md`（範本） | 編輯 ×2 | 新增「Memory Types」4-type 對照表 + 知識頁雙層格式說明；結構樹標注 type。 |
| `memory/MEMORY.md`（範本） | 重寫 | 索引按 type 分組（User / Feedback / Projects / Reference / Skills / Conversations）。 |
| `commands/status.md` | 編輯 | 知識頁列表按 type 分組顯示。 |
| `TECHNICAL_GUIDE.md` | 編輯 ×4 | 兩個 entity 格式區塊 + 兩處引用同步成新雙層格式（避免文件與實作再次脫節）。 |

### 測試驗證

見最末測試小節（命名一致性 grep + 重跑安裝確認無回歸）。

---

## 2026-05-31 — 新功能：Skill 失敗兜底回寫（目標⑤）

### 背景與原因

研究報告 Gap 1 指出：框架能「升格」技能，但技能升格後**沒有失敗反饋機制**——同一個
skill 重複犯同樣的錯，不會自我修正。本次模仿 gbrain 的 `_friction-protocol.md`
（遇到困惑/錯誤就 log → 收集 → 回寫 → 下次進化），把「失敗 → 兜底回寫」的閉環補進框架。

### 設計（融入現有流程，不新增指令）

```
偵測（/capture）→ 對話中發現 skill 失敗 → 寫進當日 log 的「🛠️ Skill Failures」
                 （帶 severity：blocker/error/confused/nit，仿 friction 嚴重度）
回寫（/dream）  → 新增 Phase 3.6：掃 skill 失敗 → 找到對應 SKILL.md
                 → 追加/更新「## Known Limitations & Fallbacks」段（去重）
生效（執行時）  → CLAUDE.md 規則：skill 觸發前先讀該段 → 主動避開已知失敗
```

**為什麼不新增指令**：偵測屬 capture、回寫屬 dream，剛好對應「記錄 vs 整合」的既有分工；
維持 5 指令對 beginner 較友善。

### 修改清單（逐檔）

| 檔案 | 動作 | 內容 |
|------|------|------|
| `commands/capture.md` | 編輯 ×2 | 信號表加「🛠️ Skill Failure」列 + 失敗偵測準則（仿 friction「何時 log」）；當日 log 範本加 `## 🛠️ Skill Failures` 區塊（含 severity 欄）。 |
| `commands/dream.md` | 編輯 ×3 | 新增 **Phase 3.6: Skill Failure Writeback**（掃失敗 → 定位 SKILL.md → 寫/更新 `## Known Limitations & Fallbacks`，去重、找不到檔案時的處理）；升格 prompt 要求預留 fallback 段；Phase 5 報告加 3.6 統計。 |
| `CLAUDE.md`（範本） | 編輯 ×2 | 新增「When a Skill Triggers」段：skill 觸發前先讀 fallback 段並避開；信號偵測表加「Skill failure」列。 |
| `commands/status.md` | 編輯 ×2 | Step 1 統計含 fallback 段的 SKILL.md 數 + 未回寫的失敗數；報告 Self-Evolution 區塊顯示這兩個數字。 |

### 閉環的一致性（命名對齊）

```
capture 寫 →「## 🛠️ Skill Failures」(當日 log)
dream 讀  ←「## 🛠️ Skill Failures」→ 寫「## Known Limitations & Fallbacks」(SKILL.md)
CLAUDE 指示 → skill 觸發前讀「## Known Limitations & Fallbacks」
status 統計 →「## Known Limitations & Fallbacks」段數 + 未回寫失敗數
```

### 測試驗證

見下方測試小節（靜態一致性檢查 + 重跑安裝確認無回歸）。

---

## 2026-05-31 — 同步修復：把「自我進化迴路」補進可攜框架

### 背景與原因

研究發現：**「能進化的已安裝版（`~/.claude/`）」與「打算發佈的可攜框架（本資料夾）」不同步。**

- 說明書（`README.md` / `TECHNICAL_GUIDE.md`）描述完整 5 指令 + doctrine/reflection 自我進化迴路。
- 但實際打包的檔案只是舊簡化版：缺 2 個指令、`dream.md` 沒有反思階段、`CLAUDE.md` 沒有 doctrine 指針。
- 兩個 install 腳本其實已預期完整版（會複製 5 指令、建立 doctrine/reflection），但因指令檔缺失而 `Test-Path` 靜默跳過。

**後果**：若把此框架上傳 GitHub 給別人用，別人裝到的是「沒有靈魂的空殼」——能記對話、能升格技能，但不會反思、不會進化、不會越來越懂用戶。本次修復把自我進化迴路完整補進可攜框架。

### 修改清單（逐檔）

| 檔案 | 動作 | 原因 |
|------|------|------|
| `commands/status.md` | **新建** | 安裝器會複製此檔但檔案不存在 → 用戶只裝到 4 指令。英文版，路徑用 `~/.claude/memory/`，含技能進度條 + 自我進化區塊。 |
| `commands/review-doctrine.md` | **新建** | 同上。doctrine 審核/merge 流程（批准只寫 doctrine.md，不動 CLAUDE.md）。 |
| `commands/dream.md` | **編輯** | 缺自我進化核心。① 標題改「five phases + reflection」② 在 Phase 3 與 4 之間插入 **Phase 3.5: Reflection**（寫 reflection.md → 提煉 doctrine 候選）③ Phase 4 索引範本加 Self-Evolution 區塊 ④ Phase 5 報告補反思統計 + doctrine 候選預覽。 |
| `CLAUDE.md`（範本） | **編輯** | 原為簡化版。升級為完整版：session-start 同時讀 `MEMORY.md` + `doctrine.md`（並遵守準則）、列出全部 5 指令、補記憶庫結構與自我進化說明。保留 `{{MEMORY_PATH}}` 佔位與頂部 `# Claude Memory System` marker（安裝器靠它判斷是否已設定）。 |
| `memory/MEMORY.md`（範本） | **編輯** | 加入 Self-Evolution 區塊（指向 reflection/doctrine_candidates/doctrine）與 Skills 區塊；指令提示補齊 5 個。 |
| `memory/doctrine.md` | **新建（範本）** | 原本安裝器建空檔，新用戶開到空白會困惑。改放含說明的範本內容。 |
| `memory/doctrine_candidates.md` | **新建（範本）** | 同上。 |
| `memory/reflection.md` | **新建（範本）** | 同上。 |
| `install.ps1` | **編輯 ×2** | ① **Bug 修復**：Step 1 從不建立 `commands` 目錄（`.sh` 有、`.ps1` 漏）→ 全新安裝時 `Copy-Item` 丟錯，加上 `$ErrorActionPreference="Stop"` 會中止整個腳本，導致指令/記憶檔/CLAUDE.md 全沒建立。補上 `New-Item ... "$COMMANDS_PATH"`。② 三個系統檔改為「有範本就複製、否則建空檔」（原本一律建空檔）。 |
| `install.sh` | **編輯** | 三個系統檔改為「有範本就複製、否則 touch 空檔」，與 `.ps1` 對齊。（commands 目錄本來就有 `mkdir -p`，無 bug。） |

### 測試抓到的隱藏 Bug

`install.ps1` 缺少建立 `commands/` 目錄的步驟。在原作者電腦上 `~/.claude/commands` 早已存在（Claude Code 建的），所以永遠測不出來；但全新安裝會整個失敗。屬「自己機器跑沒問題、一發佈就壞」的典型陷阱，靠隔離安裝測試才抓到。已修。

### 測試驗證

把兩個安裝器分別安裝進隔離暫存目錄後檢查，再清理（未碰真實 `~/.claude/`）：

```
Windows  install.ps1 → 21 / 21 PASS
Mac/Linux install.sh  → 18 / 18 PASS
```

驗證項目：5 個指令到位、5 個記憶檔有內容、conversations/knowledge/skills 子目錄建立、
CLAUDE.md 的 `{{MEMORY_PATH}}` 正確替換且含 doctrine 指針、安裝後 dream.md 確含 Phase 3.5。

### 結果

可攜框架現在 = 完整自我進化迴路：

```
capture → dream(含 Phase 3.5 反思) → doctrine 候選 → review-doctrine → 永久準則
重啟時 CLAUDE.md 自動讀 MEMORY.md + doctrine.md → 不丟魂
```

### 尚未處理（後續可做）

- 目標⑤：skill「失敗兜底回寫」（模仿 gbrain friction-protocol）—— 尚未實作。
- knowledge 頁面雙層結構（compiled-truth + timeline，llm-wiki 理論）—— 尚未實作。
- memory type 分桶統一 —— 尚未實作。
