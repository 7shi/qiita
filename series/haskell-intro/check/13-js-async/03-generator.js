// 双方向ジェネレーター + ドライバー = async/await。
// async/await が言語に入る前、これが実際に使われていた実装方式
// （co ライブラリ、babel の regenerator など）。
//
// Haskell 側の
//   drive :: (o -> IO (Maybe i)) -> Gen i o -> IO ()
// （check/13-gen-io/GenBiIO.hs）と同じ形。
const fs = require('fs');

const readFileK = path => k => fs.readFile(path, 'utf8', (err, data) => k(err, data));

// ドライバー。ジェネレーターが yield した「継続を受け取る関数」を実行し、
// 結果を it.next(結果) で渡して再開する。
//
// it.next(x) が双方向コルーチンそのもの。yield の戻り値が
// 「次の再開時に渡された値」になる ＝ 構成案 6 (a) の yield と同じ。
function drive(genFn) {
    const it = genFn();
    function step(err, value) {
        if (err) return it.throw(err);
        const { value: action, done } = it.next(value);
        if (done) return;
        action(step); // action は (k) => void ＝ Cont の中身
    }
    step();
}

console.log('=== ジェネレーター + ドライバー ===');
drive(function* () {
    const a = yield readFileK('hello.txt');
    const b = yield readFileK('world.txt');
    console.log('  ' + a.trim() + ' ' + b.trim());
    try {
        yield readFileK('missing.txt');
    } catch (e) {
        console.log('  caught: ' + e.code);
    }
});

// yield している値をログに出して、生産と消費が交互に進むのを見る
setTimeout(() => {
    console.log('=== 交互に進んでいることの確認 ===');
    const trace = genFn => {
        const it = genFn();
        function step(err, value) {
            if (err) return it.throw(err);
            const { value: action, done } = it.next(value);
            if (done) return console.log('  [drv] done');
            console.log('  [drv] got an action, running it');
            action((e, v) => {
                console.log('  [drv] resume with ' + JSON.stringify(v && v.trim()));
                step(e, v);
            });
        }
        step();
    };
    trace(function* () {
        console.log('  [gen] request 1');
        const a = yield readFileK('hello.txt');
        console.log('  [gen] received ' + JSON.stringify(a.trim()));
        console.log('  [gen] request 2');
        const b = yield readFileK('world.txt');
        console.log('  [gen] received ' + JSON.stringify(b.trim()));
    });
}, 100);
