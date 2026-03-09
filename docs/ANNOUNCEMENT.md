# Announcement Copy

## 短版

我把 `news-verify` 整理成公開的 Gemini CLI Skill repo 了。

它會把一篇文章拆成 `fact`、`bias`、`evidence`、`timeliness` 四個維度並行查核，保留 prompt、result、checkpoint 與 error log，讓整個查核流程可觀察、可恢復、可追溯。

Repo:
https://github.com/slee124565/gemini-news-verify-skill

## 中版

我把 `news-verify` 發佈成公開 repo 了，這是一個給 Gemini CLI 用的新聞可信度查核 Skill。

它不是單次 prompt 式的「幫我判斷真假」，而是把同一篇文章拆成四個 worker 並行分析：

- fact
- bias
- evidence
- timeliness

每個維度都會留下自己的 prompt、result、checkpoint 與 error log，所以如果其中一個步驟失敗，可以直接用同一個 workdir 補跑，不需要整篇重來。

如果你在做新聞閱讀、資訊查證、媒體識讀或 agent workflow 實驗，這種 file-based orchestration 形式應該會比單次摘要更實用。

Repo:
https://github.com/slee124565/gemini-news-verify-skill

## README 首段版

`news-verify` is a Gemini CLI skill for four-dimension news credibility verification. It splits one article into `fact`, `bias`, `evidence`, and `timeliness` checks, keeps all intermediate files on disk, and supports checkpoint-based resume for failed runs.
