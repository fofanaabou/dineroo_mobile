const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '../..');
const chrome = '/Applications/Google Chrome.app/Contents/MOS/Google Chrome'.replace('/MOS/', '/MacOS/');
const fonts = path.resolve(root, '../../assets/fonts');
const foodBowl = path.join(__dirname, 'food-bowl.jpg');
const foodPlate = path.join(__dirname, 'food-plate.jpg');
const foodPizza = path.join(__dirname, 'food-pizza.jpg');

function menuCard({ left, title, desc, price, image }) {
  return `<article class="menu-card" style="left:${left}%">
    <div class="menu-img ${image}"><span>Menu</span></div>
    <div class="menu-body">
      <div class="menu-title">${title}</div>
      <div class="menu-desc">${desc}</div>
      <div class="menu-price">Dès ${price} GNF</div>
      <div class="plus">+</div>
    </div>
  </article>`;
}

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
    .headline {
      position: absolute;
      left: ${72 * sx}px;
      top: ${78 * sy}px;
      width: ${820 * sx}px;
      font-size: ${80 * fsScale}px;
      line-height: 1.02;
      font-weight: 800;
      letter-spacing: -.058em;
    }
    .side-food {
      position: absolute;
      left: ${-175 * sx}px;
      bottom: ${48 * sy}px;
      width: ${360 * sx}px;
      height: ${700 * sy}px;
      border-radius: 45%;
      background: url('file://${foodBowl}') center / cover;
      filter: saturate(1.08) contrast(1.03);
      opacity: .78;
      transform: rotate(-8deg);
    }
    .phone-wrap {
      position: absolute;
      left: ${96 * sx}px;
      top: ${370 * sy}px;
      width: ${888 * sx}px;
      height: ${1538 * sy}px;
      filter: drop-shadow(0 ${28 * fsScale}px ${44 * fsScale}px rgba(70,28,0,.24));
    }
    .phone { position: absolute; inset: 0; overflow: hidden; border-radius: ${46 * fsScale}px ${46 * fsScale}px 0 0; background: #fff; }
    .screen { position: relative; width: 100%; height: 100%; overflow: hidden; background: #fff; color: #11111f; }
    .hero {
      position: absolute;
      left: 0;
      right: 0;
      top: 0;
      height: ${315 * sy}px;
      background: linear-gradient(rgba(0,0,0,.08), rgba(0,0,0,.08)), url('file://${foodPlate}') center 48% / cover;
    }
    .round-btn {
      position: absolute;
      top: ${72 * sy}px;
      width: ${80 * sx}px;
      height: ${80 * sx}px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 999px;
      background: #fff;
      color: #050509;
      font-size: ${42 * fsScale}px;
      font-weight: 800;
      box-shadow: 0 ${8 * fsScale}px ${18 * fsScale}px rgba(0,0,0,.14);
    }
    .back { left: ${42 * sx}px; }
    .cart { right: ${42 * sx}px; }
    .content { position: absolute; left: ${36 * sx}px; right: ${36 * sx}px; top: ${360 * sy}px; }
    .title-row { display: flex; align-items: center; justify-content: space-between; gap: ${20 * sx}px; }
    .restaurant-name { font-size: ${52 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.052em; }
    .verified { width: ${46 * sx}px; height: ${46 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #ff5a2a; color: #fff; font-size: ${27 * fsScale}px; font-weight: 800; }
    .address { margin-top: ${28 * sy}px; color: #222229; font-size: ${30 * fsScale}px; line-height: 1.12; font-weight: 800; letter-spacing: -.02em; }
    .address span { color: #ff5a2a; margin-right: ${12 * sx}px; }
    .description { margin-top: ${18 * sy}px; color: #7c7c83; font-size: ${29 * fsScale}px; line-height: 1.28; letter-spacing: .01em; }
    .open { display: inline-flex; margin-top: ${26 * sy}px; padding: ${10 * sy}px ${20 * sx}px; border-radius: 999px; background: #e9f9ef; color: #159447; font-size: ${25 * fsScale}px; line-height: 1; }
    .stats { display: flex; gap: ${16 * sx}px; margin-top: ${22 * sy}px; }
    .stat { padding: ${12 * sy}px ${22 * sx}px; border-radius: 999px; background: #f5f5f5; color: #696970; font-size: ${23 * fsScale}px; font-weight: 800; line-height: 1; }
    .selection {
      margin-top: ${34 * sy}px;
      height: ${112 * sy}px;
      display: flex;
      align-items: center;
      gap: ${24 * sx}px;
      padding: 0 ${32 * sx}px;
      border: 1.5px solid #ffdfc7;
      border-radius: ${32 * fsScale}px;
      background: #fffaf6;
      color: #191920;
      font-size: ${29 * fsScale}px;
      font-weight: 800;
      letter-spacing: -.035em;
    }
    .fire { width: ${66 * sx}px; height: ${66 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #ff5a2a; color: #fff; }
    .chips { display: flex; gap: ${14 * sx}px; margin-top: ${26 * sy}px; }
    .chip { display: flex; align-items: center; gap: ${10 * sx}px; padding: ${15 * sy}px ${24 * sx}px; border-radius: 999px; background: #f6f6f6; color: #222229; font-size: ${25 * fsScale}px; font-weight: 800; line-height: 1; white-space: nowrap; }
    .chip i { width: ${32 * sx}px; height: ${32 * sx}px; border-radius: 50%; background: url('file://${foodPizza}') center / cover; }
    .menus-title { position: absolute; left: 0; top: ${603 * sy}px; z-index: 3; font-size: ${46 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.052em; background: #fff; padding-right: ${18 * sx}px; }
    .menus-subtitle { position: absolute; left: 0; top: ${656 * sy}px; z-index: 3; color: #a2a2a7; font-size: ${23 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.025em; }
    .count { position: absolute; right: 0; top: ${606 * sy}px; z-index: 3; width: ${54 * sx}px; height: ${54 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #f0f0f0; color: #11111f; font-size: ${24 * fsScale}px; font-weight: 800; }
    .menus-row { position: absolute; left: 0; top: ${700 * sy}px; z-index: 2; width: ${980 * sx}px; height: ${310 * sy}px; background: #fff; }
    .menu-card { position: absolute; top: 0; width: ${500 * sx}px; height: ${300 * sy}px; overflow: hidden; border: 1px solid #e8e8e8; border-radius: ${28 * fsScale}px; background: #fff; box-shadow: 0 ${6 * fsScale}px ${16 * fsScale}px rgba(0,0,0,.05); }
    .menu-img { position: relative; height: ${118 * sy}px; background-size: cover; background-position: center; }
    .menu-img.bistro { background-image: url('file://${foodPizza}'); }
    .menu-img.discover { background-image: url('file://${foodBowl}'); }
    .menu-img span { position: absolute; left: ${24 * sx}px; top: ${24 * sy}px; padding: ${13 * sy}px ${24 * sx}px; border-radius: 999px; background: #fff; color: #222229; font-size: ${24 * fsScale}px; font-weight: 800; }
    .menu-body { position: relative; height: ${182 * sy}px; padding: ${20 * sy}px ${24 * sx}px; }
    .menu-title { color: #17171e; font-size: ${30 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.048em; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .menu-desc { margin-top: ${14 * sy}px; color: #85858b; font-size: ${21 * fsScale}px; line-height: 1.16; max-height: ${50 * sy}px; overflow: hidden; }
    .menu-price { position: absolute; left: ${24 * sx}px; bottom: ${28 * sy}px; color: #5f5f66; font-size: ${24 * fsScale}px; line-height: 1; font-weight: 800; letter-spacing: -.035em; }
    .plus { position: absolute; right: ${21 * sx}px; bottom: ${18 * sy}px; width: ${48 * sx}px; height: ${48 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #fff; color: #ff7600; font-size: ${32 * fsScale}px; line-height: 1; font-weight: 400; box-shadow: 0 ${5 * fsScale}px ${12 * fsScale}px rgba(0,0,0,.12); }
    .nav { position: absolute; left: 0; right: 0; bottom: 0; height: ${170 * sy}px; display: grid; grid-template-columns: repeat(4, 1fr); align-items: center; background: rgba(255,255,255,.98); box-shadow: 0 -${12 * fsScale}px ${30 * fsScale}px rgba(0,0,0,.055); }
    .nav-item { position: relative; text-align: center; color: #aaa8ad; font-size: ${25 * fsScale}px; line-height: 1.16; font-weight: 400; }
    .nav-icon { display: block; width: ${54 * sx}px; height: ${54 * sx}px; margin: 0 auto ${5 * sy}px; }
    .nav-icon svg { width: 100%; height: 100%; fill: none; stroke: currentColor; stroke-width: 2.35; stroke-linecap: round; stroke-linejoin: round; }
    .nav-item.active { color: #ff6f43; }
    .badge-count { position: absolute; left: 50%; top: ${-13 * sy}px; transform: translateX(${23 * sx}px); min-width: ${30 * sx}px; height: ${30 * sx}px; padding: 0 ${7 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 999px; background: #ff6f43; color: #fff; font-size: ${16 * fsScale}px; line-height: 1; font-weight: 800; }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="headline">Choisissez<br>votre menu</div>
    <div class="side-food"></div>
    <div class="phone-wrap">
      <section class="phone" aria-label="Page restaurant Mimiche's Food dans Dineroo">
        <div class="screen">
          <div class="hero"><div class="round-btn back">‹</div><div class="round-btn cart">🛒</div></div>
          <div class="content">
            <div class="title-row"><div class="restaurant-name">Mimiche's Food</div><div class="verified">✓</div></div>
            <div class="address"><span>●</span>Carrefour Canadien, Lambanyi, Conakry</div>
            <div class="description">Restaurant de cuisine africaine situé à Conakry, fondé par Mimiche Diabaté.</div>
            <div class="open">Restaurant ouvert</div>
            <div class="stats"><div class="stat">▤ 3 menus</div><div class="stat">▦ 17 produits</div></div>
            <div class="selection"><div class="fire">♨</div>Découvrez la sélection du restaurant</div>
            <div class="chips"><div class="chip"><i></i>Entrée</div><div class="chip"><i></i>Plat</div><div class="chip"><i></i>Boisson</div><div class="chip"><i></i>Dessert</div></div>
            <div class="menus-title">Menus</div>
            <div class="menus-subtitle">Prix de base + suppléments éventuels</div>
            <div class="count">3</div>
            <div class="menus-row">
              ${menuCard({ left: 0, title: 'Menu Bistrot', desc: 'Plat et boisson au choix.', price: '47 250', image: 'bistro' })}
              ${menuCard({ left: 56, title: 'Menu Découverte', desc: 'Entrée, plat, dessert et boisson au choix.', price: '81 900', image: 'discover' })}
            </div>
          </div>
          <nav class="nav">
            <div class="nav-item active"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M4.5 11.2 12 5l7.5 6.2"/><path d="M6.5 10.5v8h11v-8"/><path d="M10 18.5v-4h4v4"/></svg></span>Accueil</div>
            <div class="nav-item"><span class="badge-count">2</span><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M7 7h12l-1.2 7.4H8.6L7 4.5H4.5"/><path d="M9.2 19h.1"/><path d="M17.2 19h.1"/></svg></span>Panier</div>
            <div class="nav-item"><span class="nav-icon"><svg viewBox="0 0 24 24"><path d="M7 5h10v14H7z"/><path d="M9.5 8.5h5"/><path d="M9.5 12h5"/><path d="M9.5 15.5h3.5"/></svg></span>Commandes</div>
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

render(1080, 1920, path.join(root, 'android', '03-restaurant-detail.png'));
render(1242, 2688, path.join(root, 'ios', '03-restaurant-detail.png'));
render(2048, 2732, path.join(root, 'ipad-13', '03-restaurant-detail.png'));

console.log('Generated premium draft 03-restaurant-detail');
