---
coediting: false
comments_count: 0
created_at: '2015-05-05T11:48:14+09:00'
id: 18d15f8238c074a2e8fc
likes_count: 2
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: NetBeans
  versions: []
- name: msys2
  versions: []
title: NetBeansからMSYS2のgccを使う
updated_at: '2015-11-17T17:58:20+09:00'
url: https://qiita.com/7shi/items/18d15f8238c074a2e8fc
slide: false
---

NetBeansからMSYS2のgccを使うといくつか問題が起きます。

* NetBeansがMSYS2を自動認識しない
* パスが通らない
* 文字化けする

パスと環境変数を設定するラッパーを用意することで解決を試みました。

※ 公式な手段があるのかもしれませんが、不明なので力技です。

# ラッパー

次のようなファイルを作成します。

※ MSYS2のインストール先が異なる場合は`USR`を適宜修正してください。

```make-wrap.cpp
#include <stdlib.h>
#include <unistd.h>
#include <string>
#include <vector>

#define USR "C:\\msys64\\usr"

std::string lower(const std::string &s) {
	std::string ret;
	for (int i = 0; i < s.size(); i++) {
		char ch = s[i];
		if ('A' <= ch && ch <= 'Z') ch += 32;
		ret += ch;
	}
	return ret;
}

int main(int argc, const char *argv[], const char *envp[]) {
	const char *make = USR"\\bin\\make.exe";
	argv[0] = make;
	std::vector<const char *> envs;
	std::string path;
	for (int i = 0; envp[i]; i++) {
		std::string e = envp[i];
		std::string e5 = lower(e.substr(0, 5));
		if (e5 == "path=") {
			path = "PATH="USR"\\bin;"USR"\\local\\bin;" + e.substr(5);
			envs.push_back(path.c_str());
		} else if (e5 != "lang=") {
			envs.push_back(envp[i]);
		}
	}
	envs.push_back("LANG=C");
	envs.push_back(NULL);
	return execve(make, const_cast<char **>(argv), const_cast<char **>(&envs[0]));
}
```

コンパイルしてMSYS2のルートに置きます。DLLに依存しないよう、Win32ネイティブでスタティックリンクします。

```text
$ x86_64-w64-mingw32-g++ -static -s -o /make-wrap make-wrap.cpp
```

※ 要 `pacman -S mingw-w64-cross-gcc`

# NetBeansの設定

NetBeansで環境を設定します。

## プラグインの確認

C/C++プラグインがインストールされているか確認します。

ツール → プラグイン

![NetBeans1.png](https://qiita-image-store.s3.amazonaws.com/0/32057/7bd87582-0a2b-440b-5503-a6a3e95560a2.png)

インストールされていなければ、インストールしてください。

![NetBeans2.png](https://qiita-image-store.s3.amazonaws.com/0/32057/633d469c-a5f7-19b5-fcd3-95c7ba1678db.png)

## プラグインの設定

ツール → オプション → C/C++ → [追加]

![NetBeans3.png](https://qiita-image-store.s3.amazonaws.com/0/32057/446d89c8-7821-d441-a867-dad44fd460c5.png)

ベース・ディレクトリとツール・コレクション・ファミリを選択 → [OK]

![NetBeans4.png](https://qiita-image-store.s3.amazonaws.com/0/32057/2e88930a-fce5-09bc-d68f-37027655cff4.png)

※ CygwinやMinGWを選択するとうまく動かないためInterixを指定しています。

CコンパイラとC++コンパイラとmakeコマンド（先ほど作成したラッパー）を指定

![NetBeans5.png](https://qiita-image-store.s3.amazonaws.com/0/32057/a494e7b1-1462-dee9-5746-9cf713f4e3c8.png)

コード支援 → インクルード・ディレクトリで`...\usr\usr\include`を変更 → 重複する`\usr`を取り除く

![NetBeans6.png](https://qiita-image-store.s3.amazonaws.com/0/32057/b026ca01-5803-3a3d-52a0-b2fef8a154a1.png)

C++コンパイラについても同様に処置 → [OK]

![NetBeans7.png](https://qiita-image-store.s3.amazonaws.com/0/32057/f916a784-c20b-fbc6-f014-40bb256fd4ed.png)

以上で設定は完了です。
