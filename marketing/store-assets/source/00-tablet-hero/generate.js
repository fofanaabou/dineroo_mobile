const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '../..');
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const fontsDir = path.resolve(root, '../../assets/fonts');
const sharedFoodDir = path.resolve(root, 'source/02-restaurants-nearby');

function fileUrl(filePath) {
  return `file://${filePath}`;
}

function html() {
  const pizza = fileUrl(path.join(sharedFoodDir, 'food-pizza.jpg'));
  const plate = fileUrl(path.join(sharedFoodDir, 'food-plate.jpg'));

  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <style>
    @font-face { font-family: Montserrat; src: url('${fileUrl(path.join(fontsDir, 'Montserrat-Regular.ttf'))}'); font-weight: 400; }
    @font-face { font-family: Montserrat; src: url('${fileUrl(path.join(fontsDir, 'Montserrat-SemiBold.ttf'))}'); font-weight: 800; }
    @font-face { font-family: Lobster; src: url('${fileUrl(path.join(fontsDir, 'Lobster-Regular.ttf'))}'); font-weight: 400; }

    * { box-sizing: border-box; }
    html, body { margin: 0; width: 2560px; height: 1600px; overflow: hidden; }
    body { font-family: Montserrat, Arial, sans-serif; background: #f58d1d; }

    .artboard {
      position: relative;
      width: 2560px;
      height: 1600px;
      overflow: hidden;
      color: #fff;
      background:
        radial-gradient(circle at 18% 16%, rgba(255,255,255,.24) 0, rgba(255,255,255,0) 620px),
        linear-gradient(135deg, #f58d1d 0%, #f18717 56%, #ef7b0c 100%);
    }

    .cream-shape {
      position: absolute;
      right: -260px;
      bottom: -240px;
      width: 1320px;
      height: 690px;
      border-radius: 130px;
      background: #fff8ef;
      transform: rotate(-8deg);
      box-shadow: 0 -34px 110px rgba(87, 37, 0, .16);
    }

    .brand {
      position: absolute;
      left: 148px;
      top: 128px;
      font-family: Lobster, Montserrat, sans-serif;
      font-size: 126px;
      line-height: .95;
      letter-spacing: -.02em;
    }

    .headline {
      position: absolute;
      left: 148px;
      top: 370px;
      width: 1130px;
      font-size: 150px;
      line-height: .96;
      letter-spacing: -.078em;
      font-weight: 400;
    }

    .headline strong {
      display: inline-block;
      font-weight: 800;
      letter-spacing: -.086em;
    }

    .subline {
      position: absolute;
      left: 154px;
      top: 910px;
      width: 1040px;
      font-size: 48px;
      line-height: 1.22;
      letter-spacing: -.04em;
      font-weight: 800;
      color: rgba(255,255,255,.92);
    }

    .tag {
      position: absolute;
      left: 154px;
      top: 1115px;
      padding: 28px 46px;
      border-radius: 999px;
      background: rgba(15, 15, 45, .20);
      border: 2px solid rgba(255,255,255,.36);
      font-size: 34px;
      line-height: 1;
      font-weight: 800;
      letter-spacing: -.02em;
    }

    .food {
      position: absolute;
      background-size: cover;
      background-position: center;
      filter: saturate(1.13) contrast(1.04);
      box-shadow: 0 44px 110px rgba(63, 28, 0, .28);
    }

    .food-main {
      right: -70px;
      top: 220px;
      width: 1040px;
      height: 760px;
      border-radius: 90px;
      background-image: url('${pizza}');
      transform: rotate(-6deg);
      z-index: 2;
    }

    .food-plate {
      right: 500px;
      bottom: 90px;
      width: 520px;
      height: 390px;
      border-radius: 64px;
      background-image: url('${plate}');
      transform: rotate(5deg);
      z-index: 4;
    }
  </style>
</head>
<body>
  <main class="artboard">
    <div class="cream-shape"></div>
    <div class="brand">Dineroo</div>
    <div class="headline">Vos plats<br>préférés<br><strong>livrés chez vous.</strong></div>
    <div class="subline">Commandez dans vos restaurants préférés et suivez votre livraison en direct.</div>
    <div class="tag">Commande • Paiement mobile • Suivi en direct</div>
    <div class="food food-main"></div>
    <div class="food food-plate"></div>
  </main>
</body>
</html>`;
}

const htmlPath = path.join(__dirname, '.render-tablet.html');
const outPath = path.join(root, 'tablet', '00-brand-hero.png');

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(htmlPath, html());
execFileSync(chrome, [
  '--headless=new',
  '--disable-gpu',
  '--hide-scrollbars',
  '--window-size=2560,1600',
  `--screenshot=${outPath}`,
  htmlPath,
], { stdio: 'inherit' });
fs.rmSync(htmlPath, { force: true });

console.log('Generated tablet hero 00-brand-hero');
