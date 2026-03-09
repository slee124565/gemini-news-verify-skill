# Architecture

`news-verify` 採用 file-based orchestration。

核心概念如下：

- `article.txt` 是單次任務的唯一原始輸入
- 四個 prompt template 會各自具現化成 `prompt_*.md`
- 四個 worker 分別產生 `result_*.md`
- `checkpoint/` 記錄每個維度的狀態與輸入簽章
- 只有四個維度都完成後，主代理才進入最終彙整

這種設計的價值：

- 背景執行中的每個維度都可獨立觀察
- 任一維度失敗時，不需要重做全部工作
- 輸入變更時，能靠簽章自動失效舊 checkpoint

狀態流轉：

- `pending`
- `running`
- `completed`
- `failed`

重跑規則：

- `completed` 且結果檔存在：沿用
- `failed`、`pending` 或結果檔缺失：補跑
- `article.txt` 或 template 變更：該維度簽章失效並重跑
