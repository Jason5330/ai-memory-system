# Personal Memory Index 個人記憶索引  (~/.ai-memory)

> Loaded every session on BOTH Claude Code and Codex. The personal layer is shared across all
> projects and never committed into any project's git. Project memory has its own MEMORY.md.
> 名詞看不懂（conversations/doctrine/persona…）？打 `/help` 看「記憶分類速查」，或翻框架 repo 的 `記憶名詞對照表.md`。

## ⚠️ Environment Limits & Blocked Tools 環境限制／壞工具  (highest priority — read and obey first)
<!-- Each line is an EXECUTABLE DIRECTIVE, not reference material. /capture writes here when a
     tool/behavior breaks in this environment. Named-tool failures are ALSO hard-blocked by the
     PreToolUse hook on both platforms (see blocked-actions.json). -->
_(none yet — entries look like: `- ❌ WebSearch broken (400, API key unset) → use WebFetch; do not call WebSearch.`)_

## User 用戶  (type: user — 你是誰)
- [feedback_user_style.md](feedback_user_style.md) — 偏好 how you like tasks done
- [persona.md](persona.md) — 人設 the AI's identity/voice/role for you (kind: persona)

## Feedback / Self-Evolution 反饋／自我進化  (type: feedback — AI 該怎麼做)
- [reflection.md](reflection.md) — 反思日誌 accumulated reflection log (empty until first /dream)
- [doctrine_candidates.md](doctrine_candidates.md) — 準則候選 pending review (run /review-doctrine)
- [doctrine.md](doctrine.md) — 行為準則 approved behavior rules (none yet)

## Reference 參考  (type: reference — 工具/概念/人物，跨專案知識)
_(personal knowledge pages: tools / concepts / people)_

## Skills 技能  (personal, cross-project)
_(promoted via /harvest; materialized to ~/.claude/skills AND ~/.agents/skills)_

## Conversations 對話紀錄  (personal / non-project sessions)
_(newest first)_
