# Cloudflare Feedback Aggregator

## What Is This?

A system that automatically collects customer feedback from multiple sources (Support, Email, GitHub, Discord, Twitter), uses AI to analyze and consolidate similar issues, then prioritizes them based on source reliability and frequency.

**Technology:** Cloudflare Workers + Workers AI (Llama 3.1) + D1 Database  
**Cost:** 100% free tier  
**Automation:** Runs every 6 hours automatically

---

## The Problem It Solves

When users report the same issue across different channels:
- **Without this system:** 15 people reporting "deployment errors" creates 15 separate items to track
- **With this system:** All 15 reports consolidate into 1 prioritized issue with a clear, readable title

---

## How It Works

### 1. Data Collection (Every 6 hours)
Scrapes feedback from 5 sources, each with different priority weights:
- Support Tickets: Weight 5 (highest priority)
- Email: Weight 4
- GitHub Issues: Weight 3
- Discord: Weight 2
- Twitter: Weight 1 (lowest priority)

### 2. AI Analysis
For each feedback item, AI (Llama 3.1):
- Determines if it's an issue (yes/no)
- Extracts keywords (e.g., "deployment", "timeout", "custom-domain")
- Generates a natural language summary (e.g., "Deployment fails with custom domains causing 522 timeout errors")

### 3. Issue Consolidation (KEY FEATURE)
**Multiple feedback items → Single consolidated issue**

Example:
```
8 different feedback items:
- 3 support tickets
- 2 GitHub issues
- 2 Discord messages
- 1 email

All about the same problem, all get keywords: ["deployment", "timeout", "custom-domain"]

Consolidated into 1 issue:
✓ Title: "Deployment fails with custom domains causing 522 timeout errors" (AI summary)
✗ NOT: "Deployment + Timeout + Custom-domain Issues" (keyword list)
✓ Tracks: 8 occurrences, 6 unique reporters
✓ Weighted score: 250
```

### 4. Weighted Scoring
Issues are prioritized using:
```
Base Score = Σ(source_weight) × count_last_30_days
Cross-Channel Bonus = unique_reporters_count × 2
Final Score = Base Score + Cross-Channel Bonus
```

**Example Calculation:**
- 3 support tickets (3×5=15) + 2 emails (2×4=8) + 3 GitHub (3×3=9) = 32 per occurrence
- 11 total occurrences = 352 base score
- 9 unique reporters = 18 bonus
- **Final Score: 370** (high priority!)

### 5. Status Tracking
Three simple states with score change visibility:

**NEW** → Issue just discovered  
**IN PROGRESS** → Team working on it (shows score increase if more people report it)  
**FIXED** → Issue resolved

**Key Feature:** For "In Progress" issues, UI shows score changes  
Example: "Score: 250 ↑ +45 since in-progress started"  
Helps identify: "We're working on it, but it's getting worse"

---
## Core Application Files

| File | Purpose | Cloudflare Product Used |
|------|---------|------------------------|
| **worker.js** | Main application logic - handles cron jobs, API endpoints, AI analysis, and issue consolidation | Workers + Workers AI |
| **wrangler.toml** | Cloudflare configuration - defines worker settings, cron schedule, and resource bindings | Workers (config) |
| **schema.sql** | Database structure - creates 4 tables for storing feedback and consolidated issues | D1 Database |
| **dummy-data.sql** | Sample data - 70 realistic feedback items for testing | D1 Database |
| **index.html** | Dashboard UI - displays issues in 3 tabs (New, In Progress, Fixed) | Pages (optional) |

---

## Documentation Files

| File | Purpose |
|------|---------|
| **PROJECT_DOCUMENTATION.md** | **Main documentation** - explains what the project is and how it works (195 lines) |
| **DEPLOYMENT_GUIDE.md** | Step-by-step deployment instructions with troubleshooting |
| **QUICK_DEPLOY.md** | Copy-paste commands for 5-minute deployment |
| **CHANGES_SUMMARY.md** | Summary of latest updates and clarifications |
| **ARCHITECTURE.md** | Visual diagrams of system architecture and data flow |

---

## Supporting Files

| File | Purpose |
|------|---------|
| **package.json** | Node.js dependencies and npm scripts |
| **setup.sh** | Automated deployment script (bash) |
| **.gitignore** | Git ignore patterns |

---

## Cloudflare Products Summary

### Workers
**Files:** worker.js, wrangler.toml  
**Usage:** Runs the entire application - processes feedback every 6 hours via cron, provides API endpoints for the dashboard, orchestrates all logic  
**Free Tier:** 100,000 requests/day

### Workers AI
**Files:** worker.js (AI.run calls)  
**Usage:** Analyzes each feedback item - determines if it's an issue, extracts keywords, generates natural language summaries  
**Model:** Llama 3.1 8B Instruct  
**Free Tier:** 10,000 neurons/day

### D1 Database
**Files:** schema.sql, dummy-data.sql  
**Usage:** Stores all data in 4 tables - raw feedback, AI analysis, consolidated issues, status changes  
**Free Tier:** 5GB storage, 5M reads/day, 100K writes/day

### Pages (Optional)
**Files:** index.html  
**Usage:** Hosts the dashboard UI - can also be run locally  
**Free Tier:** Unlimited static requests

---

## File Relationships

```
wrangler.toml ──┐
                ├─> Configures worker.js
worker.js ──────┘

worker.js ──────┐
                ├─> Reads/writes to D1 (schema.sql structure)
schema.sql ─────┤
dummy-data.sql ─┘

worker.js ──────┐
                ├─> Provides API for index.html
index.html ─────┘

PROJECT_DOCUMENTATION.md ──> Read this first to understand the project
DEPLOYMENT_GUIDE.md ──> Follow this to deploy
```

---

## Total Files: 12

**Essential (5):** worker.js, wrangler.toml, schema.sql, dummy-data.sql, index.html  
**Documentation (5):** PROJECT_DOCUMENTATION.md, DEPLOYMENT_GUIDE.md, QUICK_DEPLOY.md, CHANGES_SUMMARY.md, ARCHITECTURE.md  
**Supporting (2):** package.json, setup.sh

## What Users See

### Dashboard (3 Views)

**New Issues Tab**
- All unaddressed issues
- Sorted by weighted score
- Actions: Start Working | Mark as Fixed

**In Progress Tab**
- Issues being worked on
- Shows score delta: "↑ +70 since in-progress started"
- Action: Mark as Fixed

**Fixed Issues Tab**
- Resolved issues
- Sorted by most recent

### Issue Card Example
```
Title: Deployment fails with custom domains causing 522 timeout errors
Score: 250 ↑ +45 since in-progress started
12 occurrences (last 30 days)
👥 7 unique reporters
Keywords: deployment, timeout, custom-domain
Status: in-progress
```

---

## Data Storage

**4 Database Tables:**
1. **raw_feedback** - Original feedback from all sources
2. **analyzed_issues** - AI analysis results (keywords, summaries)
3. **consolidated_issues** - Grouped issues with scores, status, unique reporters
4. **status_changes** - Audit log

**Each consolidated issue tracks:** AI title, keywords, occurrence count, unique reporters, weighted score, status, related feedback IDs, score at status change

---

## API Endpoints

- `GET /api/stats` - System statistics
- `GET /api/issues/new` - New issues
- `GET /api/issues/in-progress` - In-progress issues (with score deltas)
- `GET /api/issues/fixed` - Fixed issues
- `POST /api/update-status` - Change issue status
- `POST /api/process` - Manually trigger processing

---

## Key Benefits

### 1. Eliminates Duplicate Tracking
15 reports about the same bug = 1 prioritized issue, not 15 separate items

### 2. Readable Issue Titles
AI summaries like "Deployment fails with custom domains causing 522 errors"  
NOT keyword lists like "Deployment + Timeout + Custom-domain Issues"

### 3. Smart Prioritization
- High-value sources (support tickets) weighted more than low-value (tweets)
- Cross-channel reporting gives bonus (same person complaining everywhere = bigger problem)
- 30-day rolling window keeps focus on current issues

### 4. Escalation Detection
Score delta tracking shows when in-progress issues are getting worse

### 5. Cross-Channel Visibility
Tracks unique reporters: 15 occurrences from 1 person ≠ 15 from 15 different people

### 6. Zero Infrastructure
Runs entirely on Cloudflare's free tier with no servers to manage

---

## What Makes It Different

**Traditional systems:** Each feedback item is tracked separately  
**This system:** AI automatically groups similar feedback into single issues

**Traditional titles:** Manual categorization or keyword tags  
**This system:** AI-generated natural language summaries

**Traditional prioritization:** First-come-first-served or manual  
**This system:** Weighted by source reliability + frequency + cross-channel reporting

**Traditional status:** Fixed or not fixed  
**This system:** Shows score changes during work, reveals escalating issues

---

## Sample Data

Prototype includes 70 feedback items across all 5 sources, consolidating into ~5-8 issues with AI titles like:
- "Deployment fails with custom domains causing 522 timeout errors"
- "D1 database queries timing out after recent update"  
NOT: "Deployment + Custom-domain + Timeout Issues"

---

## Technical Summary

**Input:** Raw feedback from 5 sources  
**Processing:** AI classification → Keyword extraction → Consolidation → Scoring  
**Output:** Prioritized issues with readable titles and cross-channel tracking  
**Automation:** Every 6 hours via cron  
**Interface:** 3-tab dashboard (New, In Progress, Fixed)  

**Core Innovation:** Multiple feedback items automatically consolidate into single issues with AI-generated readable titles.