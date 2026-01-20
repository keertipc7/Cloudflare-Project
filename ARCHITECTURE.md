# Architecture Diagram - Cloudflare Feedback Aggregator
## 📑 Contents

- [System Architecture](#system-architecture)
- [Data Processing Pipeline](#data-processing-pipeline)
- [Database Schema Relationships](#database-schema-relationships)
- [Score Calculation Flow](#score-calculation-flow)
- [Status Lifecycle](#status-lifecycle)
- [Cron Schedule Visualization](#cron-schedule-visualization)
- [Issue Consolidation Logic](#issue-consolidation-logic)

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DATA SOURCES (External)                            │
│                                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Support  │  │  Email   │  │  GitHub  │  │ Discord  │  │ Twitter  │    │
│  │ Tickets  │  │(Forward) │  │  Issues  │  │          │  │          │    │
│  │ Weight:5 │  │ Weight:4 │  │ Weight:3 │  │ Weight:2 │  │ Weight:1 │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       └─────────────┴─────────────┴──────────────┴─────────────┘           │
│                                   │                                         │
└───────────────────────────────────┼─────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      CLOUDFLARE WORKER (Orchestration)                       │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Cron Trigger (Every 6 hours: 0 */6 * * *)                          │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐   │   │
│  │  │ Scrape API │─→│ Store DB   │─→│ AI Process │─→│Consolidate │   │   │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  HTTP API Endpoints                                                  │   │
│  │  • GET  /api/stats                                                  │   │
│  │  • GET  /api/issues/{new|in-progress|fixed}                        │   │
│  │  • POST /api/update-status                                         │   │
│  │  • POST /api/process (manual trigger)                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└───────┬──────────────────────────────────┬──────────────────────────────────┘
        │                                  │
        ▼                                  ▼
┌────────────────────┐          ┌──────────────────────┐
│   WORKERS AI       │          │    D1 DATABASE       │
│                    │          │                      │
│  ┌──────────────┐  │          │  ┌────────────────┐ │
│  │ Llama 3.1    │  │          │  │ raw_feedback   │ │
│  │ 8B Instruct  │  │          │  ├────────────────┤ │
│  └──────────────┘  │          │  │ analyzed_issues│ │
│                    │          │  ├────────────────┤ │
│  Tasks:            │          │  │ consolidated   │ │
│  • Classification  │          │  │ _issues        │ │
│  • Keyword Extract │          │  ├────────────────┤ │
│  • Summarization   │          │  │ status_changes │ │
│                    │          │  └────────────────┘ │
└────────────────────┘          └──────────────────────┘
                                          │
                                          ▼
                              ┌──────────────────────┐
                              │  CONSOLIDATION       │
                              │  (Issue Grouping)    │
                              │                      │
                              │  CRITICAL: Multiple  │
                              │  feedback items are  │
                              │  consolidated into   │
                              │  single issues!      │
                              │                      │
                              │  Example:            │
                              │  15 feedback items   │
                              │  (5 support, 4 email,│
                              │   3 GitHub, 2 Discord│
                              │   1 Twitter)         │
                              │  ↓                   │
                              │  1 Consolidated Issue│
                              │                      │
                              │  Grouping Method:    │
                              │  • Match by keywords │
                              │  • Same keywords =   │
                              │    Same issue        │
                              │                      │
                              │  Issue Title:        │
                              │  • AI-generated      │
                              │    summary (NOT      │
                              │    keywords!)        │
                              │  • From most recent  │
                              │    feedback item     │
                              │                      │
                              │  Tracked Data:       │
                              │  • Unique reporters  │
                              │  • All feedback IDs  │
                              │  • Weighted score    │
                              └──────────────────────┘
                                          │
                                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CLOUDFLARE PAGES / STATIC UI                              │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         DASHBOARD (index.html)                       │   │
│  │                                                                       │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐                    │   │
│  │  │    New     │  │In Progress │  │   Fixed    │                    │   │
│  │  │   Issues   │  │   Issues   │  │   Issues   │                    │   │
│  │  │  (status:  │  │  (status:  │  │  (status:  │                    │   │
│  │  │   'new')   │  │'in-progress│  │  'fixed')  │                    │   │
│  │  │            │  │ +score Δ)  │  │            │                    │   │
│  │  └────────────┘  └────────────┘  └────────────┘                    │   │
│  │                                                                       │   │
│  │  Stats Cards:                                                        │   │
│  │  [Total Feedback: 70] [New: 5] [In Progress: 3] [Fixed: 2]        │   │
│  │                                                                       │   │
│  │  Actions: Start Working (In Progress) | Mark as Fixed              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Processing Pipeline

```
┌─────────────┐
│   INPUT     │  Raw feedback from multiple sources
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  STORAGE    │  Store in raw_feedback table (D1)
└──────┬──────┘  Fields: id, source, author, content, timestamp, url
       │
       ▼
┌─────────────┐
│ AI ANALYSIS │  Workers AI - Llama 3.1
└──────┬──────┘  1. Is this an issue? (Boolean)
       │         2. Extract keywords (Array)
       │         3. Generate summary (String)
       │
       ▼
┌─────────────┐
│  STORAGE    │  Store in analyzed_issues table
└──────┬──────┘  Fields: feedback_id, is_issue, keywords, summary
       │
       ▼
┌─────────────┐
│ GROUPING    │  Consolidate feedback into issues
└──────┬──────┘  
       │         CONSOLIDATION PROCESS:
       │         • Multiple feedback items → Single consolidated issue
       │         • Group by: Keyword similarity (exact keyword match)
       │         • Title: AI-generated summary
       │         
       │         EXAMPLE:
       │         8 feedback items about "deployment + timeout":
       │         - 3 from support tickets
       │         - 2 from GitHub issues  
       │         - 2 from Discord
       │         - 1 from email
       │         
       │         All share keywords: ["deployment", "timeout", "custom-domain"]
       │         
       │         Consolidated into 1 issue with:
       │         ✓ Title: "Deployment fails with custom domains causing 522 errors"
       │         ✓ Count: 8 occurrences
       │         ✓ Unique reporters: 6 people
       │         ✓ Related feedback IDs: [1, 5, 12, 18, 22, 25, 28, 31]
       │
       ▼
┌─────────────┐
│  SCORING    │  Calculate: Sum across channels(source_weight × count_last_30_days)
└──────┬──────┘  + unique_reporters_count × 2 (cross-channel bonus)
       │         Example: (Support(5)×3 + GitHub(3)×2 + Email(4)×1) 
       │         + 5 unique reporters×2 = 35 total
       │
       ▼
┌─────────────┐
│  STORAGE    │  Store in consolidated_issues table
└──────┬──────┘  Fields: title, keywords, count, weighted_score, status
       │
       ▼
┌─────────────┐
│   OUTPUT    │  Display in UI dashboard with 3 views: New → In Progress → Fixed
└─────────────┘
```

## Database Schema Relationships

```
┌──────────────────┐
│  raw_feedback    │
│──────────────────│
│ id (PK)          │◄──┐
│ source           │   │
│ author           │   │
│ content          │   │
│ timestamp        │   │
│ url              │   │
│ processed        │   │
└──────────────────┘   │
                       │
                       │ FK: feedback_id
                       │
                  ┌────┴──────────────┐
                  │ analyzed_issues   │
                  │───────────────────│
                  │ id (PK)           │
                  │ feedback_id (FK)  │
                  │ is_issue          │
                  │ keywords (JSON)   │
                  │ summary           │
                  └───────────────────┘
                           │
                           │ Multiple issues
                           │ can reference
                           ▼
                  ┌────────────────────┐
                  │ consolidated_issues │◄──┐
                  │────────────────────│   │
                  │ id (PK)            │   │
                  │ title              │   │
                  │ keywords (JSON)    │   │
                  │ count_last_30_days │   │
                  │ weighted_score     │   │
                  │ status             │   │
                  │ related_ids (JSON) │   │
                  └────────────────────┘   │
                                           │
                                           │ FK: issue_id
                                           │
                                      ┌────┴────────────┐
                                      │ status_changes  │
                                      │─────────────────│
                                      │ id (PK)         │
                                      │ issue_id (FK)   │
                                      │ old_status      │
                                      │ new_status      │
                                      │ changed_at      │
                                      └─────────────────┘
```

**Legend:**
- PK = Primary Key
- FK = Foreign Key
- JSON = JSON-formatted text field
- ─→ = Data flow direction
- ◄─ = Relationship/reference

## Score Calculation Flow

```
Individual Feedback Item
        │
        ├─ Source: Support Ticket → Weight: 5
        ├─ Source: Email         → Weight: 4
        ├─ Source: GitHub        → Weight: 3
        ├─ Source: Discord       → Weight: 2
        └─ Source: Twitter       → Weight: 1
                │
                ▼
        Group by Keywords
        (deployment + timeout)
                │
                ├─ Support: 3 items × 5 = 15
                ├─ GitHub:  2 items × 3 = 6
                └─ Discord: 1 item  × 2 = 2
                │
                ▼
        Total Weighted Score: 23
                │
                ▼
        Store in consolidated_issues
        Sort by score (DESC)
```

## Status Lifecycle

```
     ┌─────────┐
     │   NEW   │  ← Initial state (just detected)
     └────┬────┘
          │
          │ User marks as "Pending"
          ▼
     ┌─────────┐
     │ PENDING │  ← Being worked on
     └────┬────┘
          │
          │ User marks as "Resolved"
          ▼
     ┌─────────┐
     │RESOLVED │
     └────┬────┘

```

## Cron Schedule Visualization

```
00:00 UTC ──┐
            │ Run Processing
06:00 UTC ──┤
            │ Run Processing
12:00 UTC ──┤
            │ Run Processing
18:00 UTC ──┤
            │ Run Processing
00:00 UTC ──┘
(next day)

Each run:
1. Fetch unprocessed feedback 
2. Analyze with AI (~30 seconds for 50 items)
3. Store results in D1
4. Consolidate similar issues
5. Recalculate weighted scores
6. Update timestamps
```

## Issue Consolidation Logic

**What is Consolidation?**
Multiple individual feedback items are grouped together into a single consolidated issue based on keyword similarity.

**Example:**
```
Individual Feedback Items:
┌────────────────────────────────────────────────────────────┐
│ #1: "Deployment fails with custom domains. 522 errors"    │
│     Source: Support, Keywords: [deployment, custom-domain]│
│     Summary: "Deployment fails with custom domains..."    │
├────────────────────────────────────────────────────────────┤
│ #2: "Getting 522 timeout on custom domain deployments"    │
│     Source: GitHub, Keywords: [deployment, custom-domain] │
│     Summary: "522 timeout errors on custom domains"       │
├────────────────────────────────────────────────────────────┤
│ #3: "Custom domain not working, 522 error constantly"     │
│     Source: Discord, Keywords: [deployment, custom-domain]│
│     Summary: "Custom domain 522 errors affecting..."      │
└────────────────────────────────────────────────────────────┘
                           │
                           ▼ Consolidated by matching keywords
┌────────────────────────────────────────────────────────────┐
│              CONSOLIDATED ISSUE                            │
├────────────────────────────────────────────────────────────┤
│ Title: "Custom domain 522 errors affecting production"    │
│        (AI summary)        │
│                                                            │
│ Keywords: [deployment, custom-domain]                     │
│ Occurrences: 3 (in last 30 days)                         │
│ Unique Reporters: 3                                       │
│ Weighted Score: (5+3+2) = 10 × 3 = 30 + (3×2) = 36       │
│ Related Feedback IDs: [1, 2, 3]                          │
└────────────────────────────────────────────────────────────┘
```

**Consolidation Rules:**
1. **Grouping**: Feedback items with identical keyword sets are grouped together
2. **Title**: Uses AI-generated summary 
3. **Scoring**: Aggregates source weights × occurrence count + cross-channel bonus
4. **Updates**: When new feedback arrives with same keywords, the consolidated issue is updated:
   - Occurrence count increases
   - Weighted score recalculated
   - Last seen timestamp updated
   - If status is "in-progress", score delta is shown

---


