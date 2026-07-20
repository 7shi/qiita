---
coediting: false
comments_count: 0
created_at: '2023-05-13T01:46:31+09:00'
id: 59e12ee1f56536710b83
likes_count: 3
private: false
reactions_count: 0
stocks_count: 0
tags:
- name: C#
  versions: []
- name: WindowsForm
  versions: []
title: TextBox への貼り付け時に改行コードを調整
updated_at: '2023-05-14T16:22:51+09:00'
url: https://qiita.com/7shi/items/59e12ee1f56536710b83
slide: false
---

Windows Forms の TextBox へクリップボードから貼り付ける際、改行コードが CR+LF でないと改行が表示されません。

貼り付け時に改行コードを調整して対処しました。

```cs
public class MyTextBox : TextBox
{
    public static string NormalizeNewLine(string s)
    {
        return s.Replace("\r\n", "\n").Replace("\r", "\n").Replace("\n", "\r\n");
    }

    protected override void WndProc(ref Message m)
    {
        const int WM_PASTE = 0x302;
        if (m.Msg == WM_PASTE)
        {
            try
            {
                var t = Clipboard.GetText();
                Paste(NormalizeNewLine(t));
                return;
            }
            catch { }
        }
        base.WndProc(ref m);
    }
}
```

# 参考

https://stackoverflow.com/questions/15987712/handle-a-paste-event-in-c-sharp
