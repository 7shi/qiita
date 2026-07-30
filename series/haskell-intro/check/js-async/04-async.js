// async/await 版。03-generator.js と同じ内容で、
// yield → await、ドライバー → 言語組み込み、になっただけ。
const fs = require('fs');

const readFileP = path =>
    new Promise((res, rej) => fs.readFile(path, 'utf8', (err, data) => (err ? rej(err) : res(data))));

async function main() {
    console.log('=== async/await ===');
    const a = await readFileP('hello.txt');
    const b = await readFileP('world.txt');
    console.log('  ' + a.trim() + ' ' + b.trim());
    try {
        await readFileP('missing.txt');
    } catch (e) {
        console.log('  caught: ' + e.code);
    }
}

main();
