# IncidentIQ AI

IncidentIQ AI is a full-stack incident-response MVP with a React + TypeScript dashboard and an Express API. It uses the official Hindsight TypeScript client for persistent memory and Groq for structured incident reasoning. The UI includes a labeled sample workspace, incident capture, live recall and retention, history, analytics, an assistant, and a three-interaction memory demonstration.

## Requirements

- Node.js 20+
- A Hindsight Cloud account, API key, and memory bank ID
- A Groq API key for AI reasoning

## Run locally

```bash
npm install
Copy-Item .env.example .env
# Edit .env with your credentials
npm run dev
```

Open the Vite URL printed in the terminal (normally http://localhost:5173). The Express API runs on port 3001. For a production build, run `npm run build` and then `npm start`; the server serves `dist/` and API routes from the same origin.

## Hindsight Cloud setup

1. Create or select a memory bank in the Hindsight Cloud console.
2. Open the Cloud **Connect** page. Copy the API endpoint and create an API key. Hindsight only displays a new key once.
3. Set `HINDSIGHT_BASE_URL=https://api.hindsight.vectorize.io`, `HINDSIGHT_API_KEY`, and `HINDSIGHT_BANK_ID` in the server environment. Use a bank dedicated to this organization/workspace. Never use a `VITE_` prefix for secrets.
4. Restart the server. The Settings page checks the connection; Memory Explorer's live results come from `listMemories`, and incident intake uses Hindsight `recall` before Groq analysis.
5. Resolve an incident only after recording the actual fix. A successful Hindsight `retain` stores the full incident context, the explicitly labeled root-cause hypothesis, troubleshooting steps, engineer-reported failed approaches, actual resolution, and outcome. A failed retain is reported in the UI and is never represented as a stored memory.

The integration uses `@vectorize-io/hindsight-client` and its documented `HindsightClient({baseUrl, apiKey})`, `recall`, `retain`, and `listMemories` methods. See [Hindsight Cloud API Integration](https://docs.hindsight.vectorize.io/cloud/api-integration/) and [Hindsight TypeScript SDK Guide](https://docs.hindsight.vectorize.io/cloud/typescript-sdk/).

## Groq setup

Set `GROQ_API_KEY` on the backend. The app calls Groq's OpenAI-compatible chat completions endpoint from Express, requests JSON output, and uses the configured `GROQ_MODEL` (default `llama-3.3-70b-versatile`). The API key is not sent to the browser. Without it, the app reports that analysis is not configured and provides only a basic, clearly labeled fallback checklist.

## The live memory demonstration

1. Configure Hindsight and Groq in `.env`.
2. Create an incident titled **Database connection timeout** with error **HTTP 503**, and report the suspected pool exhaustion in its description. Analyze it. The initial incident and explicitly labeled hypothesis are retained in Hindsight if the configured Cloud call succeeds.
3. Open the incident, record the actual resolution **Increased connection pool limit**, and mark it resolved. IncidentIQ retains a second update containing the verified resolution and reports success only if Hindsight confirms the retain call.
4. Submit a follow-up incident such as **Application database requests are failing again** with **Database connection timeout** as the error, or use **Memory Explorer → Recall from Hindsight now**. Inspect the returned facts, which are fetched live from Hindsight.
5. Ask the assistant **Have we faced this issue before, and how did we resolve it?** The answer displays the actual Hindsight memories returned for that query.

The supplied five `DEMO-` records are clearly labeled sample data. They are kept out of Hindsight and cannot be mistaken for retained real memories. The sample database timeout does not pre-populate the memory bank.

## Storage and deployment

Incident records are stored in `data/incidents.json` on the server. This is suitable for a hackathon single-instance demo; persistent production hosting should mount durable storage or replace the repository with a managed database. Hindsight is persistent across app sessions and is scoped by `HINDSIGHT_BANK_ID`. In a multi-tenant production app, derive and authorize bank IDs from authenticated organization membership rather than accepting them from the browser.

Deploy the Node service with Node 20, set the server-side environment variables, expose the configured port, and make sure the host provides persistent storage for `data/`. No secrets belong in a client environment variable or in Git.

## API routes

- `GET /api/status` — integration readiness
- `GET /api/incidents` — saved incident records
- `POST /api/incidents` — validate, recall Hindsight memories, analyze with Groq, save incident
- `POST /api/incidents/:id/resolve` — record actual resolution and retain to Hindsight
- `POST /api/assistant` — recall memories and answer an operational question
- `GET /api/memories?q=...` — live Hindsight memory explorer results
- `POST /api/demo/recall` — live recall for the database-timeout presentation

