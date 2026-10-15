# Dineroo Store Assets

Marketing assets for the Dineroo Mobile Google Play and App Store listings.

## Structure

```text
marketing/store-assets/
  android/              # Android phone PNGs, 1080x1920
  ios/                  # iPhone PNGs, 1290x2796
  tablet/               # Google Play tablet PNGs, 2560x1600
  source/               # HTML/CSS/Node generators and visual sources
```

## Available Assets

Android/iOS phone screenshots:

```text
00-brand-hero
01-role-entry
02-restaurants-nearby
03-restaurant-detail
04-driver-map
05-driver-earnings
06-restaurant-orders
07-client-tracking
```

Tablet:

```text
00-brand-hero
```

## Generation

Images are generated with Node.js, HTML/CSS, and Chrome headless.

Generate all phone assets:

```bash
for script in marketing/store-assets/source/0[0-7]-*/generate.js; do node "$script"; done
```

Generate the tablet hero:

```bash
node marketing/store-assets/source/00-tablet-hero/generate.js
```

Generate one asset:

```bash
node marketing/store-assets/source/07-client-tracking/generate.js
```

## Formats

```text
Android phone : 1080x1920
iOS phone     : 1290x2796
Tablet hero   : 2560x1600
```

PNG files should stay rectangular. Rounded corners displayed in Google Play or the App Store are usually applied by the store UI.

## Preview

Each folder in `source/` contains a `preview.html` file for the generated asset.

Example:

```text
marketing/store-assets/source/07-client-tracking/preview.html
```

## Videos

The same approach can be used for marketing videos:

1. Build animated HTML/CSS scenes.
2. Capture frames with Chrome headless.
3. Assemble frames with `ffmpeg`.
4. Export as `.mp4` or `.mov`.

Check that `ffmpeg` is available before generating videos.

## Notes

- Do not edit PNGs manually. Update `generate.js`, then regenerate.
- Shared food sources are in `source/02-restaurants-nearby/`.
- Phone assets `01` to `07` use short store-style headlines with faithful Dineroo UI mockups.
- `00-brand-hero` is intentionally more marketing-focused and does not show an app screen.
