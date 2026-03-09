# Privacy

使用這個 Skill 時，文章內容會被寫入本地工作目錄中的 `article.txt`。

這代表：

- 若文章含有敏感資訊，會以明文存在你的本地檔案系統
- 相關 prompt、result、error log 也可能包含文章片段
- 使用者應自行判斷是否適合對特定內容執行查核

若你的 workspace 受 Git 管理，建議確認 `news-verify/` 是否應加入 `.gitignore`。
