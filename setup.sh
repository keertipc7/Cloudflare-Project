#!/bin/bash

# Cloudflare Feedback Aggregator - Quick Setup Script
# This script automates the deployment process

echo "🚀 Cloudflare Feedback Aggregator - Setup Script"
echo "================================================"
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null
then
    echo "❌ Wrangler CLI not found!"
    echo "Please install it first: npm install -g wrangler"
    exit 1
fi

echo "✅ Wrangler CLI found"
echo ""

# Step 1: Login to Cloudflare
echo "📝 Step 1: Authenticating with Cloudflare..."
wrangler login
echo ""

# Step 2: Create D1 Database
echo "🗄️ Step 2: Creating D1 Database..."
echo "Please run: wrangler d1 create feedback-db"
echo "Then copy the database_id and update it in wrangler.toml"
echo ""
read -p "Press enter when you've updated wrangler.toml with your database_id..."
echo ""

# Step 3: Initialize Database Schema
echo "📊 Step 3: Initializing database schema..."
wrangler d1 execute feedback-db --file=schema.sql
if [ $? -eq 0 ]; then
    echo "✅ Database schema created successfully"
else
    echo "❌ Failed to create database schema"
    exit 1
fi
echo ""

# Step 4: Load Dummy Data
echo "📥 Step 4: Loading dummy data..."
wrangler d1 execute feedback-db --file=dummy-data.sql
if [ $? -eq 0 ]; then
    echo "✅ Dummy data loaded successfully"
else
    echo "❌ Failed to load dummy data"
    exit 1
fi
echo ""

# Step 5: Deploy Worker
echo "🚢 Step 5: Deploying worker..."
wrangler deploy
if [ $? -eq 0 ]; then
    echo "✅ Worker deployed successfully"
else
    echo "❌ Failed to deploy worker"
    exit 1
fi
echo ""

# Step 6: Get worker URL
echo "🔗 Step 6: Getting worker URL..."
WORKER_URL=$(wrangler deployments list 2>/dev/null | grep -oP 'https://[^\s]+' | head -1)
if [ -z "$WORKER_URL" ]; then
    echo "⚠️  Could not automatically detect worker URL"
    echo "Please check your Cloudflare dashboard for the URL"
else
    echo "✅ Worker URL: $WORKER_URL"
fi
echo ""

# Step 7: Process initial data
echo "⚙️ Step 7: Processing initial data with AI..."
if [ ! -z "$WORKER_URL" ]; then
    curl -X POST "$WORKER_URL/api/process"
    echo ""
    echo "✅ Initial processing triggered"
else
    echo "⚠️  Please manually trigger processing by visiting:"
    echo "https://your-worker-url.workers.dev/api/process"
fi
echo ""

# Final Instructions
echo "================================================"
echo "✨ Setup Complete!"
echo "================================================"
echo ""
echo "Next Steps:"
echo "1. Update API_URL in index.html with your worker URL:"
if [ ! -z "$WORKER_URL" ]; then
    echo "   const API_URL = '$WORKER_URL';"
else
    echo "   const API_URL = 'https://your-worker-url.workers.dev';"
fi
echo ""
echo "2. Deploy the UI to Cloudflare Pages or open index.html locally"
echo ""
echo "3. Visit the dashboard to see your aggregated feedback!"
echo ""
echo "API Endpoints:"
if [ ! -z "$WORKER_URL" ]; then
    echo "  - Stats: $WORKER_URL/api/stats"
    echo "  - New Issues: $WORKER_URL/api/issues/new"
    echo "  - Pending: $WORKER_URL/api/issues/pending"
    echo "  - Trending: $WORKER_URL/api/issues/trending"
    echo "  - Resolved: $WORKER_URL/api/issues/resolved"
else
    echo "  - Stats: https://your-worker-url.workers.dev/api/stats"
    echo "  - Issues: https://your-worker-url.workers.dev/api/issues/new"
fi
echo ""
echo "For local development:"
echo "  wrangler dev"
echo ""
echo "To view logs:"
echo "  wrangler tail"
echo ""
echo "================================================"
