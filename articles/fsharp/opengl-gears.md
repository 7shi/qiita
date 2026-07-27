---
coediting: false
comments_count: 0
created_at: '2017-01-20T00:37:01+09:00'
id: efdf0ae04a24bc1b7623
likes_count: 3
private: false
reactions_count: 0
stocks_count: 2
tags:
- name: C
  versions: []
- name: F#
  versions: []
- name: OpenGL
  versions: []
title: F#にOpenGLの歯車デモを移植
updated_at: '2017-01-31T14:04:40+09:00'
url: https://qiita.com/7shi/items/efdf0ae04a24bc1b7623
slide: false
---

F#でOpenGLを使うことができたので、デモプログラムを移植してみました。

* [OpenGL - Mesademos](https://www.opengl.org/archives/resources/code/samples/glut_examples/mesademos/mesademos.html) ([gears.c](https://www.opengl.org/archives/resources/code/samples/glut_examples/mesademos/gears.c))

![gears.gif](https://qiita-image-store.s3.amazonaws.com/0/32057/7ab38dec-3bc5-f744-b28a-a49c8612255d.gif)

シリーズの記事です。

* [F#でOpenGL](http://qiita.com/7shi/items/029343420518b6884d7c)
* F#にOpenGLの歯車デモを移植 ← この記事
* [OpenGLでオフスクリーンレンダリング](http://qiita.com/7shi/items/b02f2e45b49c0314fd12)

関連するコードをまとめたリポジトリです。

* https://bitbucket.org/7shi/fsgl

<font color="red">**【注意】**</font>この記事のサンプルは[レガシーなAPI](https://www.khronos.org/opengl/wiki/Legacy_OpenGL)を使っています。新しいAPIへの移行は機会を改めることにして、今回はレガシーなまま進めます。

# 移植

前回の記事で作ったOpenGLサポートに足りない機能を補いながら移植を進めました。

完成したコードを説明します。

* [GL7.fsx](https://bitbucket.org/7shi/fsgl/src/tip/GL7.fsx)
* [GL7.GL.fsx](https://bitbucket.org/7shi/fsgl/src/tip/GL7.GL.fsx)
* [gears.fsx](https://bitbucket.org/7shi/fsgl/src/tip/gears.fsx)

※ GL7 という名前は適当で、7は七誌の七です。

## コンテキスト

元のC言語の `main()` から初期化部を抜粋します。

```c:gears.c
main(int argc, char *argv[])
{
  （略）
  glutCreateWindow("Gears");
  init();
```

GLUTではコンテキストが1つしかないため切り替える必要がありませんが、GLFormでは必要に応じて切り替える方針です。

`init()` ではOpenGLの関数を使用しています。

```c:gears.c
static void
init(void)
{
  （略）
  glLightfv(GL_LIGHT0, GL_POSITION, pos);
  glEnable(GL_CULL_FACE);
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glEnable(GL_DEPTH_TEST);
```

GLFormではPaintだけ特別扱いでコンテキストを切り替えています。必要に応じてハンドラを追加していてはきりがないため、Paint以外では必要に応じてコンテキストを切り替えるようにします。

スコープアウト時にコンテキストを手放すため、後片付け用のクラスを実装します。

※ [RAII](https://ja.wikipedia.org/wiki/RAII)は手法の略語です。

```fsharp
type RAII(dtor) =
    interface IDisposable with override x.Dispose() = dtor()
```

`RAII`を使ってスコープ内だけでコンテキストを取得するメソッドを実装します。

```fsharp
    member x.MakeCurrent() =
        ignore <| wglMakeCurrent(hDC, hGLRC)
        new RAII(fun () -> ignore <| wglMakeCurrent(0n, 0n))
```

F#の初期化部で`MakeCurrent`を使います。GLUTでは起動直後にReshapeイベントが発生しますがWindows Formsでは発生しないため、明示的にハンドラを呼びます。

```fsharp:gears.fsx
    let f = new GLForm(Text = "Gears")
    f.Load.Add <| fun _ ->
        use raii = f.MakeCurrent()
        init()
        reshape f
```

## イベントハンドリング

`main()` でGUIのイベントハンドラを設定しています。

```c:gears.c
main(int argc, char *argv[])
{
  （略）
  glutDisplayFunc(draw);
  glutReshapeFunc(reshape);
  glutKeyboardFunc(key);
  glutSpecialFunc(special);
  glutVisibilityFunc(visible);
```

`reshape()` はウィンドウのリサイズを処理します。ここでもOpenGLの関数が使われています。

```c:gears.c
/* new window size or exposure */
static void
reshape(int width, int height)
{
  GLfloat h = (GLfloat) height / (GLfloat) width;

  glViewport(0, 0, (GLint) width, (GLint) height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glFrustum(-1.0, 1.0, -h, h, 5.0, 60.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glTranslatef(0.0, 0.0, -40.0);
}
```

イベントハンドラで必要に応じて`MakeCurrent`でコンテキストを取得します。GLUTとはハンドラの引数が異なるため、引数を調整してコールバックします。

```fsharp:gears.fsx
    f.Paint.Add <| fun _ ->
        draw f
        idle f
    f.Resize.Add <| fun _ ->
        use raii = f.MakeCurrent()
        reshape f
    f.KeyPress.Add <| fun e ->
        key f e.KeyChar
    f.KeyDown.Add <| fun e ->
        special e.KeyCode
```

GLUTではVisibilityイベントで非表示時に再描画要求を止めています。Windows Formsでは非表示時にPaintイベントが発生しないため自然と止まるためVisibilityイベントは移植する必要がありません。

これでGLUTとGLFormのすり合わせは完了です。後は文法を書き替えれば移植できます。

## float32

F#では数値型の自動キャストは行われないため、必要に応じてキャストを追加します。

```c:gears.c
#ifndef M_PI
#define M_PI 3.14159265
#endif
```

```fsharp:gears.fsx
let M_PI = float32 Math.PI
```

そこに注意すれば後はほとんど機械的な書き替えです。

```c:gears.c
static void
gear(GLfloat inner_radius, GLfloat outer_radius, GLfloat width,
  GLint teeth, GLfloat tooth_depth)
{
  （略）
  /* draw front face */
  glBegin(GL_QUAD_STRIP);
  for (i = 0; i <= teeth; i++) {
    angle = i * 2.0 * M_PI / teeth;
    glVertex3f(r0 * cos(angle), r0 * sin(angle), width * 0.5);
    glVertex3f(r1 * cos(angle), r1 * sin(angle), width * 0.5);
    glVertex3f(r0 * cos(angle), r0 * sin(angle), width * 0.5);
    glVertex3f(r1 * cos(angle + 3 * da), r1 * sin(angle + 3 * da), width * 0.5);
  }
  glEnd();
```

```fsharp:gears.fsx
let gear inner_radius outer_radius width teeth tooth_depth =
    （略）
    // draw front face
    glBegin(GL_QUAD_STRIP)
    for i = 0 to teeth do
        let angle = float32 i * 2.0f * M_PI / float32 teeth
        glVertex3f(r0 * cos(angle), r0 * sin(angle), width * 0.5f)
        glVertex3f(r1 * cos(angle), r1 * sin(angle), width * 0.5f)
        glVertex3f(r0 * cos(angle), r0 * sin(angle), width * 0.5f)
        glVertex3f(r1 * cos(angle + 3.f * da), r1 * sin(angle + 3.f * da), width * 0.5f)
    glEnd()
```

## キーイベント

キーイベントで終了するようになっていますが、いきなり `exit` は行儀が悪いので、GLFormを渡して閉じるようにします。

```c:gears.c
/* change view angle, exit upon ESC */
/* ARGSUSED1 */
static void
key(unsigned char k, int x, int y)
{
  switch (k) {
  case 'z':
    view_rotz += 5.0;
    break;
  case 'Z':
    view_rotz -= 5.0;
    break;
  case 27:  /* Escape */
    exit(0);
    break;
  default:
    return;
  }
  glutPostRedisplay();
}
```

別の所で再描画を呼ぶため `glutPostRedisplay()` は移植から省きます。

```fsharp:gears.fsx
// change view angle, exit upon ESC
let key (f:GLForm) = function
| 'z' -> view_rotz <- view_rotz + 5.0f
| 'Z' -> view_rotz <- view_rotz - 5.0f
| '\u001b' (* Escape *) -> f.Close()
| _ -> ()
```

F#の構文は縦に長くならないのですっきりしています。別の例も見ます。

```c:gears.c
/* change view angle */
/* ARGSUSED1 */
static void
special(int k, int x, int y)
{
  switch (k) {
  case GLUT_KEY_UP:
    view_rotx += 5.0;
    break;
  case GLUT_KEY_DOWN:
    view_rotx -= 5.0;
    break;
  case GLUT_KEY_LEFT:
    view_roty += 5.0;
    break;
  case GLUT_KEY_RIGHT:
    view_roty -= 5.0;
    break;
  default:
    return;
  }
  glutPostRedisplay();
}
```

```fsharp:gears.fsx
// change view angle
let special = function
| Keys.Up    -> view_rotx <- view_rotx + 5.0f
| Keys.Down  -> view_rotx <- view_rotx - 5.0f
| Keys.Left  -> view_roty <- view_roty + 5.0f
| Keys.Right -> view_roty <- view_roty - 5.0f
| _ -> ()
```

## アニメーション

画面描画後にすぐ再描画を要求することでアニメーションしています。

```fsharp:gears.fsx
    f.Paint .Add <| fun _ ->
        draw()
        idle f
```

オリジナルのgearsが開発されたときとはマシン性能が異なるため、元の回転角度では速過ぎます。そのため回転角度を修正します。

```c:gears.c
static void
idle(void)
{
  angle += 2.0;
  glutPostRedisplay();
}
```

```fsharp:gears.fsx
let idle (f:GLForm) =
    angle <- angle + 0.1f  // 2.0f
    f.Invalidate()
```

移植時に注意した点は以上です。

# 感想

GLUTではなく慣れたWindows FormsをOpenGLと組み合わせるのはなかなか快適です。既存の非OpenGL資産との組み合わせも柔軟にできます。もっと早く知っていれば必要以上にGDI+で消耗しなかったのにとも思いましたが、まあ今からでも遅すぎることはないでしょう。

# その他

定番の解説書[Red Bookのサンプル](https://www.opengl.org/archives/resources/code/samples/redbook/)をいくつか移植してみました。

<blockquote class="twitter-tweet" data-conversation="none" data-lang="ja"><p lang="ja" dir="ltr">簡単なサンプルを2つ移植しました。 <a href="https://t.co/VYySVpnzMn">https://t.co/VYySVpnzMn</a> <a href="https://t.co/9NKIu9qhPw">pic.twitter.com/9NKIu9qhPw</a></p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/823481161468940288">2017年1月23日</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet" data-conversation="none" data-lang="ja"><p lang="ja" dir="ltr">FreeGLUTから必要な関数だけ移植して、球やトーラスを表示するサンプルを移植した。GLUTありきだと気付かなかったけど、こんなに手間が掛かるんだ… <a href="https://t.co/n3AnhQGvnG">https://t.co/n3AnhQGvnG</a> <a href="https://t.co/DXHefpWnX6">pic.twitter.com/DXHefpWnX6</a></p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/824933436137709568">2017年1月27日</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

<blockquote class="twitter-tweet" data-conversation="none" data-lang="ja"><p lang="ja" dir="ltr">移植してみたけどちょっとシンプル過ぎる（教材目的で取っ掛かりを提供するだけなので、これで良いのだろうけど）。拡大して塗りつぶしをやめたら、ワイヤーフレームのトーラスが現れた。 <a href="https://t.co/5H2RjsfZ0r">https://t.co/5H2RjsfZ0r</a> <a href="https://t.co/Pn6cCXWvaq">pic.twitter.com/Pn6cCXWvaq</a></p>&mdash; 七誌 (@7shi) <a href="https://twitter.com/7shi/status/825905507927941124">2017年1月30日</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
