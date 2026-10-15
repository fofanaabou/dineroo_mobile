const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '../..');
const chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const fontsDir = path.resolve(root, '../../assets/fonts');
const sharedFoodDir = path.resolve(root, 'source/02-restaurants-nearby');

const outputs = [
  { name: 'android', width: 1080, height: 1920, file: 'android/00-brand-hero.png' },
  { name: 'ios', width: 1242, height: 2688, file: 'ios/00-brand-hero.png' },
  { name: 'ipad-13', width: 2048, height: 2732, file: 'ipad-13/00-brand-hero.png' },
];

function fileUrl(filePath) {
  return `file://${filePath}`;
}

function html({ width, height }) {
  const sx = width / 1080;
  const sy = height / 1920;
  const fsScale = Math.min(sx, sy);

  const burger = fileUrl(path.join(sharedFoodDir, 'food-pizza.jpg'));
  const bowl = fileUrl(path.join(sharedFoodDir, 'food-bowl.jpg'));

  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <style>
    @font-face {
      font-family: Montserrat;
      src: url('${fileUrl(path.join(fontsDir, 'Montserrat-Regular.ttf'))}');
      font-weight: 400;
    }
    @font-face {
      font-family: Montserrat;
      src: url('${fileUrl(path.join(fontsDir, 'Montserrat-SemiBold.ttf'))}');
      font-weight: 700;
    }
    @font-face {
      font-family: Lobster;
      src: url('${fileUrl(path.join(fontsDir, 'Lobster-Regular.ttf'))}');
      font-weight: 400;
    }

    * { box-sizing: border-box; }
    html, body { margin: 0; width: ${width}px; height: ${height}px; overflow: hidden; }
    body { font-family: Montserrat, Arial, sans-serif; background: #f58d1d; }

    .artboard {
      position: relative;
      width: ${width}px;
      height: ${height}px;
      overflow: hidden;
      background:
        radial-gradient(circle at 18% 18%, rgba(255,255,255,.22) 0, rgba(255,255,255,0) ${330 * sx}px),
        linear-gradient(180deg, #f58d1d 0%, #f18717 56%, #ef7b0c 100%);
      color: #fff;
    }

    .cream-shape {
      position: absolute;
      left: ${-150 * sx}px;
      right: ${-140 * sx}px;
      bottom: ${-118 * sy}px;
      height: ${560 * sy}px;
      background: #fff8ef;
      transform: rotate(-6deg);
      transform-origin: center;
      border-radius: ${88 * sx}px;
      box-shadow: 0 ${-26 * sy}px ${84 * sx}px rgba(104, 45, 0, .12);
    }

    .soft-disc {
      position: absolute;
      right: ${-170 * sx}px;
      top: ${505 * sy}px;
      width: ${520 * sx}px;
      height: ${520 * sx}px;
      border-radius: 50%;
      background: rgba(255,255,255,.12);
    }

    .brand {
      position: absolute;
      left: ${82 * sx}px;
      top: ${94 * sy}px;
      font-family: Lobster, Montserrat, sans-serif;
      font-size: ${82 * fsScale}px;
      line-height: .95;
      letter-spacing: -.02em;
    }

    .headline {
      position: absolute;
      left: ${82 * sx}px;
      top: ${245 * sy}px;
      width: ${890 * sx}px;
      font-size: ${102 * fsScale}px;
      line-height: .99;
      letter-spacing: -.075em;
      font-weight: 400;
    }

    .headline strong {
      display: inline-block;
      font-weight: 700;
      letter-spacing: -.082em;
    }

    .subline {
      position: absolute;
      left: ${82 * sx}px;
      top: ${650 * sy}px;
      width: ${760 * sx}px;
      font-size: ${32 * fsScale}px;
      line-height: 1.25;
      letter-spacing: -.035em;
      color: rgba(255,255,255,.92);
      font-weight: 700;
    }

    .tag {
      position: absolute;
      left: ${82 * sx}px;
      top: ${786 * sy}px;
      padding: ${18 * sy}px ${30 * sx}px;
      border-radius: ${999 * sx}px;
      background: rgba(15, 15, 45, .20);
      border: ${1.5 * sx}px solid rgba(255,255,255,.35);
      font-size: ${23 * fsScale}px;
      line-height: 1;
      font-weight: 700;
      letter-spacing: -.015em;
    }

    .food {
      position: absolute;
      background-size: cover;
      background-position: center;
      filter: saturate(1.12) contrast(1.04);
    }

    .food-main {
      right: ${-240 * sx}px;
      bottom: ${245 * sy}px;
      width: ${860 * sx}px;
      height: ${670 * sy}px;
      background-image: url('${burger}');
      border-radius: ${62 * sx}px;
      transform: rotate(-7deg);
      box-shadow: 0 ${38 * sy}px ${104 * sx}px rgba(63, 28, 0, .34);
    }

    .food-bowl {
      left: ${-160 * sx}px;
      bottom: ${315 * sy}px;
      width: ${565 * sx}px;
      height: ${455 * sy}px;
      background-image: url('${bowl}');
      border-radius: 50%;
      transform: rotate(9deg);
      box-shadow: 0 ${32 * sy}px ${88 * sx}px rgba(63, 28, 0, .24);
    }

  </style>
</head>
<body>
  <main class="artboard">
    <div class="cream-shape"></div>
    <div class="soft-disc"></div>
    <div class="brand">Dineroo</div>
    <div class="headline">Vos plats<br>préférés<br><strong>livrés chez vous.</strong></div>
    <div class="subline">Commandez dans vos restaurants préférés et suivez votre livraison en direct.</div>
    <div class="tag">Commande • Paiement mobile • Suivi en direct</div>
    <div class="food food-bowl"></div>
    <div class="food food-main"></div>
  </main>
</body>
</html>`;
}

fs.mkdirSync(path.join(root, 'android'), { recursive: true });
fs.mkdirSync(path.join(root, 'ios'), { recursive: true });
fs.mkdirSync(path.join(root, 'ipad-13'), { recursive: true });

for (const output of outputs) {
  const htmlPath = path.join(__dirname, `.render-${output.name}.html`);
  const outPath = path.join(root, output.file);
  fs.writeFileSync(htmlPath, html(output));
  execFileSync(chrome, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    `--window-size=${output.width},${output.height}`,
    `--screenshot=${outPath}`,
    htmlPath,
  ], { stdio: 'inherit' });
  fs.rmSync(htmlPath, { force: true });
}
