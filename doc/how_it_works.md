# How image_color_backdrop works

This document explains the pipeline from an `ImageProvider` to the final
background color, so you can predict and tune the result.

## 1. Loading

`ImageColorBackdrop.paletteFromImageProvider` wraps your provider in a
`ResizeImage` (policy `fit`, no upscaling) with `maxDimension` (default 96) as
the target box. Flutter's engine therefore decodes the image directly at a
small size, which keeps memory use and time low even for 12-megapixel photos.

The resulting `ui.Image` is read as **straight RGBA** bytes
(`ImageByteFormat.rawStraightRgba`). Straight (non-premultiplied) alpha
matters: premultiplied data would darken semi-transparent edges and skew the
color.

`paletteFromImage` accepts an already decoded `ui.Image`; when it is larger
than `maxDimension` it is drawn to a smaller canvas first.

## 2. Filtering

While pixels are counted, a pixel is skipped when:

- its alpha is below `alphaThreshold` (default 16), so transparent PNG
  backgrounds never contribute;
- it lies outside `region` (see `BackdropRegion`);
- `ignoreNearWhite` is set and all channels are at least 235;
- `ignoreNearBlack` is set and all channels are at most 20.

If the color filters remove every pixel (for example an all-white image with
`ignoreNearWhite`), they are dropped automatically and the image is sampled
again, so you always get a color when there is one.

## 3. Quantization (histogram + median cut)

1. Each remaining pixel is placed in a 32x32x32 histogram (5 bits per
   channel). Per bin the algorithm stores the pixel count and the exact sum of
   each channel, so the final averages are precise and not rounded to bin
   centers.
2. All non-empty bins form one *box*. Repeatedly, one box is chosen and split
   along its longest color axis at the population median. The first 75% of
   splits choose the box with the largest population; the remaining splits
   also weigh the box's color volume, so that small but distinct colors get a
   swatch instead of being absorbed by big areas.
3. Each final box becomes a `PaletteSwatch`: the population-weighted average
   color, its pixel count and its proportion of all sampled pixels.

Complexity is linear in the number of sampled pixels; a 96x96 sample takes a
few milliseconds. The result is deterministic.

## 4. Choosing a swatch (strategies)

| Strategy | Rule |
| --- | --- |
| `dominant` | The swatch with the highest population. |
| `vibrant` | Highest score of `0.5 * saturation + 0.3 * midLightness + 0.2 * relativePopulation`, considering swatches with at least 0.5% of the pixels. |
| `muted` | Like `vibrant`, but rewards a saturation close to 0.3 instead of a high one. |
| `average` | Population-weighted mean of all swatches (equal to the mean of all sampled pixels). |
| `lightest` / `darkest` | Highest / lowest HSL lightness among swatches with at least 2% of the pixels (all swatches when none reaches 2%). |

`midLightness` is `1 - 2 * |lightness - 0.5|`: it is 1 for a mid-tone and 0 for
pure black or white, which keeps washed-out and near-black colors from being
called "vibrant".

## 5. Styling

`BackdropStyle.apply` runs, in order:

1. **saturation**: HSL saturation is increased towards 1 (positive) or scaled
   down towards 0 (negative).
2. **brightness**: linear interpolation towards white (positive) or black
   (negative).
3. **blend**: linear interpolation towards `blendColor` by `blendAmount`.
4. **contrast**: if `ensureContrastWith` is set and the WCAG contrast ratio is
   below `minContrastRatio`, the color is moved towards white or black
   (whichever increases the contrast) in 5% steps until the ratio is met.
5. **opacity**: the alpha channel is multiplied.

## 6. Readable foreground

`BackdropColorUtils.readableOn` composites the (possibly translucent) color
over a surface color and returns whichever of a light or dark foreground has
the higher WCAG contrast ratio. `ImageBackdrop` uses the current theme's
surface color; `BackdropResult.onColorFor(surface)` lets you do the same in
your own widgets.

## 7. Caching

Palettes are cached in an LRU cache keyed by `(ImageProvider key, sampling
options)`. Options that do not change the palette (`strategy`,
`fallbackColor`) and styles are not part of the key, so re-styling never
triggers new work. Concurrent requests for the same key share a single
in-flight future.

## Limitations

- SVG and other vector formats must be rasterized first.
- Animated images use their first frame.
- On the web, images from other origins need CORS headers so that their pixels
  can be read.
- Median cut finds representative colors, not semantic objects: the "vibrant"
  color of a photo is the most saturated large-enough area, not necessarily
  the subject.
