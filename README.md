# Fine-tuning intro for practitioners and the curious

Slides from a live session (Hyperskill, October 2026) for people who use LLM APIs and are wondering whether they should fine-tune a model on their own data.

The short answer: **fine-tuning changes how a model answers, not what it knows.** It's a good fit for narrow, repetitive tasks where you already know what good output looks like and need it cheaper, faster, more consistent, or running on your own hardware. It's a poor way to teach a model your documents, products or policies; those belong in the prompt, retrieval or tools.

- **Slides (PDF):** [finetuning-intro.pdf](finetuning-intro.pdf). No setup needed; GitHub shows it in the browser
- **Audience questions, with answers:** [audience-qa.md](audience-qa.md)

## Repository contents

| File | What it is |
|---|---|
| `finetuning-intro.pdf` | The slides as a PDF |
| `finetuning_intro_deck.md` | The slides, written in [Slidev](https://sli.dev) markdown |
| `style.css` | Global styles for the deck |
| `audience-qa.md` | Questions asked during the session, and answers |
| `Dockerfile`, `compose.yaml` | Run or export the deck without installing Node |

## Viewing the slides

### With Docker (recommended)

Requires only Docker with Compose.

```bash
docker compose up
```

Open http://localhost:3030. Edits to `finetuning_intro_deck.md` or `style.css` show up in the browser immediately.

Useful pages on the dev server:

- `/presenter`: presenter view with timer and next-slide preview
- `/overview`: all slides on one page

If port 3030 is already in use, pick another one on your machine:

```bash
SLIDES_PORT=3031 docker compose up
```

The startup log will still print `localhost:3030`; that's the port inside the container.

### Export to PDF

```bash
docker compose run --rm export
```

This writes `finetuning-intro.pdf` to the repository folder.

### Without Docker

Requires Node.js 22.12 or later.

```bash
npm ci
npx playwright install chromium   # only needed for PDF export
npm run dev                       # dev server on http://localhost:3030
npm run export                    # PDF export
npm run build                     # static site in dist/, e.g. for GitHub Pages
```

## Questions or feedback

- **Questions about the slides or fine-tuning:** start a [discussion](../../discussions) (see the [welcome post](https://github.com/hyperskill-content/finetuning_intro_session/discussions/1) first)
- **Found a mistake or a broken link:** open an [issue](../../issues)
