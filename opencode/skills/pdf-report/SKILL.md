---
name: pdf-report
description: Generate beautiful, print-ready PDF reports from structured content (markdown, bullet points, meeting notes, plain text). Produces a styled HTML file and exports it to PDF using Chrome headless via Puppeteer — full CSS, fonts, colors, embedded images all preserved. Use this skill whenever the user wants to create a PDF report, document, summary, or presentation-quality output — proposals, postmortems, meeting reports, changelogs, or any "make this look professional as a PDF" request. Trigger on phrases like "make a PDF", "create a report", "turn this into a document", "export to PDF", "generate a nice PDF", "make a nice report".
---

# PDF Report Skill

Turn structured content into a polished, branded PDF. The workflow is: design a beautiful HTML document → export to PDF via Puppeteer (Chrome headless) for pixel-perfect rendering.

## Core Principles

Weasyprint and `--print-to-pdf` CLI flags strip fonts and colors. Always use **Puppeteer via Node.js** with Chrome as the PDF engine — it renders identically to what the user sees in the browser.

Design with intent. Each report has a purpose and an audience. Before writing a line of CSS, commit to an aesthetic direction (formal/executive, technical/clean, branded, etc.) and execute it with precision.

## Step 1 — Gather Context

Before designing, extract or confirm:
- **Content**: the markdown/text to render (may already be in the conversation)
- **Branding**: any logo files to embed? Company name? Color preferences?
- **Purpose**: proposal, postmortem, meeting report, summary, changelog? Shapes the tone.
- **Output path**: where to save the HTML and PDF (default: same directory as input or `~/Downloads/`)

Check `~/Downloads/` for logos — embed them as base64 so the PDF is self-contained.

## Step 2 — Design the HTML

### File naming
`<slug>-YYYY-MM-DD.html` alongside a matching `.pdf`.

### Aesthetic Direction
Pick one and commit:
- **Executive/formal**: dark navy cover, serif display font, stat cards, clean tables
- **Technical**: monospace accents, syntax-highlighted code blocks, timeline layout
- **Branded**: derive palette from the logo, match company visual identity
- **Minimal**: generous whitespace, single accent color, no decoration

### Typography — never use generic fonts
Good pairs:
- `DM Serif Display` + `DM Sans` (formal reports)
- `Playfair Display` + `Source Sans 3` (editorial)
- `Fraunces` + `Inter` (modern branded)

Load via Google Fonts `@import` in the `<style>` block.

### Structure
Every report needs:
1. **Cover page** — title, subtitle, date, metadata grid, branding. Use `page-break-after: always`.
2. **Content pages** — consistent page header (title + logo), section headings with eyebrow labels, footer with page number.
3. **Visual hierarchy** — use stat/summary cards for key numbers, color-coded badges for status/categories, tables with a dark `thead`. Match the complexity of the visuals to the content — not every report needs stat cards.

### CSS Essentials
```css
/* A4 sizing */
body { max-width: 210mm; margin: 0 auto; }

/* Page breaks */
.cover { page-break-after: always; }
.page  { page-break-before: always; min-height: 297mm; padding: 40px 52px; }
h2, .section-label { page-break-after: avoid; }
table  { page-break-inside: avoid; }

/* Print: remove browser chrome */
@media print {
  body { max-width: 100%; }
}
```

### Embed logos as base64
```bash
LOGO=$(base64 -i /path/to/logo.png | tr -d '\n')
# Then in HTML: <img src="data:image/png;base64,${LOGO}" />
```
Use a shell heredoc to write the HTML file with the variable interpolated — don't use a Python/JS script for the HTML generation, keep it in bash for simplicity.

## Step 3 — Export to PDF via Puppeteer

**Do not use weasyprint or Chrome's `--print-to-pdf` CLI flag** — both drop fonts, colors, and complex CSS.

Check Node is available: `which node`. If not, fall back to Chrome headless with a local HTTP server (see fallback below).

### Primary method — Puppeteer script
```bash
# Install puppeteer (once per machine, cached after first run)
cd /tmp && npm install puppeteer --save-quiet 2>&1 | tail -1

# Write and run the export script
cat > /tmp/pdf-export.mjs << 'EOF'
import puppeteer from 'puppeteer';
import { pathToFileURL } from 'url';

const browser = await puppeteer.launch({
  executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  args: ['--no-sandbox']
});
const page = await browser.newPage();
await page.goto(pathToFileURL('/PATH/TO/report.html').href, { waitUntil: 'networkidle0' });
await page.pdf({
  path: '/PATH/TO/report.pdf',
  format: 'A4',
  printBackground: true,
  displayHeaderFooter: false,   // ← this actually works via Puppeteer
  margin: { top: 0, bottom: 0, left: 0, right: 0 }
});
await browser.close();
console.log('Done');
EOF

node /tmp/pdf-export.mjs
```

Key flags:
- `printBackground: true` — preserves background colors/images
- `displayHeaderFooter: false` — removes Chrome's URL/date footer (this is the ONLY reliable way)
- `waitUntil: 'networkidle0'` — waits for Google Fonts to load
- `margin: { top:0, ... }` — let the HTML control all spacing

### Fallback — Chrome headless over HTTP
If Node/Puppeteer isn't available:
```bash
cd "$(dirname /path/to/report.html)" && python3 -m http.server 8923 &
SERVER_PID=$!
sleep 1
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --headless=new --print-to-pdf="/path/to/report.pdf" \
  --print-to-pdf-no-header --no-margins --no-sandbox \
  "http://localhost:8923/report.html" 2>&1 | tail -2
kill $SERVER_PID
```
Note: this method may still show the URL in the footer — Puppeteer is strongly preferred.

## Step 4 — Verify and Open
```bash
ls -lh /path/to/report.pdf   # confirm it exists and has reasonable size (>100KB)
open /path/to/report.pdf      # open for user to review
```

## Common Patterns

### Stat cards row
```html
<div style="display:grid; grid-template-columns:repeat(4,1fr); gap:12px; margin-bottom:28px;">
  <div style="background:#f8fafc; border:1px solid #cbd5e1; border-top:3px solid #1e3a5f; border-radius:6px; padding:16px; text-align:center;">
    <div style="font-size:26pt; font-weight:700; color:#1e3a5f; font-family:'DM Serif Display',serif;">42</div>
    <div style="font-size:8pt; font-weight:600; color:#475569;">Items Completed</div>
  </div>
  <!-- repeat... -->
</div>
```

### Status badge
```html
<span style="display:inline-block; padding:2px 8px; border-radius:12px; font-size:8pt; font-weight:700; background:#dcfce7; color:#15803d;">Done</span>
<span style="display:inline-block; padding:2px 8px; border-radius:12px; font-size:8pt; font-weight:700; background:#fef9ec; color:#92400e;">In Progress</span>
<span style="display:inline-block; padding:2px 8px; border-radius:12px; font-size:8pt; font-weight:700; background:#fef2f2; color:#b91c1c;">Blocked</span>
```

### Dark table header
```css
thead tr { background: #0f2644; color: white; }
thead th { padding: 9px 12px; font-size: 8.5pt; font-weight: 600; }
tbody td { padding: 8px 12px; border-bottom: 1px solid #e2e8f0; }
tbody tr:nth-child(even) { background: #f8fafc; }
```

### Cover page template
```html
<div class="cover" style="background:#1e3a5f; color:white; min-height:297mm; display:flex; flex-direction:column; padding:52px 56px 48px; position:relative; overflow:hidden; page-break-after:always;">
  <img src="data:image/png;base64,${LOGO}" style="width:130px; filter:brightness(0) invert(1); margin-bottom:64px;" />
  <div style="font-size:9pt; font-weight:600; letter-spacing:.18em; text-transform:uppercase; color:rgba(255,255,255,.55); margin-bottom:16px;">DOCUMENT TYPE · CONTEXT</div>
  <h1 style="font-family:'DM Serif Display',serif; font-size:38pt; line-height:1.1; color:white; margin-bottom:8px;">Report Title</h1>
  <div style="font-family:'DM Serif Display',serif; font-size:18pt; color:rgba(255,255,255,.65); margin-bottom:40px;">Subtitle</div>
  <div style="width:56px; height:3px; background:#1a7f6e; margin-bottom:36px; border-radius:2px;"></div>
  <!-- metadata grid, badges at bottom -->
</div>
```
