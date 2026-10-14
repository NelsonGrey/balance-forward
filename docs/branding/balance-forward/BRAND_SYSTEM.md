# Balance Forward brand system

**Status:** Selected creative direction; preliminary name and mark only. Formal
trademark clearance and final legal approval remain required before launch.

## Brand idea

**Balance Forward** helps students practice financial choices that build on one
another across school and home. The **Compounding Arc** turns that promise into
three rising bands: daily practice, growing capability, and expanding options.

Primary tagline: **Good choices compound.**

## Logo files

| Asset | Intended use |
| --- | --- |
| `packages/web/public/brand/balance-forward-mark.svg` | Default standalone mark |
| `packages/web/public/brand/balance-forward-mark-mono.svg` | One-color production and print |
| `packages/web/public/brand/balance-forward-mark-reverse.svg` | Dark backgrounds |
| `packages/web/public/brand/balance-forward-lockup-horizontal.svg` | Website headers and wide layouts |
| `packages/web/public/brand/balance-forward-lockup-stacked.svg` | Square and centered layouts |
| `packages/web/public/brand/balance-forward-app-icon.svg` | App-icon master artwork |
| `packages/web/public/brand/balance-forward-tokens.css` | Portable web token source |

The SVGs use no gradients, filters, masks, or raster content. Lockups keep the
wordmark as accessible live text with a documented fallback stack; the mark is
fully geometric.

## Color

| Role | Name | Hex | Use |
| --- | --- | --- | --- |
| Primary | Ink Green | `#123C35` | Wordmark, primary arc, dark fields |
| Growth | Sage | `#75B798` | Middle arc, illustration, large fills |
| Momentum | Marigold | `#F2B544` | Top arc, emphasis, large accents |
| Foundation | Parchment | `#F8F3E8` | Warm canvas and reverse artwork |

### Accessibility

Measured WCAG contrast ratios:

- Ink Green on Parchment: **11.01:1**
- Ink Green on white: **12.18:1**
- Sage on Ink Green: **5.21:1**
- Marigold on Ink Green: **6.65:1**

Sage and Marigold must not be used for normal-sized text on white or Parchment.
They are brand accents and large graphic fills. Use Ink Green or the secondary
text token for copy. White may be used on the darker UI action tokens, not on
Marigold or Sage.

## Typography

The identity uses **Avenir Next** where it is licensed and installed. Product
implementations should use this portable fallback stack:

```css
font-family: "Avenir Next", Avenir, Montserrat, system-ui, sans-serif;
```

- Wordmark and display headings: weight 700, tight tracking.
- Interface headings: weight 700 without extreme tracking.
- Body and labels: weight 400–600, normal tracking.
- Never typeset the product as `BalanceForward` or abbreviate it to `BF` in
  customer-facing copy.

## Clear space and minimum size

Use the top arc's stroke width as the minimum clear space on every side of the
standalone mark and lockups.

- Standalone mark: minimum **24 CSS px** wide digitally.
- App icon: minimum **32 CSS px**; use platform-specific safe-area exports.
- Horizontal lockup: minimum **220 CSS px** wide.
- Stacked lockup: minimum **160 CSS px** wide.
- Below those lockup sizes, use the standalone mark plus adjacent HTML text
  instead of shrinking the tagline.

## Backgrounds

- Use the full-color mark on white or Parchment.
- Use the reverse mark on Ink Green or photography with a verified dark field.
- Do not place the full-color mark on Sage or Marigold.
- Do not add drop shadows, outlines, gradients, or containers to the mark.

## Voice

Balance Forward is encouraging, practical, and nonjudgmental. It speaks about
choices and learning—not a child's worth, discipline, or financial status.

Preferred language:

- practice money skills
- make a plan
- learn from a choice
- see how choices add up
- practice money, not real money

Avoid:

- good kid / bad kid
- winning at money
- rich / poor comparisons
- streak loss or shame language
- claims that the product guarantees financial outcomes

## Production note

The selected raster concept board remains in
`docs/branding/balance-forward-concepts/02c-compounding-arc-evergreen-gold.png`.
It is visual direction only. The SVG files listed above are the deterministic
production masters. Do not trace or export assets from the raster board.
