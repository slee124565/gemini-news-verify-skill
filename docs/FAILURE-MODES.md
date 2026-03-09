# Failure Modes

常見失敗情境：

- `gemini` CLI 未安裝
- `gemini` CLI 尚未登入
- 模型呼叫失敗或配額不足
- prompt template 缺失
- `article.txt` 不存在
- 某個維度輸出為空檔

排查順序建議：

1. 先看 `*_error.log`
2. 再看 `checkpoint/<dimension>.status`
3. 確認 `prompt_<dimension>.md` 是否正確生成
4. 用同一個 workdir 重跑 orchestrator

如果只有單一維度有問題，可刪除對應 checkpoint 與結果檔後補跑。
