const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '../..');
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const fontsDir = path.resolve(root, '../../assets/fonts');
const foodDir = path.resolve(root, 'source/02-restaurants-nearby');

function fileUrl(filePath) {
  return `file://${filePath}`;
}

function html() {
  const pizza = fileUrl(path.join(foodDir, 'food-pizza.jpg'));
  const plate = fileUrl(path.join(foodDir, 'food-plate.jpg'));

  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <style>
    @font-face { font-family: Montserrat; src: url('${fileUrl(path.join(fontsDir, 'Montserrat-Regular.ttf'))}'); font-weight: 400; }
    @font-face { font-family: Montserrat; src: url('${fileUrl(path.join(fontsDir, 'Montserrat-SemiBold.ttf'))}'); font-weight: 800; }
    @font-face { font-family: Lobster; src: url('${fileUrl(path.join(fontsDir, 'Lobster-Regular.ttf'))}'); }

    * { box-sizing: border-box; }
    html, body { width: 1024px; height: 500px; margin: 0; overflow: hidden; }
    body { font-family: Montserrat, Arial, sans-serif; background: #f58d1d; }

    .artboard {
      position: relative;
      width: 1024px;
      height: 500px;
      overflow: hidden;
      color: #fff;
      background:
        radial-gradient(circle at 10% 15%, rgba(255,255,255,.22) 0, rgba(255,255,255,0) 230px),
        linear-gradient(135deg, #f58d1d 0%, #f18717 58%, #ef7b0c 100%);
    }

    .brand {
      position: absolute;
      left: 58px;
      top: 45px;
      font-family: Lobster, Montserrat, sans-serif;
      font-size: 58px;
      line-height: .95;
      letter-spacing: -.02em;
    }

    .headline {
      position: absolute;
      left: 58px;
      top: 130px;
      width: 520px;
      font-size: 55px;
      line-height: .98;
      font-weight: 800;
      letter-spacing: -.062em;
    }

    .subline {
      position: absolute;
      left: 60px;
      top: 310px;
      width: 430px;
      font-size: 22px;
      line-height: 1.25;
      font-weight: 800;
      letter-spacing: -.035em;
      color: rgba(255,255,255,.92);
    }

    .tag {
      position: absolute;
      left: 60px;
      bottom: 48px;
      padding: 13px 22px;
      border-radius: 999px;
      background: rgba(15, 15, 45, .20);
      border: 1px solid rgba(255,255,255,.35);
      font-size: 15px;
      line-height: 1;
      font-weight: 800;
      letter-spacing: -.01em;
    }

    .cream {
      position: absolute;
      right: -110px;
      bottom: -115px;
      width: 560px;
      height: 330px;
      border-radius: 80px;
      background: #fff8ef;
      transform: rotate(-7deg);
      box-shadow: 0 -18px 62px rgba(104,45,0,.12);
    }

    .food {
      position: absolute;
      background-size: cover;
      background-position: center;
      filter: saturate(1.12) contrast(1.04);
      box-shadow: 0 26px 70px rgba(63,28,0,.28);
    }

    .food-main {
      right: -82px;
      top: 52px;
      width: 410px;
      height: 310px;
      border-radius: 42px;
      background-image: url('${pizza}');
      transform: rotate(-7deg);
    }

    .food-accent {
      right: 280px;
      bottom: 32px;
      width: 230px;
      height: 175px;
      border-radius: 34px;
      background-image: url('${plate}');
      transform: rotate(6deg);
    }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="cream"></div>
    <div class="brand">Dineroo</div>
    <div class="headline">Vos plats préférés livrés chez vous.</div>
    <div class="subline">Commandez dans vos restaurants préférés et suivez votre livraison en direct.</div>
    <div class="tag">Commande • Paiement mobile • Suivi en direct</div>
    <div class="food food-accent"></div>
    <div class="food food-main"></div>
  </main>
</body>
</html>`;
}

const outDir = path.join(root, 'feature-graphics');
fs.mkdirSync(outDir, { recursive: true });

const htmlPath = path.join(__dirname, '.render-feature-graphic.html');
const outPath = path.join(outDir, 'feature-graphic.png');
fs.writeFileSync(htmlPath, html());
execFileSync(chrome, [
  '--headless=new',
  '--disable-gpu',
  '--hide-scrollbars',
  '--window-size=1024,500',
  `--screenshot=${outPath}`,
  htmlPath,
], { stdio: 'inherit' });
fs.rmSync(htmlPath, { force: true });

console.log('Generated feature-graphic.png');
