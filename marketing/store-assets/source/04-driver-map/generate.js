const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '../..');
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const fonts = path.resolve(root, '../../assets/fonts');

function page(width, height) {
  const sx = width / 1080;
  const sy = height / 1920;
  const fsScale = Math.min(sx, sy);

  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <style>
    @font-face { font-family: Montserrat; src: url('${path.join(fonts, 'Montserrat-Regular.ttf')}'); font-weight: 400; }
    @font-face { font-family: Montserrat; src: url('${path.join(fonts, 'Montserrat-SemiBold.ttf')}'); font-weight: 800; }
    @font-face { font-family: Lobster; src: url('${path.join(fonts, 'Lobster-Regular.ttf')}'); }
    * { box-sizing: border-box; }
    html, body { width: ${width}px; height: ${height}px; margin: 0; overflow: hidden; }
    body { font-family: Montserrat, Arial, sans-serif; background: #f58d1d; }
    .artboard { position: relative; width: 100%; height: 100%; overflow: hidden; color: #fff; background: #f58d1d; }
    .headline { position: absolute; left: ${72 * sx}px; top: ${78 * sy}px; width: ${820 * sx}px; font-size: ${80 * fsScale}px; line-height: 1.02; font-weight: 800; letter-spacing: -.058em; }
    .phone-wrap { position: absolute; left: ${96 * sx}px; top: ${370 * sy}px; width: ${888 * sx}px; height: ${1538 * sy}px; filter: drop-shadow(0 ${28 * fsScale}px ${44 * fsScale}px rgba(70,28,0,.24)); }
    .phone { position: absolute; inset: 0; overflow: hidden; border-radius: ${46 * fsScale}px ${46 * fsScale}px 0 0; background: #fff; }
    .screen { position: relative; width: 100%; height: 100%; overflow: hidden; background: #f6f2ea; color: #11111f; }
    .map { position: absolute; inset: 0 0 ${255 * sy}px 0; overflow: hidden; background: #eee8df; }
    .water { position: absolute; right: ${-60 * sx}px; top: ${-30 * sy}px; width: ${330 * sx}px; height: ${980 * sy}px; background: #a8d9df; transform: rotate(12deg); opacity: .9; }
    .park { position: absolute; border-radius: ${28 * fsScale}px; background: #b9dfaa; opacity: .85; }
    .park.one { left: ${60 * sx}px; top: ${160 * sy}px; width: ${250 * sx}px; height: ${210 * sy}px; transform: rotate(-12deg); }
    .park.two { left: ${425 * sx}px; top: ${665 * sy}px; width: ${300 * sx}px; height: ${250 * sy}px; transform: rotate(8deg); }
    .park.three { left: ${95 * sx}px; top: ${885 * sy}px; width: ${220 * sx}px; height: ${185 * sy}px; transform: rotate(15deg); }
    .road { position: absolute; height: ${30 * sy}px; border-radius: 999px; background: #fff; box-shadow: 0 0 0 ${5 * fsScale}px #dad7cf; opacity: .98; }
    .road.a { left: ${-80 * sx}px; top: ${155 * sy}px; width: ${980 * sx}px; transform: rotate(28deg); }
    .road.b { left: ${40 * sx}px; top: ${360 * sy}px; width: ${980 * sx}px; transform: rotate(-19deg); }
    .road.c { left: ${-120 * sx}px; top: ${650 * sy}px; width: ${1080 * sx}px; transform: rotate(9deg); }
    .road.d { left: ${250 * sx}px; top: ${120 * sy}px; width: ${950 * sx}px; transform: rotate(82deg); }
    .road.e { left: ${-80 * sx}px; top: ${835 * sy}px; width: ${830 * sx}px; transform: rotate(-35deg); }
    .main-road { position: absolute; left: ${-110 * sx}px; top: ${990 * sy}px; width: ${1150 * sx}px; height: ${58 * sy}px; border-radius: 999px; background: #f3b36d; box-shadow: 0 0 0 ${7 * fsScale}px #e19b55; transform: rotate(-10deg); }
    .rail { position: absolute; left: ${-90 * sx}px; top: ${515 * sy}px; width: ${1080 * sx}px; height: ${42 * sy}px; background: repeating-linear-gradient(90deg, #5f6266 0 ${18 * sx}px, #777b80 ${18 * sx}px ${33 * sx}px); transform: rotate(9deg); opacity: .88; }
    .label { position: absolute; color: #6f7177; font-size: ${23 * fsScale}px; font-weight: 800; opacity: .7; }
    .label.a { left: ${120 * sx}px; top: ${250 * sy}px; transform: rotate(28deg); }
    .label.b { right: ${135 * sx}px; top: ${410 * sy}px; transform: rotate(-18deg); }
    .label.c { left: ${350 * sx}px; top: ${725 * sy}px; color: #4973c2; font-size: ${27 * fsScale}px; }
    .route { position: absolute; left: ${226 * sx}px; top: ${612 * sy}px; width: ${330 * sx}px; height: ${390 * sy}px; overflow: visible; opacity: .98; }
    .route-casing { fill: none; stroke: rgba(255,255,255,.92); stroke-width: ${22 * fsScale}px; stroke-linecap: round; stroke-linejoin: round; }
    .route-shadow { fill: none; stroke: rgba(15,15,45,.14); stroke-width: ${25 * fsScale}px; stroke-linecap: round; stroke-linejoin: round; }
    .route-line { fill: none; stroke: #1689ff; stroke-width: ${11 * fsScale}px; stroke-linecap: round; stroke-linejoin: round; }
    .route-start { position: absolute; left: ${427 * sx}px; top: ${622 * sy}px; width: ${70 * sx}px; height: ${70 * sx}px; border-radius: 50%; border: ${7 * fsScale}px solid #fff; background: #1689ff; box-shadow: 0 ${8 * fsScale}px ${18 * fsScale}px rgba(22,137,255,.24); }
    .route-start:after { content: ''; position: absolute; left: 50%; top: 50%; width: ${18 * sx}px; height: ${18 * sx}px; border-radius: 50%; background: #fff; transform: translate(-50%, -50%); }
    .route-end { position: absolute; left: ${247 * sx}px; top: ${941 * sy}px; width: ${46 * sx}px; height: ${46 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: ${12 * fsScale}px; background: #8a5512; color: #fff; font-size: ${26 * fsScale}px; font-weight: 800; box-shadow: 0 ${7 * fsScale}px ${15 * fsScale}px rgba(80,46,10,.2); }
    .bike { position: absolute; left: ${492 * sx}px; top: ${535 * sy}px; z-index: 3; width: ${122 * sx}px; height: ${86 * sy}px; filter: drop-shadow(0 ${8 * fsScale}px ${10 * fsScale}px rgba(0,0,0,.12)); }
    .bike * { vector-effect: non-scaling-stroke; }
    .pin { position: absolute; display: flex; align-items: center; justify-content: center; }
    .target { left: ${430 * sx}px; top: ${625 * sy}px; width: ${64 * sx}px; height: ${64 * sx}px; border-radius: 50%; border: ${7 * fsScale}px solid #050509; background: #fff; }
    .target:after { content: ''; width: ${18 * sx}px; height: ${18 * sx}px; border-radius: 50%; background: #050509; }
    .offline { position: absolute; left: 50%; top: ${72 * sy}px; z-index: 5; transform: translateX(-50%); padding: ${28 * sy}px ${54 * sx}px; border-radius: ${34 * fsScale}px; background: #ff3029; color: #fff; font-size: ${34 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.025em; box-shadow: 0 ${10 * fsScale}px ${22 * fsScale}px rgba(124,20,12,.24); }
    .avatar { position: absolute; right: ${58 * sx}px; top: ${210 * sy}px; z-index: 5; width: ${118 * sx}px; height: ${118 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #fff; color: #1b7994; font-size: ${58 * fsScale}px; box-shadow: 0 ${8 * fsScale}px ${20 * fsScale}px rgba(0,0,0,.16); }
    .bottom-panel { position: absolute; left: 0; right: 0; bottom: ${170 * sy}px; height: ${150 * sy}px; display: flex; align-items: center; gap: ${26 * sx}px; padding: 0 ${48 * sx}px; background: #fff; box-shadow: 0 -${10 * fsScale}px ${26 * fsScale}px rgba(0,0,0,.055); }
    .sync { color: #1689ff; font-size: ${46 * fsScale}px; font-weight: 800; }
    .searching { color: #11111f; font-size: ${44 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.048em; }
    .nav { position: absolute; left: 0; right: 0; bottom: 0; height: ${170 * sy}px; display: grid; grid-template-columns: repeat(4, 1fr); align-items: center; background: rgba(255,255,255,.98); box-shadow: 0 -${12 * fsScale}px ${30 * fsScale}px rgba(0,0,0,.055); }
    .nav-item { position: relative; text-align: center; color: #aaa8ad; font-size: ${25 * fsScale}px; line-height: 1.16; font-weight: 400; }
    .nav-icon { display: block; width: ${54 * sx}px; height: ${54 * sx}px; margin: 0 auto ${5 * sy}px; }
    .nav-icon svg { width: 100%; height: 100%; fill: none; stroke: currentColor; stroke-width: 2.35; stroke-linecap: round; stroke-linejoin: round; }
    .nav-item.active { color: #ff6f43; }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="headline">Des courses<br>près de vous</div>
    <div class="phone-wrap">
      <section class="phone" aria-label="Recherche de courses livreur Dineroo">
        <div class="screen">
          <div class="map">
            <div class="water"></div>
            <div class="park one"></div><div class="park two"></div><div class="park three"></div>
            <div class="road a"></div><div class="road b"></div><div class="road c"></div><div class="road d"></div><div class="road e"></div>
            <div class="main-road"></div><div class="rail"></div>
            <div class="label a">Route de Donka</div><div class="label b">Corniche</div><div class="label c">Conakry</div>
            <svg class="route" viewBox="0 0 330 390" aria-hidden="true">
              <path class="route-shadow" d="M246 24 C296 74 292 123 237 155 C184 187 194 230 146 254 C100 278 88 323 38 365" />
              <path class="route-casing" d="M246 24 C296 74 292 123 237 155 C184 187 194 230 146 254 C100 278 88 323 38 365" />
              <path class="route-line" d="M246 24 C296 74 292 123 237 155 C184 187 194 230 146 254 C100 278 88 323 38 365" />
            </svg>
            <svg class="bike" viewBox="0 0 150 105" aria-hidden="true">
              <circle cx="35" cy="73" r="24" fill="#f7f7f7" stroke="#50545a" stroke-width="7" />
              <circle cx="113" cy="73" r="24" fill="#f7f7f7" stroke="#50545a" stroke-width="7" />
              <path d="M35 73 L62 43 L82 73 L55 73 L76 43 L103 43 L113 73" fill="none" stroke="#e53935" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" />
              <path d="M73 30 L83 18 M73 30 L68 43 M102 42 L114 31" fill="none" stroke="#50545a" stroke-width="7" stroke-linecap="round" />
              <circle cx="78" cy="77" r="8" fill="#50545a" />
            </svg>
            <div class="route-start"></div><div class="route-end">▣</div>
            <div class="pin target"></div>
          </div>
          <div class="offline">Passer hors ligne</div>
          <div class="avatar">🎧</div>
          <div class="bottom-panel"><div class="sync">↻</div><div class="searching">Recherche de courses</div></div>
          <nav class="nav">
            <div class="nav-item active"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M4.5 11.2 12 5l7.5 6.2"/><path d="M6.5 10.5v8h11v-8"/><path d="M10 18.5v-4h4v4"/></svg></span>Accueil</div>
            <div class="nav-item"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M7 5h10v14H7z"/><path d="M9.5 8.5h5"/><path d="M9.5 12h5"/><path d="M9.5 15.5h3.5"/></svg></span>Historique</div>
            <div class="nav-item"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M5 18h14"/><path d="M7 15l4-4 3 3 4-6"/><path d="M15 8h3v3"/></svg></span>Gains</div>
            <div class="nav-item"><span class="nav-icon"><svg viewBox="0 0 24 24"><circle cx="12" cy="8.5" r="2.6"/><path d="M7 19c.8-3.2 3-4.6 5-4.6s4.2 1.4 5 4.6"/></svg></span>Profil</div>
          </nav>
        </div>
      </section>
    </div>
  </main>
</body>
</html>`;
}

function render(width, height, out) {
  const file = path.join(__dirname, `.render-${width}x${height}.html`);
  fs.writeFileSync(file, page(width, height));
  execFileSync(chrome, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    `--window-size=${width},${height}`,
    `--screenshot=${out}`,
    `file://${file}`,
  ], { stdio: 'ignore' });
  fs.rmSync(file, { force: true });
}

render(1080, 1920, path.join(root, 'android', '04-driver-map.png'));
render(1242, 2688, path.join(root, 'ios', '04-driver-map.png'));
render(2048, 2732, path.join(root, 'ipad-13', '04-driver-map.png'));

console.log('Generated premium draft 04-driver-map');
