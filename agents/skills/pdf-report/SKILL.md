---
name: pdf-report
description: Generate beautiful, print-ready PDF reports from structured content (markdown, bullet points, meeting notes, plain text). Produces a styled HTML file and exports it to PDF using Chrome headless via Puppeteer — full CSS, fonts, colors, embedded images all preserved. KYOS documents (audit evidence, client communication, post-mortems/RCAs) use the KYOS report style from the KYOS Design System. Use this skill whenever the user wants to create a PDF report, document, summary, or presentation-quality output — proposals, postmortems, meeting reports, changelogs, or any "make this look professional as a PDF" request. Trigger on phrases like "make a PDF", "create a report", "turn this into a document", "export to PDF", "generate a nice PDF", "make a nice report".
---

# PDF Report Skill

Turn structured content into a polished, branded PDF. The workflow is: write the HTML with the KYOS report stylesheet → export to PDF via Puppeteer (Chrome headless) for pixel-perfect rendering.

## Core Principles

Weasyprint and `--print-to-pdf` CLI flags strip fonts and colors. Always use **Puppeteer via Node.js** with Chrome as the PDF engine — it renders identically to what the user sees in the browser.

Every KYOS report uses the same look, so readers recognise it: audit evidence, client letters, incident post-mortems and RCAs. Don't invent a new palette or font pairing per report; spend the effort on structure and content.

## The KYOS report style

The style lives in the **KYOS Design System** (https://claude.ai/artifact/YA8cz8zVMnsywSrsCTNyG2), section **Documents and PDF reports**, so colleagues produce the same reports. It's the source of truth:

| What | In the design system | Local copy (fallback) |
|---|---|---|
| Rules: anatomy, colour, type, parts, writing | `project/documents.md` | — |
| Stylesheet | `project/documents/kyos-report.css` | `assets/kyos-report.css` |
| Logo (the ring) | `assets/Logos/kyos-ring.png` (asset id `edc36025d4fe59a68d3caf1ba8a759e3`) | `assets/kyos-ring.png` |
| Examples | components `ReportCover`, `ReportPage` | — |

When the Artifact tool is available, read `project/documents.md` and `project/documents/kyos-report.css` from the design system (action `read`, `paths`) before writing, and use them over the local copies. If they differ from `assets/kyos-report.css`, tell the user the local copy is stale. Without the Artifact tool, use the local copies.

Non-KYOS work (personal, other organisations) can use a different look; ask.

## Step 1 — Gather Context

Before writing, extract or confirm:
- **Content**: the markdown/text to render (may already be in the conversation)
- **Kind**: audit evidence, client communication, post-mortem/RCA, other. Shapes the cover eyebrow, the parts used and the footer classification.
- **Audience**: internal ("KYOS — Confidential") or a client copy ("KYOS · Incident report (prepared for <client>)")
- **Output path**: where to save the HTML and PDF (default: the current directory, else `~/Downloads/`)

## Step 2 — Write the HTML

### File naming
`<slug>-YYYY-MM-DD.html` alongside a matching `.pdf`.

### Stylesheet and logo
Inline the whole stylesheet in `<style>` and the ring as a base64 data URI so the PDF is self-contained:

```bash
SKILL=~/.claude/skills/pdf-report   # or the design-system copies read via the Artifact tool
CSS=$(cat "$SKILL/assets/kyos-report.css")
RING=$(base64 -i "$SKILL/assets/kyos-ring.png" | tr -d '\n')
```
Use a shell heredoc to write the HTML file with the variables interpolated — keep it in bash rather than a Python/JS generator. Don't add report-specific CSS beyond small layout tweaks (column widths, one-off spacing); if a report needs a new part, propose adding it to the design system.

### Structure
1. **Cover** — `.cover` with `.cover-logo` (the ring), `.grow`, `.cover-eyebrow`, `h1`, `.cover-sub`, `.cover-accent`, optional `.badges`, `.cover-meta` (or `.cover-meta three`).
2. **Content pages** — `.page` with `.page-header` (`.page-header-title` + `.page-header-logo` ring, or `.title` + `.ref`), sections as `.section-eyebrow` + `h2`, then `.page-footer` (classification · document · page number). Add `.page.fixed` for a page that must be exactly one sheet.
3. **Parts**, as the content needs them: `.meta` fact strip, `.stats > .stat` (`.good|.warn|.bad`), tables (`.kv`, `.compact`, `tr.secondary`), `.badge.ok|warn|bad|muted|info`, `.callout` (`.warn|.bad|.info`), `.qa`, `.cia.on|off`, `code`.

Follow `documents.md` for the rules — notably: `kyos-orange` is never text; every badge carries a word; titles in sentence case and outcome-first for post-mortems.

### Skeleton
```html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><title>Report title</title>
<style>${CSS}</style></head><body>
<div class="cover">
  <img class="cover-logo" src="data:image/png;base64,${RING}" alt="KYOS"/>
  <div class="grow"></div>
  <div class="cover-eyebrow">Evidence document &middot; ISMS / Vanta &middot; ISO 27001:2022 A.8.18</div>
  <h1>Privileged utility programs</h1>
  <div class="cover-sub">One-line description of what the document covers</div>
  <div class="cover-accent"></div>
  <div class="cover-meta">
    <div><span>Evidence request</span>Privileged utility programs</div>
    <div><span>Prepared</span>9 November 2026</div>
  </div>
</div>
<div class="page">
  <div class="page-header"><span class="page-header-title">Privileged utility programs &middot; A.8.18</span>
    <img class="page-header-logo" src="data:image/png;base64,${RING}" alt=""/></div>
  <div class="section-eyebrow">Overview</div>
  <h2>How KYOS controls privileged utilities</h2>
  <p>…</p>
  <div class="page-footer"><span>KYOS &mdash; Confidential</span><span>Privileged utility programs</span><span>Page 1</span></div>
</div>
</body></html>
```

### Fitting pages
Pages grow with their content and Chrome breaks them, which can leave a footer alone on the next sheet. After exporting, check the page count; if a page spills by a few lines, split a table or move a section to the next `.page` rather than shrinking the type.

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
- `printBackground: true` — preserves background colors/images (the dark cover and table heads)
- `displayHeaderFooter: false` — removes Chrome's URL/date footer (this is the ONLY reliable way)
- `waitUntil: 'networkidle0'` — waits for Figtree to load from Google Fonts
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
ls -lh /path/to/report.pdf                      # exists, reasonable size
pdfinfo /path/to/report.pdf | grep Pages        # expected page count, no footer-only spill pages
pdffonts /path/to/report.pdf | grep -i figtree  # Figtree embedded, not a fallback font
open /path/to/report.pdf                        # open for user to review
```
