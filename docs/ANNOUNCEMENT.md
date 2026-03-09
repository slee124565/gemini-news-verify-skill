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

## 長版

我把 `news-verify` 整理成公開的 Gemini CLI Skill repo 了：

https://github.com/slee124565/gemini-news-verify-skill

這個專案的出發點很簡單：我不想只把一篇文章丟進單一 prompt，然後拿到一段無法追溯的結論。我想要的是一個比較接近「可觀察工作流」的查核方式。

所以 `news-verify` 不是單次摘要工具，而是把同一篇文章拆成四個維度並行查核：

- fact
- bias
- evidence
- timeliness

每個維度都會留下自己的 prompt、result、checkpoint 與 error log。這樣做的好處是：

- 你可以看到每個子任務到底怎麼分析
- 某個步驟失敗時，不需要整篇重來
- 同一個 workdir 可以直接用來補跑、除錯、比對結果

如果你平常在做：

- 新聞閱讀與資訊查證
- 媒體識讀
- prompt workflow 設計
- agent orchestration 實驗

這種 file-based orchestration 的做法，應該會比「只要最後答案」更有意思。

目前這個 repo 還是公開 MVP，先只支援 Gemini CLI。但核心流程已經完整，包括：

- install script
- release packaging
- checkpoint resume
- GitHub Release zip asset

如果你對這種「把 agent workflow 拆成可恢復、可追蹤的實體檔案流程」有興趣，歡迎直接拿去試，或用它作為你自己的 Skill / agent pipeline 範本。

## README 首段版

`news-verify` is a Gemini CLI skill for four-dimension news credibility verification. It splits one article into `fact`, `bias`, `evidence`, and `timeliness` checks, keeps all intermediate files on disk, and supports checkpoint-based resume for failed runs.
