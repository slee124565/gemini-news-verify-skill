# Output Format

最終報告預期包含：

- 四個維度的評分
- 每個維度一句話主要發現
- 整體可信度
- 主要疑慮
- 給讀者的具體建議

四個 worker 的中間結果格式分別由各自 prompt 定義：

- `result_fact.md`
- `result_bias.md`
- `result_evidence.md`
- `result_timeliness.md`

主代理在彙整時，會參考 `references/synthesize.md` 的輸出契約，將四份結果壓縮為一份可閱讀的 `final_report.md`。
