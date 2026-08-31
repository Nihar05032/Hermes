# LeadForge AI

> Autonomous AI Digital Presence Sales Platform

Find businesses with no website or a poor one. Research them. Score the lead. Generate a demo website. Send personalized outreach. Track replies. Close deals.

## Architecture

```
User selects Location/Industry/Filters
  → n8n Search Workflow → Business Data Provider
  → Normalize + Deduplicate → Supabase
  → Website Detection (has website? audit / no website? research)
  → Hermes Research Agent → Review Analysis
  → Business Profile → Lead Scoring
  → Website Opportunity? YES →
  → Hermes Website Agent → Demo Website
  → Hermes Outreach Agent → n8n → Send Email
  → Track reply/click → Supabase CRM
```

## Tech Stack

| Technology | Responsibility |
|---|---|
| **n8n** | Workflows, schedules, API calls, loops, queues, retries |
| **Hermes** | Reasoning, research, review analysis, personalization, website planning/code |
| **Supabase** | Business data, CRM data, users, campaigns, AI intelligence |
| **PostgreSQL** | Structured relational data |
| **pgvector** | Semantic business/review intelligence |
| **Docker** | Deploy and isolate services |
| **Redis** | Queues / distributed workers |
| **Next.js** | Dashboard |
| **Business APIs** | Business discovery |
| **Email provider** | Outreach delivery |
| **Vercel/Cloudflare** | Preview website hosting |

## Project Structure

```
leadforge/
├── docker/
│   ├── docker-compose.yml      # All services
│   └── nginx.conf               # Reverse proxy config
├── supabase/
│   └── migrations/
│       └── 001_initial_schema.sql  # 14 tables + RLS + pgvector
├── n8n-workflows/
│   ├── 01_business_discovery.json  # Search → Normalize → Supabase
│   ├── 02_business_enrichment.json # Hermes Research → Store AI analysis
│   ├── 03_lead_scoring.json        # Score → Qualify → Generate website
│   └── 04_email_outreach.json      # Generate email → Send → Track
├── hermes-agents/
│   ├── 01_research_agent.md        # Investigate business
│   ├── 02_review_analyst.md        # Analyze reviews
│   ├── 03_lead_scoring.md          # Score 0-100
│   ├── 04_website_strategist.md    # Plan website structure
│   ├── 05_website_developer.md     # Generate Next.js demo site
│   ├── 06_outreach_agent.md        # Write personalized email
│   └── 07_reply_analyst.md         # Analyze email replies
├── provider/
│   └── adapter.py                  # Business Provider Interface
├── backend-api/
│   ├── main.py                     # FastAPI bridge: n8n ↔ Hermes ↔ Supabase
│   ├── Dockerfile
│   └── requirements.txt
├── website-builder/                # AI website generation service
├── dashboard/                      # Next.js dashboard
├── docs/
└── .env.example                    # Copy to .env and fill in
```

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/Nihar05032/Hermes.git
cd Hermes/leadforge
cp .env.example .env
# Edit .env with your API keys
```

### 2. Set up Supabase

```bash
# Create a new Supabase project at https://supabase.com
# Run the migration in the SQL editor:
# Paste contents of supabase/migrations/001_initial_schema.sql
```

### 3. Launch with Docker

```bash
cd docker
docker-compose up -d
```

### 4. Access services

| Service | URL |
|---|---|
| Dashboard | http://localhost:3000 |
| n8n | http://localhost:5678 |
| Backend API | http://localhost:3001 |
| Nginx (all services) | http://localhost:80 |

### 5. Import n8n workflows

1. Open n8n at http://localhost:5678
2. Go to Workflows → Import
3. Import each file from `n8n-workflows/`

### 6. Configure Hermes agents

Copy the prompts from `hermes-agents/` into your Hermes Agent profile as skills, or use them as system prompts when calling the Hermes API.

## Key Design Principles

- **n8n = WHAT happens next** (deterministic workflow)
- **Hermes = THINK about it** (AI reasoning)
- **Provider interface pattern** — swappable data providers
- **Human approval** before outreach and website publication in V1
- **pgvector** for semantic search across business intelligence

## Pipeline Stages

```
NEW → RESEARCHED → QUALIFIED → WEBSITE_GENERATED → CONTACTED → REPLIED → MEETING → CLIENT
                                                                ↘ REJECTED
```

## V1 Roadmap

- [x] Database schema (14 tables)
- [x] Docker Compose architecture
- [x] n8n workflow definitions (4 workflows)
- [x] Hermes agent prompts (7 agents)
- [x] Provider adapter interface
- [x] Backend API stubs
- [ ] Implement provider adapters (Google Places, OSM, Scraper)
- [ ] Build Next.js dashboard
- [ ] Wire n8n workflows to live APIs
- [ ] Test end-to-end pipeline
- [ ] Add email tracking (opens, clicks, replies)
- [ ] Add human approval gate UI

## License

MIT

## Author

Nihar — built with Hermes Agent