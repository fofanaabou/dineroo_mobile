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
    .soft-circle { position: absolute; right: ${-190 * sx}px; top: ${-125 * sy}px; width: ${520 * sx}px; height: ${520 * sx}px; border-radius: 50%; background: rgba(255,255,255,.14); }
    .soft-band { position: absolute; left: ${-160 * sx}px; top: ${255 * sy}px; width: ${1280 * sx}px; height: ${245 * sy}px; background: rgba(255,255,255,.08); transform: rotate(-10deg); }
    .headline { position: absolute; left: ${72 * sx}px; top: ${78 * sy}px; width: ${850 * sx}px; font-size: ${80 * fsScale}px; line-height: 1.02; font-weight: 800; letter-spacing: -.058em; }
    .phone-wrap { position: absolute; left: ${96 * sx}px; top: ${370 * sy}px; width: ${888 * sx}px; height: ${1538 * sy}px; filter: drop-shadow(0 ${28 * fsScale}px ${44 * fsScale}px rgba(70,28,0,.24)); }
    .phone { position: absolute; inset: 0; overflow: hidden; border-radius: ${46 * fsScale}px ${46 * fsScale}px 0 0; background: #fff; }
    .screen { position: relative; width: 100%; height: 100%; overflow: hidden; background: #fff; color: #11111b; }
    .map { position: absolute; left: 0; right: 0; top: 0; height: ${390 * sy}px; overflow: hidden; background: #eee8df; }
    .water { position: absolute; left: ${-65 * sx}px; top: ${-40 * sy}px; width: ${260 * sx}px; height: ${520 * sy}px; background: #a8d9df; transform: rotate(-12deg); opacity: .9; }
    .park { position: absolute; border-radius: ${20 * fsScale}px; background: #b9dfaa; opacity: .85; }
    .park.one { left: ${245 * sx}px; top: ${54 * sy}px; width: ${160 * sx}px; height: ${118 * sy}px; transform: rotate(-14deg); }
    .park.two { right: ${45 * sx}px; top: ${120 * sy}px; width: ${175 * sx}px; height: ${125 * sy}px; transform: rotate(9deg); }
    .road { position: absolute; height: ${26 * sy}px; border-radius: 999px; background: #fff; box-shadow: 0 0 0 ${5 * fsScale}px #dad7cf; opacity: .98; }
    .road.a { left: ${-100 * sx}px; top: ${105 * sy}px; width: ${1050 * sx}px; transform: rotate(22deg); }
    .road.b { left: ${70 * sx}px; top: ${255 * sy}px; width: ${950 * sx}px; transform: rotate(-18deg); }
    .road.c { left: ${180 * sx}px; top: ${-20 * sy}px; width: ${560 * sx}px; transform: rotate(82deg); }
    .main-road { position: absolute; left: ${-60 * sx}px; top: ${190 * sy}px; width: ${1050 * sx}px; height: ${48 * sy}px; border-radius: 999px; background: #f3e884; box-shadow: 0 0 0 ${6 * fsScale}px #d6cd72; transform: rotate(12deg); }
    .label { position: absolute; color: #68696e; font-size: ${22 * fsScale}px; font-weight: 800; opacity: .65; }
    .label.a { left: ${205 * sx}px; top: ${165 * sy}px; transform: rotate(12deg); }
    .label.b { right: ${72 * sx}px; top: ${55 * sy}px; transform: rotate(82deg); }
    .back { position: absolute; left: ${38 * sx}px; top: ${110 * sy}px; z-index: 4; width: ${92 * sx}px; height: ${92 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #fff; color: #11111b; font-size: ${42 * fsScale}px; font-weight: 800; box-shadow: 0 ${8 * fsScale}px ${18 * fsScale}px rgba(0,0,0,.13); }
    .support { position: absolute; right: ${52 * sx}px; top: ${235 * sy}px; z-index: 4; width: ${142 * sx}px; height: ${142 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #fff; color: #1b7994; font-size: ${76 * fsScale}px; box-shadow: 0 ${8 * fsScale}px ${20 * fsScale}px rgba(0,0,0,.16); }
    .sheet { position: absolute; left: 0; right: 0; top: ${340 * sy}px; bottom: 0; padding: ${48 * sy}px ${39 * sx}px 0; border-top-left-radius: ${42 * fsScale}px; border-top-right-radius: ${42 * fsScale}px; background: #fff; }
    .order-title { font-size: ${50 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.058em; color: #11111b; }
    .restaurant { display: inline-flex; align-items: center; gap: ${13 * sx}px; margin-top: ${33 * sy}px; height: ${53 * sy}px; padding: 0 ${22 * sx}px; border-radius: 999px; background: #f1f1f1; color: #23232b; font-size: ${30 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.04em; }
    .code-card { margin: ${45 * sy}px auto 0; width: ${510 * sx}px; height: ${190 * sy}px; display: flex; flex-direction: column; align-items: center; justify-content: center; border-radius: ${24 * fsScale}px; background: #fff0ee; }
    .code-label { color: #ff7043; font-size: ${32 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.04em; }
    .code { margin-top: ${32 * sy}px; color: #050509; font-size: ${56 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: .24em; padding-left: ${18 * sx}px; }
    .status-title { margin-top: ${45 * sy}px; font-size: ${42 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.055em; color: #11111b; }
    .timeline { position: relative; margin-top: ${38 * sy}px; padding-left: ${128 * sx}px; }
    .line { position: absolute; left: ${43 * sx}px; top: ${44 * sy}px; width: ${4 * sx}px; height: ${585 * sy}px; background: #e0e0e0; }
    .step { position: relative; min-height: ${150 * sy}px; }
    .dot { position: absolute; left: ${-126 * sx}px; top: ${-5 * sy}px; width: ${88 * sx}px; height: ${88 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; color: #fff; font-size: ${38 * fsScale}px; font-weight: 800; }
    .dot.black { background: #000; }
    .dot.purple { background: #30175c; }
    .dot.muted { background: #f1f1f1; color: #aaa; }
    .step-name { font-size: ${34 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.045em; color: #050509; }
    .step-desc { margin-top: ${20 * sy}px; font-size: ${28 * fsScale}px; line-height: 1.15; font-weight: 400; letter-spacing: -.035em; color: #77777f; }
    .step.muted .step-name { color: #a7a7ab; }
    .step.muted .step-desc { color: #c2c2c5; }
    .driver { position: relative; margin-top: ${-10 * sy}px; min-height: ${132 * sy}px; display: grid; grid-template-columns: ${130 * sx}px 1fr ${112 * sx}px; align-items: center; column-gap: ${18 * sx}px; }
    .driver-avatar { position: relative; width: ${104 * sx}px; height: ${104 * sx}px; border-radius: 50%; overflow: hidden; background: #fde7e3; box-shadow: 0 0 0 ${5 * fsScale}px #fde7e3; }
    .driver-avatar:before { content: ''; position: absolute; left: ${28 * sx}px; top: ${18 * sy}px; width: ${48 * sx}px; height: ${48 * sx}px; border-radius: 50%; background: #5a321f; box-shadow: 0 ${34 * sy}px 0 ${18 * fsScale}px #ff6a2b; }
    .driver-avatar:after { content: ''; position: absolute; left: ${20 * sx}px; top: ${8 * sy}px; width: ${64 * sx}px; height: ${34 * sy}px; border-radius: ${28 * fsScale}px ${28 * fsScale}px ${16 * fsScale}px ${16 * fsScale}px; background: #19151b; }
    .driver-face { position: absolute; left: ${34 * sx}px; top: ${32 * sy}px; width: ${36 * sx}px; height: ${32 * sy}px; border-radius: 50%; background: #8a4e30; z-index: 2; }
    .driver-shirt { position: absolute; left: ${18 * sx}px; bottom: ${-15 * sy}px; width: ${68 * sx}px; height: ${48 * sy}px; border-radius: ${28 * fsScale}px ${28 * fsScale}px 0 0; background: #ff5722; z-index: 1; }
    .driver-name { font-size: ${34 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.045em; color: #050509; }
    .call { width: ${96 * sx}px; height: ${96 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #ff3a35; color: #fff; font-size: ${43 * fsScale}px; }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="soft-circle"></div>
    <div class="soft-band"></div>
    <div class="headline">Suivez votre<br>livraison</div>
    <div class="phone-wrap">
      <section class="phone" aria-label="Suivi de commande client Dineroo">
        <div class="screen">
          <div class="map">
            <div class="water"></div><div class="park one"></div><div class="park two"></div>
            <div class="road a"></div><div class="road b"></div><div class="road c"></div><div class="main-road"></div>
            <div class="label a">Rue de Conakry</div><div class="label b">Route principale</div>
          </div>
          <div class="back">‹</div>
          <div class="support">🎧</div>
          <section class="sheet">
            <div class="order-title">Commande #A3C1</div>
            <div class="restaurant">▣ Restaurant City Louange</div>
            <div class="code-card"><div class="code-label">Code à donner au livreur</div><div class="code">1111</div></div>
            <div class="status-title">Statut de la commande</div>
            <div class="timeline">
              <div class="line"></div>
              <div class="step"><div class="dot black">✓</div><div class="step-name">Commande passée</div><div class="step-desc">Votre commande a bien été enregistrée</div></div>
              <div class="step"><div class="dot purple">✓</div><div class="step-name">Commande confirmée</div><div class="step-desc">Le restaurant a finalisé votre commande</div></div>
              <div class="step"><div class="dot purple">♞</div><div class="step-name">En cours de livraison</div><div class="step-desc">Le livreur a récupéré votre commande</div></div>
              <div class="driver"><div class="driver-avatar"><div class="driver-face"></div><div class="driver-shirt"></div></div><div class="driver-name">Kémoko</div><div class="call">☎</div></div>
            </div>
          </section>
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

render(1080, 1920, path.join(root, 'android', '07-client-tracking.png'));
render(1242, 2688, path.join(root, 'ios', '07-client-tracking.png'));
render(2048, 2732, path.join(root, 'ipad-13', '07-client-tracking.png'));

console.log('Generated premium draft 07-client-tracking');
