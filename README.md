# Cloudflare Feedback Aggregator Prototype

A lean prototype for aggregating and analyzing customer feedback from multiple sources using Cloudflare's Developer Platform.

## 🏗️ Architecture

**Cloudflare Products Used:**
1. **Cloudflare Workers** - Cron jobs, API endpoints, orchestration
2. **Workers AI** - AI-powered issue classification and keyword extraction
3. **D1 Database** - Serverless SQL database for storing feedback and issues
4. **Cloudflare Pages** - Static UI hosting (optional)

## 📊 Data Flow

```
Data Sources (GitHub, Discord, Email, Twitter, Support)
    ↓
Scraping (Every 6 hours via Cron)
    ↓
Store in D1 Database (raw_feedback table)
    ↓
AI Analysis (Workers AI - Llama 3.1)
    ├─ Is it an issue?
    ├─ Extract keywords
    └─ Generate summary
    ↓
Store Analysis (analyzed_issues table)
    ↓
Consolidation & Grouping
    ├─ Group by keyword similarity
    ├─ Multiple feedback items → Single consolidated issue
    ├─ Issue title = AI-generated summary (NOT keywords)
    ├─ Track unique reporters across channels
    └─ Calculate weighted scores
    ↓
Store Consolidated Issues (consolidated_issues table)
    ↓
Display in UI Dashboard (3 views: New, In Progress, Fixed)
```

## 🔄 Issue Consolidation

**Key Concept**: Multiple feedback items are automatically consolidated into single issues.

### How It Works

1. **AI analyzes each feedback item** and extracts keywords (e.g., "deployment", "timeout", "custom-domain")

2. **Feedback with matching keywords is grouped together**:
   ```
   Feedback #1 (Support): "Custom domain deployment timing out with 522"
   Keywords: ["deployment", "timeout", "custom-domain"]
   
   Feedback #5 (GitHub): "522 errors when deploying to custom domains"
   Keywords: ["deployment", "timeout", "custom-domain"]
   
   Feedback #12 (Email): "Deployment fails - 522 gateway timeout on my domain"
   Keywords: ["deployment", "timeout", "custom-domain"]
   
   → All consolidated into 1 issue
   ```

3. **Issue title uses AI-generated summary** (NOT keywords):
   - ✅ **Good**: "Deployment fails with custom domains causing 522 timeout errors"
   - ❌ **Bad**: "Deployment + Timeout + Custom-domain Issues"

4. **The summary comes from the most recent feedback** in the group (has best context)

5. **Consolidated issue tracks**:
   - All related feedback IDs
   - Unique reporters (people who reported it)
   - Count of occurrences in last 30 days
   - Weighted score based on sources

### Real Example

```
8 feedback items → 1 consolidated issue

Sources:
- 3 Support tickets (john_doe, sarah_chen, mike_wilson)
- 2 GitHub issues (octocat_dev, code_master_99)
- 2 Discord messages (CloudFanatic#1234, WebDev2024#7777)
- 1 Email (admin@business.org)

Consolidated Issue:
- Title: "Deployment fails with custom domains causing 522 timeout errors"
- Keywords: ["deployment", "timeout", "custom-domain"]
- Count: 8 occurrences in last 30 days
- Unique reporters: 7 people
- Weighted score: 250 (varies based on sources)
- Related IDs: [1, 5, 12, 18, 22, 25, 28, 31]
```

## 🎯 Weighted Scoring

```
Base Score = Σ(source_weight) × count_last_30_days
Cross-Channel Bonus = unique_reporters_count × 2
Final Score = Base Score + Cross-Channel Bonus

Source Weights:
- Support Tickets: 5.0
- Email: 4.0
- GitHub Issues: 3.0
- Discord: 2.0
- Twitter: 1.0

Example:
- 3 support tickets (5×3=15) + 2 GitHub issues (3×2=6) + 1 email (4×1=4)
- Base Score: (15+6+4) × 8 occurrences = 200
- 5 unique people reported across channels: 5 × 2 = 10
- Final Score: 200 + 10 = 210
```

## 🚀 Setup Instructions

### Prerequisites
- Node.js 16+ installed
- Cloudflare account (free tier works!)
- Wrangler CLI installed: `npm install -g wrangler`

### Step 1: Authenticate with Cloudflare
```bash
wrangler login
```

### Step 2: Create D1 Database
```bash
wrangler d1 create feedback-db
```

Copy the `database_id` from the output and update it in `wrangler.toml`:
```toml
[[d1_databases]]
binding = "DB"
database_name = "feedback-db"
database_id = "YOUR_DATABASE_ID_HERE"
```

### Step 3: Initialize Database Schema
```bash
wrangler d1 execute feedback-db --file=schema.sql
```

### Step 4: Load Dummy Data
```bash
wrangler d1 execute feedback-db --file=dummy-data.sql
```

### Step 5: Deploy the Worker
```bash
wrangler deploy
```

The worker will be deployed and you'll get a URL like: `https://feedback-aggregator.YOUR-SUBDOMAIN.workers.dev`

### Step 6: Trigger Initial Processing
```bash
curl https://feedback-aggregator.YOUR-SUBDOMAIN.workers.dev/api/process
```

This will process all the dummy data through the AI pipeline.

### Step 7: Deploy the UI

**Option A: Using Cloudflare Pages**
1. Create a new Pages project in the Cloudflare dashboard
2. Upload the `index.html` file
3. Update the `API_URL` in `index.html` to your worker URL
4. Deploy!

**Option B: Local Testing**
1. Update `API_URL` in `index.html` to `http://localhost:8787`
2. Run: `wrangler dev`
3. Open `index.html` in your browser

## 📱 Dashboard Features

The dashboard displays **consolidated issues** (multiple feedback items grouped into single issues) in 3 categories:

**Important**: Each issue card shows:
- **Title**: AI-generated summary (not keywords) - readable description of the issue
- **Keywords**: Auto-extracted tags for categorization  
- **Related Feedback**: Count of individual feedback items consolidated into this issue

1. **New Issues** - Unaddressed issues (status: 'new')
   - Never been worked on
   - Sorted by weighted score
   - Actions: Start Working (In Progress) | Mark as Fixed

2. **In Progress** - Currently being worked on (status: 'in-progress')
   - Team is actively addressing these
   - **Score increase is shown**: Displays how much the score has increased since the issue was moved from "New" to "In Progress"
   - Example display: "Score: 250 ↑ +45 since in-progress started"
   - Helps identify issues that are gaining more reports even while being worked on
   - Action: Mark as Fixed

3. **Fixed Issues** - Completed work (status: 'fixed')
   - Issues that have been resolved
   - Sorted by most recent

### Special Features
- **AI-Generated Titles**: Issue titles are AI-generated summaries, not keyword lists - making them easy to read and understand
- **Issue Consolidation**: Multiple related feedback items are automatically grouped into a single issue based on keyword similarity
- **Score Change Tracking**: For "In Progress" issues, the UI shows how much the score has increased since the status changed from "New" to "In Progress". This helps identify issues that are escalating even while being worked on.
- **Unique Reporters**: Track how many different people reported the same issue across channels
- **Cross-Channel Detection**: Issues reported by same person across multiple channels get visibility boost

## 🔄 Automated Processing

The worker runs automatically every 6 hours via cron trigger:
```
0 */6 * * *  (00:00, 06:00, 12:00, 18:00 UTC)
```

You can also manually trigger processing:
```bash
curl https://your-worker-url.workers.dev/api/process
```

## 🧪 Testing with Dummy Data

The prototype includes 70 realistic feedback items from all sources:
- **15** Support Tickets (highest priority)
- **12** Email feedbacks
- **14** GitHub Issues  
- **16** Discord messages
- **13** Tweets

These simulate real feedback about common platform issues:
- **Custom Domain 522 Errors** (reported across all channels by multiple people)
- **Cron Job Reliability Issues** (high frequency, cross-channel)
- **D1 Database Performance** (multiple unique reporters)
- **UI/UX Confusion** (widespread feedback)
- **API Authentication Problems** (critical support tickets)

The data demonstrates:
- Cross-channel reporting (same people reporting on multiple platforms)
- Issue clustering by keywords
- Score increases when in-progress issues get more reports
- Unique reporter tracking

## 📊 API Endpoints

```
GET  /api/stats              - Get overall statistics
GET  /api/issues             - Get all issues
GET  /api/issues/new         - Get new issues
GET  /api/issues/in-progress - Get in-progress issues
GET  /api/issues/fixed       - Get fixed issues
POST /api/update-status      - Update issue status
POST /api/process            - Manually trigger processing
```

## 🔍 Database Queries

View data directly:
```bash
# List all raw feedback
wrangler d1 execute feedback-db --command="SELECT * FROM raw_feedback LIMIT 10"

# View consolidated issues
wrangler d1 execute feedback-db --command="SELECT * FROM consolidated_issues ORDER BY weighted_score DESC"

# Check AI analysis results
wrangler d1 execute feedback-db --command="SELECT * FROM analyzed_issues WHERE is_issue = 1"
```

## 💡 Customization

### Add More Sources
Edit `worker.js` and add scraping logic for new sources. Remember to update `SOURCE_WEIGHTS`.

### Modify Keywords
Update `KEYWORD_CATEGORIES` in `worker.js` to add/remove categorization keywords.

### Change Cron Schedule
Edit the cron trigger in `wrangler.toml`:
```toml
[triggers]
crons = ["0 */6 * * *"]  # Every 6 hours
```

### Adjust Time Window
The default is 30 days. Change this in the consolidation logic:
```javascript
const thirtyDaysAgo = new Date();
thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30); // Change 30 to desired days
```

## 🎨 UI Customization

The UI is a single HTML file with inline CSS and JavaScript. Modify `index.html` to:
- Change colors (update gradient and theme colors)
- Add/remove dashboard sections
- Customize card layouts
- Add charts or graphs

## 📈 Scaling Considerations

**Current Limits (Free Tier):**
- Workers: 100,000 requests/day
- D1: 5GB storage, 5M reads/day, 100K writes/day
- Workers AI: 10,000 neurons/day

**For Production:**
1. Implement rate limiting for API calls
2. Add caching layer (use KV for frequently accessed data)
3. Batch AI processing for efficiency
4. Add error handling and retry logic
5. Implement user authentication
6. Add real source scrapers (replace dummy data)

## 🐛 Troubleshooting

**Worker not processing feedback:**
- Check logs: `wrangler tail`
- Verify D1 binding is correct
- Ensure AI binding is configured

**UI not loading data:**
- Check CORS headers in worker
- Verify API_URL in index.html
- Check browser console for errors

**AI analysis failing:**
- Workers AI free tier has limits
- Check model availability: `@cf/meta/llama-3.1-8b-instruct`
- Add fallback to keyword matching

## 📝 License

MIT License - Free to use and modify

## 🤝 Contributing

This is a prototype. Feel free to extend it with:
- Real source integrations (GitHub API, Discord webhooks, etc.)
- Advanced AI models for better classification
- Sentiment analysis
- Email notifications for high-priority issues
- Admin panel for manual adjustments
- Export functionality (CSV, PDF reports)

---

Built with ❤️ using Cloudflare's Developer Platform
