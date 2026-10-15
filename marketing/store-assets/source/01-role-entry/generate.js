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
    body { font-family: Montserrat, Arial, sans-serif; background: #fff8ef; }
    .artboard { position: relative; width: 100%; height: 100%; overflow: hidden; color: #11111f; background: linear-gradient(180deg, #fffaf2 0%, #fff2e2 42%, #f58d1d 42.2%, #f58d1d 100%); }
    .soft-circle { position: absolute; right: ${-190 * sx}px; top: ${-125 * sy}px; width: ${520 * sx}px; height: ${520 * sx}px; border-radius: 50%; background: rgba(245,141,29,.14); }
    .soft-band { position: absolute; left: ${-160 * sx}px; top: ${315 * sy}px; width: ${1280 * sx}px; height: ${245 * sy}px; background: rgba(245,141,29,.08); transform: rotate(-10deg); }
    .headline { position: absolute; left: ${72 * sx}px; top: ${78 * sy}px; width: ${850 * sx}px; font-size: ${80 * fsScale}px; line-height: 1.02; font-weight: 800; letter-spacing: -.058em; }
    .phone-wrap { position: absolute; left: ${96 * sx}px; top: ${370 * sy}px; width: ${888 * sx}px; height: ${1538 * sy}px; filter: drop-shadow(0 ${28 * fsScale}px ${44 * fsScale}px rgba(70,28,0,.24)); }
    .phone { position: absolute; inset: 0; overflow: hidden; border-radius: ${46 * fsScale}px ${46 * fsScale}px 0 0; background: #f58d1d; }
    .screen { position: relative; width: 100%; height: 100%; overflow: hidden; background: linear-gradient(180deg, #fb8c13 0%, #f58d1d 100%); color: #11111f; }
    .app-logo { position: absolute; left: 0; right: 0; top: ${515 * sy}px; text-align: center; font-family: Lobster, cursive; font-size: ${112 * fsScale}px; line-height: 1; letter-spacing: -.03em; color: #fff; }
    .question { position: absolute; left: 0; right: 0; top: ${735 * sy}px; text-align: center; font-size: ${60 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.058em; color: #11111f; }
    .role { position: absolute; left: ${50 * sx}px; right: ${50 * sx}px; height: ${118 * sy}px; display: flex; align-items: center; justify-content: center; border-radius: ${18 * fsScale}px; font-size: ${34 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: .06em; box-shadow: 0 ${6 * fsScale}px ${12 * fsScale}px rgba(60,30,0,.25); }
    .client { top: ${885 * sy}px; background: #fff; color: #15151f; }
    .driver { top: ${1065 * sy}px; background: #ff4b22; color: #fff; }
    .restaurant { position: absolute; left: 50%; bottom: ${145 * sy}px; width: ${435 * sx}px; height: ${76 * sy}px; transform: translateX(-50%); display: flex; align-items: center; justify-content: center; gap: ${18 * sx}px; border-radius: 999px; background: rgba(255,255,255,.20); color: #fff; border: ${2 * fsScale}px solid rgba(255,255,255,.30); font-size: ${25 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: .045em; }
    .store-icon { width: ${34 * sx}px; height: ${34 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: ${8 * fsScale}px; background: rgba(255,255,255,.22); font-size: ${22 * fsScale}px; }
    .glow { position: absolute; left: 50%; top: ${415 * sy}px; width: ${520 * sx}px; height: ${520 * sx}px; transform: translateX(-50%); border-radius: 50%; background: radial-gradient(circle, rgba(255,255,255,.16), rgba(255,255,255,0) 66%); }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="soft-circle"></div>
    <div class="soft-band"></div>
    <div class="headline">Une app,<br>trois espaces</div>
    <div class="phone-wrap">
      <section class="phone" aria-label="Sélection du rôle Dineroo">
        <div class="screen">
          <div class="glow"></div>
          <div class="app-logo">Dineroo</div>
          <div class="question">Qui êtes-vous ?</div>
          <div class="role client">JE SUIS UN CLIENT</div>
          <div class="role driver">JE SUIS UN LIVREUR</div>
          <div class="restaurant"><span class="store-icon">▣</span>ESPACE RESTAURANT</div>
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

render(1080, 1920, path.join(root, 'android', '01-role-entry.png'));
render(1242, 2688, path.join(root, 'ios', '01-role-entry.png'));
render(2048, 2732, path.join(root, 'ipad-13', '01-role-entry.png'));

console.log('Generated premium draft 01-role-entry');
