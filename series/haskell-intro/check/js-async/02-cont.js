// コールバックを継続モナドで包む。Haskell 側の
//   readFileC name = Cont (readFileT name abort)
// と同じことを JavaScript でやる。
const fs = require('fs');

// newtype Cont r a = Cont { runCont :: (a -> r) -> r }
const Cont = run => ({ run });

// return :: a -> Cont r a
const ret = x => Cont(k => k(x));

// (>>=) :: Cont r a -> (a -> Cont r b) -> Cont r b
const bind = (m, f) => Cont(k => m.run(x => f(x).run(k)));

// Haskell 1.0 の 2 継続版
const readFileT = path => (fail, succ) =>
    fs.readFile(path, 'utf8', (err, data) => (err ? fail(err) : succ(data)));

// 失敗継続を固定すると Cont になる（Haskell 1.0 の abort に相当）
const abort = e => console.error('  error:', e.message);
const readFileC = path => Cont(k => readFileT(path)(abort, k));

const putStrLn = s => Cont(k => (console.log('  ' + s), k()));

console.log('=== bind で連結 ===');
bind(readFileC('hello.txt'), a =>
    bind(readFileC('world.txt'), b => putStrLn(a.trim() + ' ' + b.trim())),
).run(() => {});

// Promise は「継続を後で渡せるようにした Cont」に相当する。
// then が bind、resolve が return。ただし答えの型が固定されている。
const readFileP = path => new Promise((res, rej) => readFileT(path)(rej, res));

setTimeout(() => {
    console.log('=== Promise の then で連結（形は同じ） ===');
    readFileP('hello.txt').then(a =>
        readFileP('world.txt').then(b => console.log('  ' + a.trim() + ' ' + b.trim())),
    );
}, 100);
