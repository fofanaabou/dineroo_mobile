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
    .screen { position: relative; width: 100%; height: 100%; overflow: hidden; background: #f4f4f4; color: #17171f; }
    .hero { position: absolute; left: 0; top: 0; right: 0; height: ${425 * sy}px; padding-top: ${76 * sy}px; text-align: center; color: #fff; background: linear-gradient(135deg, #ff7600 0%, #ff962e 100%); border-bottom-left-radius: ${46 * fsScale}px; border-bottom-right-radius: ${46 * fsScale}px; }
    .title { font-size: ${34 * fsScale}px; line-height: 1; font-weight: 400; letter-spacing: .06em; opacity: .96; }
    .label { margin-top: ${70 * sy}px; font-size: ${36 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.035em; }
    .amount { margin-top: ${33 * sy}px; font-size: ${82 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.045em; }
    .caption { margin-top: ${44 * sy}px; font-size: ${30 * fsScale}px; line-height: 1; font-weight: 400; color: rgba(255,255,255,.72); letter-spacing: -.025em; }
    .stats { position: absolute; left: ${49 * sx}px; right: ${49 * sx}px; top: ${463 * sy}px; display: grid; grid-template-columns: 1fr 1fr; gap: ${28 * sy}px ${28 * sx}px; }
    .stat-card { min-height: ${170 * sy}px; padding: ${34 * sy}px ${38 * sx}px; border-radius: ${34 * fsScale}px; background: #fff; box-shadow: 0 ${8 * fsScale}px ${24 * fsScale}px rgba(0,0,0,.055); }
    .stat-card .name { color: #77777f; font-size: ${28 * fsScale}px; line-height: 1.08; font-weight: 400; letter-spacing: -.03em; }
    .stat-card .value { margin-top: ${31 * sy}px; color: #17171f; font-size: ${34 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.052em; white-space: nowrap; }
    .stat-card .value.orange { color: #ff7600; }
    .notice { position: absolute; left: ${49 * sx}px; right: ${49 * sx}px; top: ${875 * sy}px; padding: ${36 * sy}px ${38 * sx}px; border-radius: ${32 * fsScale}px; background: #fff; border: ${2 * fsScale}px solid #e5e5e5; color: #77777f; font-size: ${31 * fsScale}px; line-height: 1.45; font-weight: 400; letter-spacing: -.03em; box-shadow: 0 ${8 * fsScale}px ${18 * fsScale}px rgba(0,0,0,.035); }
    .withdraw { position: absolute; left: ${49 * sx}px; right: ${49 * sx}px; bottom: ${220 * sy}px; height: ${112 * sy}px; display: flex; align-items: center; justify-content: center; border-radius: ${20 * fsScale}px; background: #ff7600; color: #fff; font-size: ${34 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: .08em; box-shadow: 0 ${8 * fsScale}px ${16 * fsScale}px rgba(185,78,0,.22); }
    .nav { position: absolute; left: 0; right: 0; bottom: 0; height: ${170 * sy}px; display: grid; grid-template-columns: repeat(4, 1fr); align-items: center; background: rgba(255,255,255,.98); box-shadow: 0 -${12 * fsScale}px ${30 * fsScale}px rgba(0,0,0,.055); }
    .nav-item { position: relative; text-align: center; color: #aaa8ad; font-size: ${25 * fsScale}px; line-height: 1.16; font-weight: 400; }
    .nav-icon { display: block; width: ${54 * sx}px; height: ${54 * sx}px; margin: 0 auto ${5 * sy}px; }
    .nav-icon svg { width: 100%; height: 100%; fill: none; stroke: currentColor; stroke-width: 2.35; stroke-linecap: round; stroke-linejoin: round; }
    .nav-item.active { color: #ff6f43; }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="soft-circle"></div>
    <div class="soft-band"></div>
    <div class="headline">Vos gains<br>en temps réel</div>
    <div class="phone-wrap">
      <section class="phone" aria-label="Gains livreur Dineroo">
        <div class="screen">
          <div class="hero">
            <div class="title">Gains</div>
            <div class="label">Montant Disponible</div>
            <div class="amount">125 000 GNF</div>
            <div class="caption">Calculé sur les courses livrées.</div>
          </div>
          <div class="stats">
            <div class="stat-card"><div class="name">Courses terminées</div><div class="value orange">38</div></div>
            <div class="stat-card"><div class="name">Déjà payé</div><div class="value">450 000 GNF</div></div>
            <div class="stat-card"><div class="name">Total gagné</div><div class="value">575 000 GNF</div></div>
            <div class="stat-card"><div class="name">Devise</div><div class="value">GNF</div></div>
          </div>
          <div class="notice">Les retraits sont gérés par Dineroo. Après paiement, votre solde est mis à jour.</div>
          <div class="withdraw">RETIRER MON ARGENT</div>
          <nav class="nav">
            <div class="nav-item"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M4.5 11.2 12 5l7.5 6.2"/><path d="M6.5 10.5v8h11v-8"/><path d="M10 18.5v-4h4v4"/></svg></span>Accueil</div>
            <div class="nav-item"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M7 5h10v14H7z"/><path d="M9.5 8.5h5"/><path d="M9.5 12h5"/><path d="M9.5 15.5h3.5"/></svg></span>Historique</div>
            <div class="nav-item active"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M5 18h14"/><path d="M7 15l4-4 3 3 4-6"/><path d="M15 8h3v3"/></svg></span>Gains</div>
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

render(1080, 1920, path.join(root, 'android', '05-driver-earnings.png'));
render(1242, 2688, path.join(root, 'ios', '05-driver-earnings.png'));
render(2048, 2732, path.join(root, 'ipad-13', '05-driver-earnings.png'));

console.log('Generated premium draft 05-driver-earnings');
