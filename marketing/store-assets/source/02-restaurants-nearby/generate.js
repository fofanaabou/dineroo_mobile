const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '../..');
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const fonts = path.resolve(root, '../../assets/fonts');
const foodBowl = path.join(__dirname, 'food-bowl.jpg');
const foodPlate = path.join(__dirname, 'food-plate.jpg');
const foodPizza = path.join(__dirname, 'food-pizza.jpg');
const nomadFood = path.join(__dirname, 'nomad-food.jpeg');

function restaurantCard({ top, title, status, distance, desc, imageClass }) {
  return `<article class="restaurant-card" style="top:${top}%">
    <div class="thumb ${imageClass}"></div>
    <div class="restaurant-copy">
      <div class="restaurant-title">${title}</div>
      <div class="closed">${status}</div>
      <div class="distance">⌖ ${distance}</div>
      ${desc ? `<div class="desc">${desc}</div>` : ''}
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
    .artboard {
      position: relative;
      width: 100%;
      height: 100%;
      overflow: hidden;
      color: #fff;
      background: #f58d1d;
    }
    .headline {
      position: absolute;
      left: ${72 * sx}px;
      top: ${78 * sy}px;
      width: ${830 * sx}px;
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
      background: url('file://${foodPlate}') center / cover;
      filter: saturate(1.06) contrast(1.02);
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
    .phone {
      position: absolute;
      inset: 0;
      overflow: hidden;
      border-radius: ${46 * fsScale}px ${46 * fsScale}px 0 0;
      background: #fff;
    }
    .screen {
      position: relative;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #fff;
      color: #11111f;
    }
    .app-header {
      position: absolute;
      left: ${44 * sx}px;
      right: ${44 * sx}px;
      top: ${82 * sy}px;
      height: ${60 * sy}px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #171722;
      font-size: ${35 * fsScale}px;
      font-weight: 400;
      letter-spacing: -.025em;
    }
    .cart {
      position: absolute;
      right: ${18 * sx}px;
      top: 50%;
      transform: translateY(-50%);
      font-size: ${42 * fsScale}px;
      color: #030307;
    }
    .search {
      position: absolute;
      left: ${24 * sx}px;
      right: ${24 * sx}px;
      top: ${228 * sy}px;
      height: ${104 * sy}px;
      display: flex;
      align-items: center;
      gap: ${26 * sx}px;
      padding: 0 ${34 * sx}px;
      border-radius: ${52 * fsScale}px;
      background: #f7f7f7;
      box-shadow: 0 ${9 * fsScale}px ${22 * fsScale}px rgba(0,0,0,.035);
      color: #8b8b91;
      font-size: ${32 * fsScale}px;
      line-height: 1;
      letter-spacing: .01em;
    }
    .search b { color: #5d5d64; font-size: ${45 * fsScale}px; line-height: 1; }
    .restaurant-card {
      position: absolute;
      left: ${22 * sx}px;
      right: ${22 * sx}px;
      height: ${196 * sy}px;
      border-radius: ${30 * fsScale}px;
      background: #fff;
      box-shadow: 0 ${10 * fsScale}px ${28 * fsScale}px rgba(18,18,24,.055);
    }
    .thumb {
      position: absolute;
      left: ${28 * sx}px;
      top: ${28 * sy}px;
      width: ${240 * sx}px;
      height: ${140 * sy}px;
      overflow: hidden;
      border-radius: ${17 * fsScale}px;
      background-size: cover;
      background-position: center;
    }
    .food-1 { background-image: url('file://${foodBowl}'); }
    .food-2 { background-image: url('file://${foodPlate}'); }
    .food-3 { background-image: url('file://${foodPizza}'); }
    .food-4 { background-image: url('file://${nomadFood}'); }
    .empty {
      display: flex;
      align-items: center;
      justify-content: center;
      background: #f0f0f0;
      color: #a8a8a8;
      font-size: ${34 * fsScale}px;
    }
    .empty:before { content: '▨'; }
    .restaurant-copy {
      position: absolute;
      left: ${300 * sx}px;
      right: ${26 * sx}px;
      top: ${31 * sy}px;
    }
    .restaurant-title {
      color: #25252d;
      font-size: ${31 * fsScale}px;
      line-height: 1.08;
      font-weight: 800;
      letter-spacing: -.04em;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .closed {
      display: inline-flex;
      margin-top: ${16 * sy}px;
      padding: ${8 * sy}px ${20 * sx}px;
      border-radius: 999px;
      background: #e9f9ef;
      color: #159447;
      font-size: ${25 * fsScale}px;
      line-height: 1;
      font-weight: 400;
    }
    .distance {
      margin-top: ${13 * sy}px;
      color: #9e9ea5;
      font-size: ${23 * fsScale}px;
      line-height: 1;
      letter-spacing: .02em;
    }
    .desc {
      margin-top: ${13 * sy}px;
      color: #8b8b92;
      font-size: ${24 * fsScale}px;
      line-height: 1.28;
      letter-spacing: .01em;
    }
    .nav {
      position: absolute;
      left: 0;
      right: 0;
      bottom: 0;
      height: ${170 * sy}px;
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      align-items: center;
      background: rgba(255,255,255,.98);
      box-shadow: 0 -${12 * fsScale}px ${30 * fsScale}px rgba(0,0,0,.055);
    }
    .nav-item {
      position: relative;
      text-align: center;
      color: #aaa8ad;
      font-size: ${22 * fsScale}px;
      line-height: 1.16;
      font-weight: 400;
    }
    .nav-icon {
      display: block;
      width: ${54 * sx}px;
      height: ${54 * sx}px;
      margin: 0 auto ${5 * sy}px;
    }
    .nav-icon svg { width: 100%; height: 100%; fill: none; stroke: currentColor; stroke-width: 2.35; stroke-linecap: round; stroke-linejoin: round; }
    .nav-item.active { color: #ff6f43; }
    .badge-count { position: absolute; left: 50%; top: ${-13 * sy}px; transform: translateX(${23 * sx}px); min-width: ${30 * sx}px; height: ${30 * sx}px; padding: 0 ${7 * sx}px; display: flex; align-items: center; justify-content: center; border-radius: 999px; background: #ff6f43; color: #fff; font-size: ${16 * fsScale}px; line-height: 1; font-weight: 800; }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="headline">Les restos<br>autour de vous</div>
    <div class="side-food"></div>
    <div class="phone-wrap">
      <section class="phone" aria-label="Restaurants à proximité dans Dineroo">
        <div class="screen">
          <header class="app-header">Restaurants à proximité <span class="cart">🛒</span></header>
          <div class="search"><b>⌕</b>Rechercher sur Dineroo</div>
          ${restaurantCard({ top: 26.3, title: "Mimiche's Food", status: 'Restaurant ouvert', distance: '1.2 km', imageClass: 'food-2' })}
          ${restaurantCard({ top: 41.5, title: 'La Cuisine de Hawa', status: 'Restaurant ouvert', distance: '1.8 km', imageClass: 'food-1' })}
          ${restaurantCard({ top: 56.7, title: 'Morgan Restaurant', status: 'Restaurant ouvert', distance: '2.4 km', desc: 'Notre mission est de fournir des repas..', imageClass: 'food-3' })}
          ${restaurantCard({ top: 73.0, title: 'Nomad', status: 'Restaurant ouvert', distance: '3.1 km', desc: 'Restaurant moderne pour vos brunchs', imageClass: 'food-4' })}
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

render(1080, 1920, path.join(root, 'android', '02-restaurants-nearby.png'));
render(1242, 2688, path.join(root, 'ios', '02-restaurants-nearby.png'));
render(2048, 2732, path.join(root, 'ipad-13', '02-restaurants-nearby.png'));

console.log('Generated premium draft 02-restaurants-nearby');
