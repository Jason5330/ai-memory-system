# Roadmap — 延後工作清單（低優先項）

> **這份檔案是寫給未來的 Claude（和用戶）看的。**
> 當用戶下次提到「git 版控記憶 / 換電腦同步 / 搜尋找不到東西 / 記憶太多」時，先讀這份，
> 照著「怎麼做」執行，並在動手前**重新確認檔案與指令引用是否仍存在**（框架可能已改版）。
>
> 來源：`research-report.md` 第 E 節、`llm-wiki.md`、`gbrain-master/docs/`。
> 高優先 + 中優先已完成（見 `CHANGELOG.md`）；以下兩項刻意延後。

---

## 共同前提（先讀這段再決定）

```
這兩項都「不影響核心目標」。自我進化迴路（capture→dream→doctrine、不丟魂）已完整。
它們是「規模變大後」的優化，而且都會動到框架最大的賣點：零依賴、純 markdown、可分享。
原則：觸發式 —— 遇到實際痛點再做，不要預先加複雜度。
```

決策檢查表（出現以下訊號才考慮動工）：

| 訊號 | 對應項目 |
|------|---------|
| 用戶說「我想把記憶放進 git / 備份 / 換電腦同步」 | 項目 5 |
| 用戶說「git 倉庫被每天的對話紀錄塞爆」 | 項目 5 |
| 知識頁累積到 ~100+，且用戶抱怨「明明有記卻搜不到」 | 項目 6 |
| 用同義詞／換句話就找不到既有知識頁 | 項目 6 |

沒有這些訊號 → **不要做**。框架停在「完整、零依賴、可分享」是最佳狀態。

---

## 項目 5：Storage Tiering（分 git 追蹤 / 不追蹤）

### 為什麼做
當用戶要對 `~/.ai-memory` 做版本控制時，每天的 `conversations/*.md` 會讓 git 倉庫不斷膨脹。
分層之後：**人工策劃、有價值的知識**保留版本歷史；**機器可重生、雜訊性的紀錄**不進 git。

### 影響什麼
- 只在「用戶決定版控記憶」時才有感；不版控就完全沒差。
- 好處：git 倉庫乾淨、重要知識有歷史；換電腦只需同步被追蹤的那層。

### 分層定義
```
✅ git 追蹤（策劃、人工價值高）        ❌ 不追蹤（可重生 / 雜訊）
  doctrine.md                          conversations/
  feedback_user_style.md               reflection.md
  knowledge/*.md                       doctrine_candidates.md
  MEMORY.md                            **/archive/
```

### 怎麼做（步驟）
1. 在框架新增範本檔 `canonical/templates/.gitignore`，內容：
   ```
   conversations/
   reflection.md
   doctrine_candidates.md
   **/archive/
   ```
2. 改 `install-personal.ps1` 與 `install-personal.sh`：把它複製到 `~/.ai-memory/.gitignore`
   （沿用既有「copy-if-missing」模式，與其他範本檔同一個迴圈即可）。
3. 在 `TECHNICAL_GUIDE.md` / `README.md` 補一段「分層理由」說明。
4. （可選）框架本身根目錄的 `.gitignore` 維持現狀（整個 memory/ 仍是範本、不進框架 repo）。

### 怎麼驗證
```
在隔離暫存裝好後 → 進 ~/.ai-memory → git init → git add -A → git status
預期：只有 doctrine.md / feedback_user_style.md / knowledge/ / MEMORY.md 被 staged
      conversations/ 與 reflection.md / doctrine_candidates.md 不出現
```

### 成本 / 風險
低 / 低。多一層「哪些追、哪些不追」的概念，但不破壞零依賴。

### 參考
`gbrain-master/docs/storage-tiering.md`（gbrain.yml 的 `db_tracked` / `db_only`）、
`research-report.md` 第 C2 節。

---

## 項目 6：向量 / 語意搜尋（引入 qmd 或 gbrain）

### 為什麼做
知識頁累積到上百個後，**關鍵字索引（MEMORY.md）會漏掉同義的東西**：
搜「容器啟動失敗」找不到標題寫「Docker 問題」的頁。向量搜尋用 embedding 語意比對，同義也能找到。

### 影響什麼
- 檢索準確度（只在記憶很多時才明顯）。
- ⚠️ **直接打破框架「零依賴、純 markdown、只要 Claude Code」的賣點**——這是最該謹慎的一項。

### 兩條路（建議走 A）
```
路線 A — qmd（輕、推薦）
  本地 markdown 搜尋引擎，BM25 + 向量混合，on-device。
  有 CLI（Claude 可 shell out）也有 MCP server（Claude 當原生工具用）。
  來源：llm-wiki.md「Optional: CLI tools」、 github.com/tobi/qmd

路線 B — gbrain（重、全套）
  完整 PGLite 個人大腦。功能多但複雜度高，除非要全面轉移否則不建議。
```

### 怎麼做（步驟，以 qmd 為例）
1. 安裝 qmd。**動手時把實際安裝指令與 Windows/Bun 眉角記錄回這份檔**
   （框架記憶曾踩過 `Bun 需 --ignore-scripts`，見 `~/.ai-memory/knowledge/bun.md`）。
2. 設定 qmd 索引 `~/.ai-memory/knowledge/` 與 `conversations/`。
3. 在 `CLAUDE.md` 加一條 fallback 規則（或新增 `/recall` 指令）：
   「當 MEMORY.md 索引找不到相關頁時 → shell out 呼叫 qmd 做語意搜尋」。
4. **鐵則：markdown 永遠是真相來源（source of truth），qmd 只是索引層，絕不取代 markdown 儲存。**
   這樣即使拿掉 qmd，框架仍能運作。

### 怎麼驗證
```
用一個同義詞搜尋（例：搜「啟動不了」找標題是「Docker 問題」的頁）
預期：qmd 能回傳該頁；移除 qmd 後框架仍可正常 capture/dream（只是退回關鍵字搜尋）
```

### 成本 / 風險
高 / 高。新增依賴、跨平台安裝風險、分享門檻提高。**必須保持「可選」**——框架沒有它也要能跑。

### 參考
`llm-wiki.md`「Optional: CLI tools」（qmd）、`gbrain-master/`（PGLite 路線）、
`research-report.md` 第 E 節。

---

## 動工前的共同檢查清單（未來的 Claude 照做）

1. 先確認觸發訊號真的出現了（見上方決策檢查表），沒出現就回報用戶「目前不需要」。
2. 重新讀本檔對應項目的「怎麼做」，並**驗證引用的檔案/路徑/指令仍存在**（框架可能已改版）。
3. 動手前先跟用戶確認範圍（這兩項都會改動架構，屬不可輕易回頭的變更）。
4. 完成後：跑「怎麼驗證」、在 `CHANGELOG.md` 加紀錄、把實際踩到的坑回寫進本檔。
