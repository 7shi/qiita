// Node.js の readFile はコールバックを取る。これが継続そのもの。
const fs = require('fs');

// readFile(path, enc, cb) から path と enc を部分適用すると
//     (cb) => void
// になる。Haskell の (a -> r) -> r と同じ形（r は void）。
const readFileK = path => cb => fs.readFile(path, 'utf8', cb);

// Node の慣習 (err, data) は、失敗継続と成功継続を
// 1 つのコールバックに畳んで先頭引数で見分けているだけ。
// Haskell 1.0 の readFile :: Name -> FailCont -> StrCont -> Behaviour では
// 2 つの継続に分かれていた。分けて書くとこうなる。
const readFileT = path => (fail, succ) =>
    fs.readFile(path, 'utf8', (err, data) => (err ? fail(err) : succ(data)));

console.log('=== コールバックのネスト（いわゆる callback hell） ===');
readFileT('hello.txt')(
    e => console.error('  error:', e.message),
    a =>
        readFileT('world.txt')(
            e => console.error('  error:', e.message),
            b =>
                readFileT('missing.txt')(
                    e => console.log('  ' + a.trim() + ' ' + b.trim() + ' / ' + e.code),
                    c => console.log('  ' + a.trim() + ' ' + b.trim() + ' ' + c.trim()),
                ),
        ),
);

// 部分適用した形をそのまま使う例。継続を後から渡せる＝継続が値になっている。
const k = readFileK('hello.txt');
setTimeout(() => k((err, data) => console.log('=== 継続を後から渡す ===\n  ' + data.trim())), 100);
