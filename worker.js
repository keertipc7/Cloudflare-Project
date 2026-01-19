// Cloudflare Worker - Feedback Aggregator
// Main orchestrator for scraping, analysis, and consolidation

// Source weights configuration
const SOURCE_WEIGHTS = {
  support: 5.0,
  email: 4.0,
  github: 3.0,
  discord: 2.0,
  twitter: 1.0
};

// Common keywords for categorization
const KEYWORD_CATEGORIES = [
  'deployment', 'UI', 'API', 'authentication', 'database', 
  'performance', 'cron', 'worker', 'documentation', 'SSL',
  'timeout', 'error', 'custom-domain', 'rollback', 'D1'
];

export default {
  // Cron trigger - runs every 6 hours
  async scheduled(event, env, ctx) {
    console.log('Starting feedback aggregation job');
    
    try {
      // Step 1: Process unprocessed feedback
      await processFeedback(env);
      
      // Step 2: Consolidate similar issues
      await consolidateIssues(env);
      
      // Step 3: Update weighted scores
      await updateWeightedScores(env);
      
      console.log('Feedback aggregation completed successfully');
    } catch (error) {
      console.error('Error in scheduled job:', error);
    }
  },

  // HTTP handler for API endpoints
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // CORS headers for frontend
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // API Routes
    if (url.pathname === '/api/issues') {
      return handleGetIssues(env, corsHeaders);
    }
    
    if (url.pathname === '/api/issues/new') {
      return handleGetNewIssues(env, corsHeaders);
    }
    
    if (url.pathname === '/api/issues/in-progress') {
      return handleGetInProgressIssues(env, corsHeaders);
    }
    
    if (url.pathname === '/api/issues/fixed') {
      return handleGetFixedIssues(env, corsHeaders);
    }
    
    if (url.pathname === '/api/stats') {
      return handleGetStats(env, corsHeaders);
    }

    if (url.pathname === '/api/update-status' && request.method === 'POST') {
      return handleUpdateStatus(request, env, corsHeaders);
    }

    // Trigger manual processing
    if (url.pathname === '/api/process') {
      await processFeedback(env);
      await consolidateIssues(env);
      await updateWeightedScores(env);
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response('Not Found', { status: 404, headers: corsHeaders });
  }
};

// Process unprocessed feedback with AI
async function processFeedback(env) {
  // Get unprocessed feedback
  const { results } = await env.DB.prepare(
    'SELECT * FROM raw_feedback WHERE processed = 0 LIMIT 50'
  ).all();

  console.log(`Processing ${results.length} feedback items`);

  for (const feedback of results) {
    try {
      // Use Workers AI for analysis
      const analysis = await analyzeWithAI(env, feedback.content);
      
      if (analysis.isIssue) {
        // Store analyzed issue
        await env.DB.prepare(
          `INSERT INTO analyzed_issues (feedback_id, is_issue, keywords, summary)
           VALUES (?, ?, ?, ?)`
        ).bind(
          feedback.id,
          1,
          JSON.stringify(analysis.keywords),
          analysis.summary
        ).run();
      }

      // Mark as processed
      await env.DB.prepare(
        'UPDATE raw_feedback SET processed = 1 WHERE id = ?'
      ).bind(feedback.id).run();

    } catch (error) {
      console.error(`Error processing feedback ${feedback.id}:`, error);
    }
  }
}

// AI analysis using Workers AI
async function analyzeWithAI(env, content) {
  const prompt = `Analyze this customer feedback and determine:
1. Is this describing an issue/problem? (yes/no)
2. Extract relevant keywords from this list: ${KEYWORD_CATEGORIES.join(', ')}
3. Provide a brief 1-sentence summary

Feedback: "${content}"

Respond in JSON format:
{
  "isIssue": true/false,
  "keywords": ["keyword1", "keyword2"],
  "summary": "brief summary"
}`;

  try {
    const response = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
      messages: [
        { role: 'system', content: 'You are a helpful assistant that analyzes customer feedback. Always respond with valid JSON only.' },
        { role: 'user', content: prompt }
      ],
      max_tokens: 256
    });

    // Parse AI response
    const text = response.response || JSON.stringify(response);
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        isIssue: parsed.isIssue === true || parsed.isIssue === 'true',
        keywords: Array.isArray(parsed.keywords) ? parsed.keywords : [],
        summary: parsed.summary || content.substring(0, 100)
      };
    }
  } catch (error) {
    console.error('AI analysis error:', error);
  }

  // Fallback: simple keyword matching
  const keywords = KEYWORD_CATEGORIES.filter(kw => 
    content.toLowerCase().includes(kw.toLowerCase())
  );
  
  const isIssue = keywords.length > 0 || 
    /(error|fail|bug|issue|problem|broken|not working)/i.test(content);

  return {
    isIssue,
    keywords: keywords.slice(0, 3),
    summary: content.substring(0, 100)
  };
}

// Consolidate similar issues based on keywords
async function consolidateIssues(env) {
  // Get all analyzed issues that aren't consolidated yet
  const { results: issues } = await env.DB.prepare(`
    SELECT ai.*, rf.source, rf.timestamp, rf.author, rf.id as feedback_id
    FROM analyzed_issues ai
    JOIN raw_feedback rf ON ai.feedback_id = rf.id
    WHERE ai.is_issue = 1
  `).all();

  // Group by keyword similarity
  const groups = {};
  
  for (const issue of issues) {
    const keywords = JSON.parse(issue.keywords || '[]');
    const keySignature = keywords.sort().join('|') || 'uncategorized';
    
    if (!groups[keySignature]) {
      groups[keySignature] = [];
    }
    groups[keySignature].push(issue);
  }

  // Create or update consolidated issues
  for (const [signature, groupIssues] of Object.entries(groups)) {
    const keywords = signature.split('|').filter(k => k);
    
    // Use the most recent summary for the title (most recent feedback likely has best context)
    const mostRecentIssue = groupIssues.reduce((latest, current) => 
      current.timestamp > latest.timestamp ? current : latest
    );
    const title = generateTitle(keywords, mostRecentIssue.summary);
    
    // Check if this consolidated issue exists
    const { results: existing } = await env.DB.prepare(
      'SELECT * FROM consolidated_issues WHERE keywords = ?'
    ).bind(JSON.stringify(keywords)).all();

    const feedbackIds = groupIssues.map(i => i.feedback_id);
    
    // Get unique reporters (people reporting similar issues across channels)
    const uniqueReporters = [...new Set(groupIssues.map(i => i.author).filter(a => a))];
    const uniqueReportersCount = uniqueReporters.length;
    
    const firstSeen = groupIssues.reduce((min, i) => 
      i.timestamp < min ? i.timestamp : min, groupIssues[0].timestamp
    );
    const lastSeen = groupIssues.reduce((max, i) => 
      i.timestamp > max ? i.timestamp : max, groupIssues[0].timestamp
    );

    // Count only issues from last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const countLast30Days = groupIssues.filter(i => 
      new Date(i.timestamp) > thirtyDaysAgo
    ).length;

    if (existing.length > 0) {
      // Update existing
      const oldScore = existing[0].weighted_score;
      const scoreAtChange = existing[0].score_at_status_change || oldScore;
      
      await env.DB.prepare(`
        UPDATE consolidated_issues 
        SET last_seen = ?,
            count_last_30_days = ?,
            unique_reporters_count = ?,
            related_feedback_ids = ?,
            unique_reporters = ?,
            last_updated = CURRENT_TIMESTAMP
        WHERE id = ?
      `).bind(
        lastSeen,
        countLast30Days,
        uniqueReportersCount,
        JSON.stringify(feedbackIds),
        JSON.stringify(uniqueReporters),
        existing[0].id
      ).run();
    } else {
      // Create new
      await env.DB.prepare(`
        INSERT INTO consolidated_issues 
        (title, keywords, first_seen, last_seen, count_last_30_days, 
         unique_reporters_count, related_feedback_ids, unique_reporters, score_at_status_change)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        title,
        JSON.stringify(keywords),
        firstSeen,
        lastSeen,
        countLast30Days,
        uniqueReportersCount,
        JSON.stringify(feedbackIds),
        JSON.stringify(uniqueReporters),
        0 // Initial score_at_status_change
      ).run();
    }
  }
}

// Calculate weighted scores
async function updateWeightedScores(env) {
  const { results: issues } = await env.DB.prepare(
    'SELECT * FROM consolidated_issues'
  ).all();

  for (const issue of issues) {
    // Get all related feedback
    const feedbackIds = JSON.parse(issue.related_feedback_ids || '[]');
    
    if (feedbackIds.length === 0) continue;

    const placeholders = feedbackIds.map(() => '?').join(',');
    const { results: feedbacks } = await env.DB.prepare(
      `SELECT source FROM raw_feedback WHERE id IN (${placeholders})`
    ).bind(...feedbackIds).all();

    // Calculate base weighted score from sources
    let baseScore = 0;
    for (const fb of feedbacks) {
      baseScore += SOURCE_WEIGHTS[fb.source] || 1;
    }

    // Multiply by count for amplification
    let weightedScore = baseScore * issue.count_last_30_days;
    
    // Add bonus for unique reporters across channels (cross-channel reporting is more significant)
    // This accounts for people reporting similar issues across different channels
    const uniqueReportersBonus = issue.unique_reporters_count * 2;
    weightedScore += uniqueReportersBonus;

    await env.DB.prepare(
      'UPDATE consolidated_issues SET weighted_score = ? WHERE id = ?'
    ).bind(weightedScore, issue.id).run();
  }
}

// Generate a title from keywords
function generateTitle(keywords, summary) {
  // Use AI-generated summary as the title for better readability
  // Fallback to keywords if summary is not available
  if (summary && summary.trim().length > 0) {
    let cleanSummary = summary.trim();
    
    // Remove any quotes that AI might have added
    cleanSummary = cleanSummary.replace(/^["']|["']$/g, '');
    
    // Ensure it starts with capital letter
    cleanSummary = cleanSummary.charAt(0).toUpperCase() + cleanSummary.slice(1);
    
    // Limit to 120 characters for better UI display
    if (cleanSummary.length > 120) {
      cleanSummary = cleanSummary.substring(0, 117) + '...';
    }
    
    return cleanSummary;
  }
  
  // Fallback: use keywords if no summary
  if (keywords.length === 0) {
    return 'Uncategorized Issue';
  }
  return keywords.map(k => 
    k.charAt(0).toUpperCase() + k.slice(1)
  ).join(' + ') + ' Issues';
}

// API Handlers
async function handleGetIssues(env, headers) {
  const { results } = await env.DB.prepare(
    'SELECT * FROM consolidated_issues ORDER BY weighted_score DESC'
  ).all();
  
  return new Response(JSON.stringify(results), {
    headers: { ...headers, 'Content-Type': 'application/json' }
  });
}

async function handleGetNewIssues(env, headers) {
  const { results } = await env.DB.prepare(
    "SELECT * FROM consolidated_issues WHERE status = 'new' ORDER BY weighted_score DESC"
  ).all();
  
  return new Response(JSON.stringify(results), {
    headers: { ...headers, 'Content-Type': 'application/json' }
  });
}

async function handleGetInProgressIssues(env, headers) {
  const { results } = await env.DB.prepare(
    "SELECT * FROM consolidated_issues WHERE status = 'in-progress' ORDER BY weighted_score DESC"
  ).all();
  
  return new Response(JSON.stringify(results), {
    headers: { ...headers, 'Content-Type': 'application/json' }
  });
}

async function handleGetFixedIssues(env, headers) {
  const { results } = await env.DB.prepare(
    "SELECT * FROM consolidated_issues WHERE status = 'fixed' ORDER BY last_seen DESC"
  ).all();
  
  return new Response(JSON.stringify(results), {
    headers: { ...headers, 'Content-Type': 'application/json' }
  });
}

async function handleGetStats(env, headers) {
  const stats = await env.DB.batch([
    env.DB.prepare("SELECT COUNT(*) as count FROM consolidated_issues WHERE status = 'new'"),
    env.DB.prepare("SELECT COUNT(*) as count FROM consolidated_issues WHERE status = 'in-progress'"),
    env.DB.prepare("SELECT COUNT(*) as count FROM consolidated_issues WHERE status = 'fixed'"),
    env.DB.prepare("SELECT COUNT(*) as count FROM raw_feedback"),
    env.DB.prepare("SELECT COUNT(*) as count FROM raw_feedback WHERE processed = 1")
  ]);

  const response = {
    newIssues: stats[0].results[0].count,
    inProgressIssues: stats[1].results[0].count,
    fixedIssues: stats[2].results[0].count,
    totalFeedback: stats[3].results[0].count,
    processedFeedback: stats[4].results[0].count
  };

  return new Response(JSON.stringify(response), {
    headers: { ...headers, 'Content-Type': 'application/json' }
  });
}

async function handleUpdateStatus(request, env, headers) {
  const { issueId, newStatus } = await request.json();
  
  // Get current issue
  const { results } = await env.DB.prepare(
    'SELECT * FROM consolidated_issues WHERE id = ?'
  ).bind(issueId).all();
  
  if (results.length === 0) {
    return new Response(JSON.stringify({ error: 'Issue not found' }), {
      status: 404,
      headers: { ...headers, 'Content-Type': 'application/json' }
    });
  }

  const oldStatus = results[0].status;
  const currentScore = results[0].weighted_score;

  // Update status and capture score at status change
  await env.DB.prepare(
    `UPDATE consolidated_issues 
     SET status = ?, 
         score_at_status_change = ?,
         last_updated = CURRENT_TIMESTAMP 
     WHERE id = ?`
  ).bind(newStatus, currentScore, issueId).run();

  // Log status change
  await env.DB.prepare(
    `INSERT INTO status_changes (issue_id, old_status, new_status, old_score, new_score)
     VALUES (?, ?, ?, ?, ?)`
  ).bind(issueId, oldStatus, newStatus, currentScore, currentScore).run();

  return new Response(JSON.stringify({ success: true }), {
    headers: { ...headers, 'Content-Type': 'application/json' }
  });
}