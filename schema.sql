-- Cloudflare D1 Database Schema for Feedback Aggregator

-- Raw feedback from all sources
CREATE TABLE IF NOT EXISTS raw_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source TEXT NOT NULL, -- support, email, github, discord, twitter
    author TEXT,
    content TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    url TEXT,
    raw_json TEXT,
    processed BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_raw_feedback_source ON raw_feedback(source);
CREATE INDEX idx_raw_feedback_timestamp ON raw_feedback(timestamp);
CREATE INDEX idx_raw_feedback_processed ON raw_feedback(processed);

-- AI-analyzed issues
CREATE TABLE IF NOT EXISTS analyzed_issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    feedback_id INTEGER NOT NULL,
    is_issue BOOLEAN NOT NULL,
    keywords TEXT, -- JSON array: ["deployment", "UI", "API"]
    summary TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (feedback_id) REFERENCES raw_feedback(id)
);

CREATE INDEX idx_analyzed_issues_feedback ON analyzed_issues(feedback_id);
CREATE INDEX idx_analyzed_issues_is_issue ON analyzed_issues(is_issue);

-- Consolidated/grouped issues
CREATE TABLE IF NOT EXISTS consolidated_issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    keywords TEXT, -- JSON array
    first_seen DATETIME NOT NULL,
    last_seen DATETIME NOT NULL,
    count_last_30_days INTEGER DEFAULT 1,
    weighted_score REAL DEFAULT 0,
    status TEXT DEFAULT 'new', -- new, pending, resolved, deployed
    related_feedback_ids TEXT, -- JSON array of feedback IDs
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consolidated_status ON consolidated_issues(status);
CREATE INDEX idx_consolidated_score ON consolidated_issues(weighted_score DESC);
CREATE INDEX idx_consolidated_last_seen ON consolidated_issues(last_seen);

-- Track status changes for trending analysis
CREATE TABLE IF NOT EXISTS status_changes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    issue_id INTEGER NOT NULL,
    old_status TEXT,
    new_status TEXT,
    old_score REAL,
    new_score REAL,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (issue_id) REFERENCES consolidated_issues(id)
);

CREATE INDEX idx_status_changes_issue ON status_changes(issue_id);
CREATE INDEX idx_status_changes_date ON status_changes(changed_at);
