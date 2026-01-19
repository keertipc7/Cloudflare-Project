-- Dummy Data for Feedback Aggregator Prototype
-- Insert this after creating the schema

-- Raw feedback from various sources (simulating 30 days of data)

-- SUPPORT TICKETS (Weight: 5)
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('support', 'user_john_doe', 'Deployment fails when using custom domains. Getting 522 errors constantly.', datetime('now', '-2 days'), 'ticket://12345'),
('support', 'sarah_chen', 'Workers not executing scheduled cron jobs. Last run was 3 days ago.', datetime('now', '-1 day'), 'ticket://12346'),
('support', 'mike_wilson', 'D1 database queries timing out after recent update. Query takes >30s now.', datetime('now', '-5 days'), 'ticket://12347'),
('support', 'emma_stone', 'Cannot deploy worker - getting "script too large" error even though its only 800KB.', datetime('now', '-3 days'), 'ticket://12348'),
('support', 'alex_kim', 'Deployment rollback not working. Need to restore previous version urgently.', datetime('now', '-1 day'), 'ticket://12349'),
('support', 'lisa_park', 'Custom domain SSL certificate not provisioning. Stuck in pending state for 48 hours.', datetime('now', '-7 days'), 'ticket://12350'),
('support', 'david_brown', 'Worker CPU time limit exceeded on free plan but script is very simple.', datetime('now', '-4 days'), 'ticket://12351');

-- EMAIL (Weight: 4)
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('email', 'developer@company.com', 'The new deployment UI is confusing. Cannot find the rollback button anymore.', datetime('now', '-3 days'), 'email://msg001'),
('email', 'cto@startup.io', 'Getting 522 errors on all our Workers endpoints. This is affecting production!', datetime('now', '-2 days'), 'email://msg002'),
('email', 'team@agency.com', 'Feature request: Would love to see A/B testing support for Workers deployments.', datetime('now', '-10 days'), 'email://msg003'),
('email', 'ops@enterprise.net', 'D1 database backup and restore documentation is unclear. Need better guides.', datetime('now', '-6 days'), 'email://msg004'),
('email', 'engineer@tech.com', 'The deployment UI hangs when uploading workers with many dependencies.', datetime('now', '-4 days'), 'email://msg005'),
('email', 'support@saas.io', 'Cannot authenticate API requests. Getting invalid token errors even with fresh keys.', datetime('now', '-1 day'), 'email://msg006');

-- GITHUB ISSUES (Weight: 3)
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('github', 'octocat_dev', 'Deployment fails with custom domains - 522 timeout errors. Reproducible on all our workers.', datetime('now', '-2 days'), 'https://github.com/cloudflare/issues/5001'),
('github', 'rustacean42', 'Workers AI responses are inconsistent. Same prompt gives different results each time.', datetime('now', '-8 days'), 'https://github.com/cloudflare/issues/5002'),
('github', 'frontend_guru', 'UI bug: Dashboard doesnt update after deployment. Need to hard refresh browser.', datetime('now', '-5 days'), 'https://github.com/cloudflare/issues/5003'),
('github', 'backend_ninja', 'KV namespace binding not working in new workers. Getting undefined errors.', datetime('now', '-12 days'), 'https://github.com/cloudflare/issues/5004'),
('github', 'cloud_architect', 'Documentation missing for new D1 migration features. Examples would help.', datetime('now', '-9 days'), 'https://github.com/cloudflare/issues/5005'),
('github', 'devops_lead', 'Cron triggers not firing reliably. Missing several scheduled runs per day.', datetime('now', '-1 day'), 'https://github.com/cloudflare/issues/5006'),
('github', 'fullstack_sam', 'The new deployment UI is not intuitive. Rollback option is hidden.', datetime('now', '-3 days'), 'https://github.com/cloudflare/issues/5007');

-- DISCORD (Weight: 2)
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('discord', 'CloudFanatic#1234', 'Anyone else getting 522 errors with custom domains? Its been happening for days.', datetime('now', '-2 days'), 'discord://msg/ch001'),
('discord', 'WorkerBee#5678', 'The UI changes are kinda confusing tbh. Where did the old deploy button go?', datetime('now', '-3 days'), 'discord://msg/ch002'),
('discord', 'EdgeComputing#9999', 'D1 queries seem slower after the update. Anyone experiencing this?', datetime('now', '-5 days'), 'discord://msg/ch003'),
('discord', 'ServerlessJoe#4321', 'Love the new features but documentation could be better for D1 migrations!', datetime('now', '-9 days'), 'discord://msg/ch004'),
('discord', 'APIWizard#7890', 'Getting auth token errors randomly. API keys seem to expire too quickly.', datetime('now', '-1 day'), 'discord://msg/ch005'),
('discord', 'CronMaster#3456', 'My cron jobs stopped running. Checked the dashboard and nothing shows up.', datetime('now', '-1 day'), 'discord://msg/ch006');

-- TWITTER (Weight: 1)
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('twitter', '@clouddev_2024', 'Loving @cloudflare workers but getting weird 522 errors with custom domains lately 😕', datetime('now', '-2 days'), 'https://twitter.com/status/001'),
('twitter', '@startup_cto', '@cloudflare the new dashboard UI is a bit confusing. Took me 10 mins to find rollback', datetime('now', '-3 days'), 'https://twitter.com/status/002'),
('twitter', '@indie_hacker', 'D1 database feels slower than before. Anyone else? @cloudflare', datetime('now', '-5 days'), 'https://twitter.com/status/003'),
('twitter', '@web_builder', 'Shoutout to @cloudflare for the AI features! But docs could use more examples 📚', datetime('now', '-8 days'), 'https://twitter.com/status/004'),
('twitter', '@saas_founder', 'API auth keeps failing on @cloudflare workers. Token issues? 🤔', datetime('now', '-1 day'), 'https://twitter.com/status/005');

-- Mark all as unprocessed initially
UPDATE raw_feedback SET processed = 0;
