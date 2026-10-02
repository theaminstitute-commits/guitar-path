// Builds Guitar Path from app/guitar-path.html (the single source of the game):
//   index.html                    full page for GitHub Pages (committed, so the web link always matches main)
//   android/assets/index.html     the page the Android WebView loads (see android/build-apk.ps1)
//   dist/guitar-path-linux/       the Linux bundle: page + launcher, installer, icon, README
//   dist/GuitarPath-linux.zip     that bundle zipped (Windows only: needs %WINDIR%\System32\tar.exe)
// Usage: node tools/build.js
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const ROOT = path.join(__dirname, '..');
const page = fs.readFileSync(path.join(ROOT, 'app', 'guitar-path.html'), 'utf8');

// app/guitar-path.html has no <html>/<head>/<body> (the claude.ai artifact viewer adds those),
// so wrap it: everything up to the end of the <style> block goes in <head>.
function wrap(viewport) {
  const k = page.indexOf('</style>') + '</style>'.length;
  if (k < '</style>'.length) throw new Error('no </style> in app/guitar-path.html');
  return '<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n' +
    `<meta name="viewport" content="${viewport}">\n` +
    page.slice(0, k) + '\n</head>\n<body>\n' + page.slice(k).replace(/^\n/, '') + '\n</body>\n</html>\n';
}
const write = (rel, text) => { const p = path.join(ROOT, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); return rel; };
const out = [];

out.push(write('index.html', wrap('width=device-width, initial-scale=1, viewport-fit=cover')));
out.push(write('android/assets/index.html', wrap('width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover')));

const LIN = path.join('dist', 'guitar-path-linux');
fs.rmSync(path.join(ROOT, 'dist'), { recursive: true, force: true });
out.push(write(path.join(LIN, 'guitar-path.html'), wrap('width=device-width, initial-scale=1, viewport-fit=cover')));
for (const f of fs.readdirSync(path.join(ROOT, 'linux'))) {
  out.push(write(path.join(LIN, f), fs.readFileSync(path.join(ROOT, 'linux', f), 'utf8').replace(/\r\n/g, '\n')));
}

// Windows' own tar writes a real zip with -a (Git Bash's GNU tar would silently write a tar instead).
const tar = process.env.WINDIR && path.join(process.env.WINDIR, 'System32', 'tar.exe');
if (tar && fs.existsSync(tar)) {
  execFileSync(tar, ['-a', '-c', '-f', 'GuitarPath-linux.zip', 'guitar-path-linux'], { cwd: path.join(ROOT, 'dist') });
  out.push(path.join('dist', 'GuitarPath-linux.zip'));
}

new Function(page.split('<script>')[1].split('</script>')[0]); // fails the build if the game script doesn't parse
const version = (page.match(/Prototype (v[\d.]+)/) || [])[1] || '?';
console.log(`Guitar Path ${version}\n` + out.map(f => '  ' + f.replace(/\\/g, '/')).join('\n'));
