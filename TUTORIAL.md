# Gemini News Verify Skill Tutorial

適用對象：已安裝 Gemini CLI 的使用者

目標：完成一次 URL 查核、一次全文查核，並理解工作目錄與 checkpoint 的用途。

## Lab 1：第一次用 URL 觸發

在你的 workspace 啟動 Gemini CLI，輸入：

```text
幫我查核這篇文章的可信度：https://example.com/news
```

你應該觀察到：

- Skill 會先取得文章內容
- 建立一個新的 `news-verify/<timestamp>/` 工作目錄
- 產生四份 prompt 與四份 result
- 最後輸出整體可信度報告

## Lab 2：直接貼全文

輸入：

```text
請幫我查核這篇報導，從事實、立場、證據、時效四個維度分析，最後給我整體可信度與主要疑慮。
<貼上全文>
```

這個情境適合：

- 網頁擷取失敗
- 文章內容在付費牆後面
- 你只想分析一段轉貼全文

## Lab 3：檢查工作目錄

進入這次任務的工作目錄後，重點看這些檔案：

- `article.txt`：原始文章內容
- `prompt_*.md`：四個 worker 實際收到的 prompt
- `result_*.md`：四個維度的分析結果
- `final_report.md`：最後彙整報告
- `checkpoint/`：每個維度的狀態、簽章與 metadata

## Lab 4：模擬失敗後重跑

若某個維度執行失敗，可直接對同一個 workdir 重跑：

```bash
./skill/gemini/scripts/orchestrate.sh /path/to/workdir
```

這時腳本只會補跑未完成或失敗的維度。

## Lab 5：強制重跑單一維度

例如要重跑 `fact`：

```bash
rm -f /path/to/workdir/checkpoint/fact.status
rm -f /path/to/workdir/checkpoint/fact.signature
rm -f /path/to/workdir/checkpoint/fact.meta
rm -f /path/to/workdir/result_fact.md
./skill/gemini/scripts/orchestrate.sh /path/to/workdir
```

## 你應該理解的核心概念

- 這不是單次 prompt，而是可恢復的多步驟工作流
- 中間檔案不是噪音，而是查核可追溯性的基礎
- 同一個 workdir 可以作為除錯與補跑的最小單位
