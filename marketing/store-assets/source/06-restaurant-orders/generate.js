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
    .screen { position: relative; width: 100%; height: 100%; overflow: hidden; background: #fff; color: #17171f; }
    .top { position: absolute; left: 0; right: 0; top: 0; height: ${365 * sy}px; padding: ${86 * sy}px ${46 * sx}px 0; background: #fff; }
    .restaurant { text-align: center; font-size: ${38 * fsScale}px; line-height: 1; font-weight: 400; letter-spacing: -.035em; color: #1d1d29; }
    .status { position: absolute; left: 50%; top: ${165 * sy}px; transform: translateX(-50%); display: inline-flex; align-items: center; padding: ${12 * sy}px ${22 * sx}px; border-radius: 999px; background: #e9f9ef; color: #42a860; font-size: ${24 * fsScale}px; line-height: 1; font-weight: 400; letter-spacing: -.03em; white-space: nowrap; }
    .summary { position: absolute; left: ${56 * sx}px; right: ${56 * sx}px; top: ${252 * sy}px; display: grid; grid-template-columns: 1fr 1fr; gap: ${42 * sx}px; }
    .summary-card { height: ${122 * sy}px; text-align: center; }
    .metric { font-size: ${72 * fsScale}px; line-height: .86; font-weight: 800; letter-spacing: -.065em; color: #11111b; }
    .metric-label { margin-top: ${25 * sy}px; font-size: ${20 * fsScale}px; line-height: 1; font-weight: 800; text-transform: uppercase; letter-spacing: .05em; color: #292933; white-space: nowrap; }
    .orders { position: absolute; left: ${34 * sx}px; right: ${34 * sx}px; top: ${465 * sy}px; bottom: ${173 * sy}px; }
    .order-card { position: absolute; left: 0; right: 0; top: 0; min-height: ${505 * sy}px; padding: ${38 * sy}px ${32 * sx}px; border-radius: ${34 * fsScale}px; background: #fff; border: ${3 * fsScale}px solid #f05a2a; box-shadow: 0 ${18 * fsScale}px ${32 * fsScale}px rgba(240,90,42,.14); }
    .order-card.ghost { top: ${545 * sy}px; min-height: ${128 * sy}px; padding: ${22 * sy}px ${32 * sx}px; opacity: .28; transform: scale(.985); transform-origin: top center; overflow: hidden; }
    .order-card.ghost.two { top: ${685 * sy}px; opacity: .16; }
    .order-card.ghost .actions { margin-top: 0; }
    .order-card.ghost .action { height: ${82 * sy}px; opacity: .9; }
    .row { display: flex; align-items: center; justify-content: space-between; gap: ${16 * sx}px; }
    .badge { display: inline-flex; align-items: center; justify-content: center; height: ${58 * sy}px; padding: 0 ${24 * sx}px; border-radius: ${9 * fsScale}px; background: #ed9708; color: #fff; font-size: ${28 * fsScale}px; font-weight: 800; letter-spacing: .02em; }
    .price { display: inline-flex; align-items: center; justify-content: center; height: ${58 * sy}px; padding: 0 ${28 * sx}px; border-radius: 999px; background: #e7f5e8; border: ${2 * fsScale}px solid #64ba76; color: #2b753b; font-size: ${28 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.052em; }
    .order-title { margin-top: ${52 * sy}px; font-size: ${36 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.048em; color: #11111b; }
    .item { margin-top: ${34 * sy}px; height: ${78 * sy}px; display: flex; align-items: center; justify-content: space-between; padding: 0 ${22 * sx}px; border-radius: ${18 * fsScale}px; background: #f7f7f7; color: #1f1f27; }
    .item .name { font-size: ${31 * fsScale}px; font-weight: 400; letter-spacing: -.04em; }
    .item .item-price { font-size: ${30 * fsScale}px; font-weight: 800; letter-spacing: -.05em; }
    .more { margin-top: ${24 * sy}px; font-size: ${29 * fsScale}px; color: #6f6f78; letter-spacing: -.035em; }
    .actions { margin-top: ${34 * sy}px; display: grid; grid-template-columns: 1fr 1fr; gap: ${23 * sx}px; }
    .action { height: ${98 * sy}px; border-radius: ${23 * fsScale}px; display: flex; align-items: center; justify-content: center; color: #fff; font-size: ${34 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: .075em; box-shadow: 0 ${7 * fsScale}px ${14 * fsScale}px rgba(0,0,0,.09); }
    .reject { background: #ed2722; }
    .accept { background: #20a82a; }
    .nav { position: absolute; left: 0; right: 0; bottom: 0; height: ${170 * sy}px; display: grid; grid-template-columns: repeat(5, 1fr); align-items: center; background: rgba(255,255,255,.98); box-shadow: 0 -${12 * fsScale}px ${30 * fsScale}px rgba(0,0,0,.055); }
    .nav-item { position: relative; text-align: center; color: #aaa8ad; font-size: ${22 * fsScale}px; line-height: 1.16; font-weight: 400; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
    .nav-icon { display: block; width: ${49 * sx}px; height: ${49 * sx}px; margin: 0 auto ${5 * sy}px; }
    .nav-icon svg { width: 100%; height: 100%; fill: none; stroke: currentColor; stroke-width: 2.35; stroke-linecap: round; stroke-linejoin: round; }
    .nav-item.active { color: #ff6f43; }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="soft-circle"></div>
    <div class="soft-band"></div>
    <div class="headline">Gérez vos<br>commandes</div>
    <div class="phone-wrap">
      <section class="phone" aria-label="Commandes entrantes restaurant Dineroo">
        <div class="screen">
          <section class="top">
            <div class="restaurant">Le-Patio</div>
            <div class="status">Restaurant ouvert</div>
          </section>
          <section class="summary">
            <div class="summary-card"><div class="metric">31</div><div class="metric-label">Nouvelles commandes</div></div>
            <div class="summary-card"><div class="metric">2</div><div class="metric-label">Commandes prêtes</div></div>
          </section>
          <section class="orders">
            <article class="order-card">
              <div class="row"><div class="badge">NOUVEAU</div><div class="price">200 000 GNF</div></div>
              <div class="order-title">Commande #228B</div>
              <div class="item"><div class="name">1× Poulet Braisé</div><div class="item-price">180 000 GNF</div></div>
              <div class="more">+ 1 autre</div>
              <div class="actions"><div class="action reject">REFUSER</div><div class="action accept">ACCEPTER</div></div>
            </article>
            <article class="order-card ghost"><div class="actions"><div class="action reject">REFUSER</div><div class="action accept">ACCEPTER</div></div></article>
            <article class="order-card ghost two"><div class="actions"><div class="action reject">REFUSER</div><div class="action accept">ACCEPTER</div></div></article>
          </section>
          <nav class="nav">
            <div class="nav-item active"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M4.5 11.2 12 5l7.5 6.2"/><path d="M6.5 10.5v8h11v-8"/><path d="M10 18.5v-4h4v4"/></svg></span>Accueil</div>
            <div class="nav-item"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M7 5h10v14H7z"/><path d="M9.5 8.5h5"/><path d="M9.5 12h5"/><path d="M9.5 15.5h3.5"/></svg></span>Command...</div>
            <div class="nav-item"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M5 17c4-2 10-2 14 0"/><path d="M7 14c2-5 8-5 10 0"/><path d="M9 10h6"/><path d="M12 7v10"/></svg></span>Menus</div>
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

render(1080, 1920, path.join(root, 'android', '06-restaurant-orders.png'));
render(1242, 2688, path.join(root, 'ios', '06-restaurant-orders.png'));
render(2048, 2732, path.join(root, 'ipad-13', '06-restaurant-orders.png'));

console.log('Generated premium draft 06-restaurant-orders');
