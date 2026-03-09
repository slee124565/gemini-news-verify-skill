# Gemini News Verify Skill

`news-verify` 是一個專供 Gemini CLI 使用的新聞可信度查核 Skill。它會將同一篇文章拆成四個維度並行分析：

- `fact`
- `bias`
- `evidence`
- `timeliness`

這個 Skill 的重點不是只輸出一個結論，而是保留完整中間產物，讓查核流程具備：

- 可觀察性：保留 prompt、result、checkpoint、error log
- 可恢復性：失敗後可在同一個工作目錄補跑
- 可追溯性：能回頭檢查每個維度的分析依據

目前版本定位為公開 MVP，支援範圍僅限 Gemini CLI。

## 核心能力

- 將文章分成事實、立場、證據、時效四個獨立維度並行查核
- 每個維度自動產生 `prompt_*.md`、`result_*.md` 與 checkpoint
- 若中途失敗，可重用同一個 workdir 從 checkpoint 恢復
- 最終輸出適合直接閱讀的整體可信度摘要

## 安裝

### 選項 A：Clone repo 後安裝到目前 workspace

```bash
git clone https://github.com/slee124565/gemini-news-verify-skill.git
cd gemini-news-verify-skill
./install.sh gemini local
```

安裝完成後，在 Gemini CLI 內重新載入：

```text
/skills reload
```

### 選項 B：安裝到 user scope

```bash
git clone https://github.com/slee124565/gemini-news-verify-skill.git
cd gemini-news-verify-skill
./install.sh gemini user
```

## 使用方式

安裝完成後，可直接對 Gemini CLI 說：

```text
幫我查核這篇文章的可信度：https://example.com/news
```

或直接貼文章內容：

```text
請幫我查核這篇報導，從事實、立場、證據、時效四個維度分析，最後給我整體可信度與主要疑慮。
<貼上全文>
```

## 產出內容

每次執行都會在工作目錄下產生類似以下檔案：

```text
news-verify/YYYYMMDD-HHMMSS/
├── article.txt
├── prompt_fact.md
├── prompt_bias.md
├── prompt_evidence.md
├── prompt_timeliness.md
├── result_fact.md
├── result_bias.md
├── result_evidence.md
├── result_timeliness.md
├── final_report.md
├── fact_error.log
├── bias_error.log
├── evidence_error.log
├── timeliness_error.log
└── checkpoint/
    ├── fact.status
    ├── fact.signature
    ├── fact.meta
    └── ...
```

## 手動驗證核心流程

若你想不透過 Gemini Skill 入口，直接驗證 orchestrator，可手動建立 workdir：

```bash
mkdir -p /tmp/news-verify-demo
printf '%s\n' '請將這裡替換成待查核文章全文。' > /tmp/news-verify-demo/article.txt
./skill/gemini/scripts/orchestrate.sh /tmp/news-verify-demo
```

只要四份 `result_*.md` 都成功產生，就代表四維度查核流程已完成。

## 恢復與補跑

同一個 workdir 可直接重跑：

```bash
./skill/gemini/scripts/orchestrate.sh /path/to/existing-workdir
```

腳本會自動判斷：

- 已完成且結果檔存在：沿用
- `failed`、`pending` 或結果檔遺失：只補跑該維度

若想強制重跑單一維度，可刪掉對應 checkpoint 與結果檔後再執行一次。

## Repo 結構

```text
.
├── README.md
├── TUTORIAL.md
├── LICENSE
├── install.sh
├── release.sh
├── docs/
│   ├── ARCHITECTURE.md
│   ├── FAILURE-MODES.md
│   ├── OUTPUT-FORMAT.md
│   └── PRIVACY.md
└── skill/
    └── gemini/
        ├── SKILL.md
        ├── scripts/orchestrate.sh
        ├── assets/prompts/*.md
        └── references/synthesize.md
```

## 限制與注意事項

- 僅支援 Gemini CLI
- 需要本機已安裝並可執行 `gemini`
- 需要 Gemini CLI 已登入且具備模型呼叫能力
- 文章內容會寫入本地工作目錄，請自行評估是否適合處理敏感資料
- 查核結果屬於輔助判讀，不構成法律、投資、醫療或其他專業意見

## Release

可使用：

```bash
./release.sh gemini
```

產生版本化 zip，例如：

```text
news-verify-gemini-v0.1.0.zip
```
