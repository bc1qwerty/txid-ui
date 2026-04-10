# @txid/ui

## Language
- Respond in Korean (한국어로 응답)

## Description
Shared Astro component library for txid.uk subdomains. Provides reusable UI components, data files, styles, and utilities consumed by all Astro-based txid.uk sites.

## Tech Stack
- **Framework**: Astro 6 components (.astro files)
- **Package**: @txid/ui (ES module, no build step)

## Key Files
- `components/` -- Shared Astro components
  - `AppBar.astro` -- Top navigation bar
  - `Footer.astro` -- Site footer
  - `Header.astro` -- Page header
  - `Toast.astro` -- Toast notifications
- `data/` -- Shared data files
- `styles/variables.css` -- CSS custom properties (design tokens)
- `utils/` -- Shared utility functions
- `package.json` -- Package exports map

## Usage
Consumed via workspace link or `file:./packages/txid-ui` in each subdomain project:
```js
import AppBar from '@txid/ui/components/AppBar.astro';
import '@txid/ui/styles/variables.css';
```

## Deployment
- Not deployed independently; bundled into each consuming Astro site

## Status
- Active, shared across all txid.uk Astro subdomains
