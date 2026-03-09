---
name: news-verify
description: Verify the credibility of a news article or long-form post across four dimensions and produce a final credibility summary.
version: v0.1.0
---

# News Verify Skill for Gemini CLI

對一篇文章或報導，同時從四個獨立維度並行查核，最後彙整給出綜合可信度結論。

本 Skill 的根目錄只保留 `SKILL.md`。其餘資源依用途分流：

- `scripts/orchestrate.sh`：負責 file-based orchestration 與 checkpoint resume
- `assets/prompts/`：四個子任務的 prompt 樣板
- `references/synthesize.md`：主代理彙整最終報告時參考的邏輯

## Step 1：建立工作目錄與取得文章內容

1. 在 `news-verify/` 目錄下建立一個以時間戳記命名的工作目錄。
2. 若使用者提供 URL，先取得文章標題、來源、日期與正文。
3. 若使用者直接提供全文，直接使用該內容。
4. 將文章內容寫入 `article.txt`。

## Step 2：呼叫 orchestrator

請使用本 Skill 目錄下的腳本：

```bash
./scripts/orchestrate.sh <工作目錄路徑>
```

這個腳本會：

1. 讀取四個 prompt template
2. 具現化 `prompt_*.md`
3. 建立 `checkpoint/`
4. 並行發起四個 `gemini run`
5. 僅在四個維度都完成時返回成功

## Step 3：彙整結論

當下列檔案都存在且非空時：

- `result_fact.md`
- `result_bias.md`
- `result_evidence.md`
- `result_timeliness.md`

請讀取 `references/synthesize.md` 作為彙整邏輯，產出最終報告並寫入 `final_report.md`。

## 輸出要求

最終輸出需包含：

- 四個維度的評分
- 每個維度一句話摘要
- 整體可信度
- 主要疑慮
- 對讀者的建議
