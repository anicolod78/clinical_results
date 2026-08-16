// Server statico minimo per provare la build web.
//
// Serve build/web senza dipendenze esterne. Il server di sviluppo di Flutter
// (`flutter run -d web-server`) attende una connessione al servizio di debug
// che in questo ambiente non si stabilisce, e l'applicazione non parte mai.
// Qui si serve il bundle già compilato, senza DDC né debugger di mezzo.
//
//   node tool/serve_web.js [porta]

const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', 'build', 'web');
const port = Number(process.argv[2] || 8090);

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.bin': 'application/octet-stream',
  '.symbols': 'application/octet-stream',
};

http
  .createServer((req, res) => {
    const requested = decodeURIComponent(req.url.split('?')[0]);
    let file = path.join(root, requested === '/' ? 'index.html' : requested);

    // Nessuna uscita dalla cartella servita.
    if (!file.startsWith(root)) {
      res.writeHead(403).end('Forbidden');
      return;
    }
    if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      file = path.join(root, 'index.html');
    }

    const type = types[path.extname(file).toLowerCase()] ||
        'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': type,
      // Gli stessi requisiti che Flutter chiede per la memoria condivisa,
      // usata dal modulo WebAssembly di SQLite.
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
      // Permette al test che gira nel browser di scaricare sqlite3mc.wasm
      // da qui: il server dei test sta su un'altra porta, quindi su
      // un'origine diversa.
      'Access-Control-Allow-Origin': '*',
      'Cross-Origin-Resource-Policy': 'cross-origin',
      'Cache-Control': 'no-store',
    });
    fs.createReadStream(file).pipe(res);
  })
  .listen(port, '127.0.0.1', () => {
    console.log(`build/web servita su http://127.0.0.1:${port}`);
  });
