# Quick Reference Guide

## 🎯 Project Overview

**Purpose**: Aggregate and analyze customer feedback from multiple sources using AI
**Stack**: Cloudflare Workers + Workers AI + D1 Database
**Update Frequency**: Every 6 hours (automated cron job)

## 📁 Project Structure

```
cloudflare-feedback-aggregator/
├── worker.js           # Main worker script (API + Cron + AI)
├── wrangler.toml       # Cloudflare configuration
├── schema.sql          # D1 database schema
├── dummy-data.sql      # Sample feedback data
├── index.html          # Dashboard UI
├── package.json        # Node.js dependencies
├── setup.sh            # Automated setup script
└── README.md           # Full documentation
```

## ⚡ Quick Commands

```bash
# Development
wrangler dev                    # Run locally
wrangler tail                   # View logs

# Database
wrangler d1 execute feedback-db --command="SELECT * FROM raw_feedback LIMIT 10"
wrangler d1 execute feedback-db --command="SELECT * FROM consolidated_issues"

# Deployment
wrangler deploy                 # Deploy to Cloudflare

# Manual Processing
curl https://your-worker-url.workers.dev/api/process
```

## 🗄️ Database Tables

### 1. raw_feedback
Stores original feedback from all sources
- `id`, `source`, `author`, `content`, `timestamp`, `url`, `processed`

### 2. analyzed_issues
AI-analyzed feedback with classification
- `id`, `feedback_id`, `is_issue`, `keywords`, `summary`

### 3. consolidated_issues
Grouped issues (MULTIPLE feedback items → SINGLE issue)
- `id`, `title` (AI summary, NOT keywords!), `keywords`, `count_last_30_days`, `weighted_score`, `status`
- **Important**: One consolidated issue can contain many feedback items
- Example: 8 feedback items with matching keywords become 1 consolidated issue
- Title uses AI-generated summary for readability

### 4. status_changes
Audit log for status updates
- `id`, `issue_id`, `old_status`, `new_status`, `changed_at`

## 🎨 Issue Statuses

| Status | Description | UI Color |
|--------|-------------|----------|
| `new` | Newly detected, not addressed | 🟡 Yellow |
| `in-progress` | Team is actively working on it | 🔵 Blue |
| `fixed` | Issue has been resolved | 🟢 Green |

**Status Flow**: New → In Progress → Fixed

## 📊 Weighted Scoring Formula

```javascript
// Base score from source weights
base_score = Σ(source_weight) × count_last_30_days

// Bonus for cross-channel reporting
cross_channel_bonus = unique_reporters_count × 2

// Final weighted score
weighted_score = base_score + cross_channel_bonus

Source Weights:
┌─────────────────────┬────────┐
│ Source              │ Weight │
├─────────────────────┼────────┤
│ Support Tickets     │   5.0  │
│ Email               │   4.0  │
│ GitHub Issues       │   3.0  │
│ Discord             │   2.0  │
│ Twitter             │   1.0  │
└─────────────────────┴────────┘

Example Calculation:
- 3 support tickets (5×3=15) 
- 2 GitHub issues (3×2=6)
- 1 email (4×1=4)
- Total: 6 feedback items in last 30 days
- Base Score: (15+6+4) = 25 per occurrence × 6 = 150
- 4 unique people reported this issue
- Cross-channel bonus: 4 × 2 = 8
- Final Score: 150 + 8 = 158

This accounts for both frequency AND cross-channel reporting!
```

## 🤖 AI Analysis Process

**Model**: Llama 3.1 (via Workers AI)

**Tasks**:
1. **Classification**: Is this an issue or general feedback?
2. **Keyword Extraction**: Identify relevant categories
3. **Summarization**: Generate brief description

**Keywords Detected**:
- deployment, UI, API, authentication, database
- performance, cron, worker, documentation, SSL
- timeout, error, custom-domain, rollback, D1

## 🌐 API Reference

### GET Endpoints

```bash
# Statistics
curl https://your-worker-url.workers.dev/api/stats

# All issues
curl https://your-worker-url.workers.dev/api/issues

# Filtered by status
curl https://your-worker-url.workers.dev/api/issues/new
curl https://your-worker-url.workers.dev/api/issues/in-progress
curl https://your-worker-url.workers.dev/api/issues/fixed
```

### POST Endpoints

```bash
# Update issue status
curl -X POST https://your-worker-url.workers.dev/api/update-status \
  -H "Content-Type: application/json" \
  -d '{"issueId": 1, "newStatus": "in-progress"}'

# Trigger manual processing
curl -X POST https://your-worker-url.workers.dev/api/process
```

## 📈 Sample API Response

```json
{
  "id": 1,
  "title": "Deployment + Custom-domain + Timeout Issues",
  "keywords": ["deployment", "custom-domain", "timeout"],
  "first_seen": "2024-01-15T10:30:00Z",
  "last_seen": "2024-01-18T14:20:00Z",
  "count_last_30_days": 12,
  "unique_reporters_count": 7,
  "unique_reporters": ["john_doe", "sarah_chen", "@clouddev_2024", "octocat_dev", "CloudFanatic#1234", "cto@startup.io", "admin@business.org"],
  "weighted_score": 248,
  "score_at_status_change": 180,
  "status": "in-progress",
  "related_feedback_ids": [1, 5, 12, 18, 22, 25, 28, 31, 35, 40, 43, 47]
}
```

**Score Breakdown:**
- 12 occurrences across sources (3 support, 4 email, 3 GitHub, 2 Discord)
- Base: (3×5 + 4×4 + 3×3 + 2×2) × 12 = 240
- Cross-channel: 7 unique reporters × 2 = 14
- Total: 254
- Score increased by 74 since marked "in-progress" (254 - 180)

## 🔄 Processing Flow

```
┌─────────────────────┐
│ Cron Trigger        │ Every 6 hours
│ (0 */6 * * *)       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Get Unprocessed     │ SELECT * FROM raw_feedback
│ Feedback (50 max)   │ WHERE processed = 0
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Workers AI Analysis │ For each feedback:
│ (@cf/meta/llama)    │ - Is issue? (yes/no)
│                     │ - Extract keywords
│                     │ - Generate summary
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Store Analysis      │ INSERT INTO analyzed_issues
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Group by Keywords   │ Group similar issues
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Calculate Scores    │ weight × count × frequency
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Update/Create       │ consolidated_issues
│ Consolidated Issues │
└─────────────────────┘
```

## 🎯 Dashboard Features

**Issue Consolidation**: Multiple related feedback items are automatically grouped into single consolidated issues based on keyword similarity.

Example:
- 5 support tickets + 3 GitHub issues + 2 emails about "custom domain 522 errors"
- → 1 consolidated issue with 10 related feedback items
- Title: AI-generated summary (readable), not "Custom-domain + Timeout Issues"
- Keywords shown separately as tags

**3 Main Views:**

1. **New Issues** (Unaddressed)
   - Never been worked on
   - Sorted by weighted score
   - Actions: Start Working | Mark as Fixed

2. **In Progress** (Being Worked On)
   - Currently being addressed
   - **Shows score increase since status changed from "New" to "In Progress"**
   - Example: "Score: 250 ↑ +45 since in-progress started"
   - This is NOT a separate "trending" state - it's still "in-progress"
   - Action: Mark as Fixed

3. **Fixed Issues** (Completed)
   - Issues that have been resolved
   - Sorted by most recent

**Key Metrics Displayed:**
- **Issue Title**: AI-generated summary (human-readable, not keyword list)
- **Keywords**: Auto-extracted tags shown separately below title
- **Related Feedback Count**: How many individual feedback items consolidated into this issue
- **Weighted Score**: Priority based on source + frequency + cross-channel reporting
- **Score Change** (In Progress only): How much score increased since moving from "New" to "In Progress"
- **Unique Reporters**: Number of different people reporting this issue
- **Occurrences**: Total feedback items in last 30 days

**Important Note**: Score increase is only shown for "In Progress" issues. This is not a separate "trending" state - the issue remains in "in-progress" status while the UI shows if it's getting more reports.

## 🛠️ Customization Tips

### Change Cron Frequency
```toml
# In wrangler.toml
[triggers]
crons = ["0 */3 * * *"]  # Every 3 hours
crons = ["0 0 * * *"]    # Daily at midnight
crons = ["*/30 * * * *"] # Every 30 minutes
```

### Add New Keywords
```javascript
// In worker.js
const KEYWORD_CATEGORIES = [
  'deployment', 'UI', 'API',
  'billing',        // Add new
  'integration',    // Add new
  'security'        // Add new
];
```

### Modify Source Weights
```javascript
// In worker.js
const SOURCE_WEIGHTS = {
  support: 5.0,
  email: 4.0,
  github: 3.0,
  discord: 2.0,
  twitter: 1.0,
  slack: 3.5     // Add new source
};
```

## 📊 Monitoring

### Check Processing Status
```bash
wrangler d1 execute feedback-db --command="
  SELECT 
    source,
    COUNT(*) as total,
    SUM(CASE WHEN processed = 1 THEN 1 ELSE 0 END) as processed
  FROM raw_feedback
  GROUP BY source
"
```

### View Top Issues
```bash
wrangler d1 execute feedback-db --command="
  SELECT title, weighted_score, count_last_30_days, status
  FROM consolidated_issues
  ORDER BY weighted_score DESC
  LIMIT 10
"
```

### Check Recent Activity
```bash
wrangler d1 execute feedback-db --command="
  SELECT * FROM status_changes
  ORDER BY changed_at DESC
  LIMIT 10
"
```

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| Worker not deploying | Check `wrangler.toml` syntax, verify database_id |
| AI not responding | Check Workers AI quota, ensure model name is correct |
| UI shows no data | Verify API_URL in index.html, check CORS headers |
| Database locked | Only one write at a time, add retry logic |
| Cron not firing | Check Cloudflare dashboard > Workers > Triggers |

## 💰 Cost Estimate (Free Tier)

| Resource | Free Tier Limit | Prototype Usage |
|----------|----------------|-----------------|
| Workers Requests | 100K/day | ~400/day (6hr cron + API) |
| Workers AI | 10K neurons/day | ~500/day (50 items × 4 runs) |
| D1 Storage | 5GB | <10MB |
| D1 Reads | 5M/day | ~1K/day |
| D1 Writes | 100K/day | ~200/day |

**Total: $0/month** ✅

## 📚 Resources

- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Workers AI Docs](https://developers.cloudflare.com/workers-ai/)
- [D1 Database Docs](https://developers.cloudflare.com/d1/)
- [Wrangler CLI Docs](https://developers.cloudflare.com/workers/wrangler/)

---

**Need Help?** Check the full README.md or Cloudflare community forums.
