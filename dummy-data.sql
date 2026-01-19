-- Dummy Data for Feedback Aggregator Prototype
-- Insert this after creating the schema
-- Simulating 30 days of data with multiple reporters for same issues

-- Raw feedback from various sources (simulating 30 days of data)

-- SUPPORT TICKETS (Weight: 5) - 15 tickets
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('support', 'john_doe', 'Deployment fails when using custom domains. Getting 522 errors constantly.', datetime('now', '-2 days'), 'ticket://12345'),
('support', 'sarah_chen', 'Workers not executing scheduled cron jobs. Last run was 3 days ago.', datetime('now', '-1 day'), 'ticket://12346'),
('support', 'mike_wilson', 'D1 database queries timing out after recent update. Query takes >30s now.', datetime('now', '-5 days'), 'ticket://12347'),
('support', 'emma_stone', 'Cannot deploy worker - getting "script too large" error even though its only 800KB.', datetime('now', '-3 days'), 'ticket://12348'),
('support', 'alex_kim', 'Deployment rollback not working. Need to restore previous version urgently.', datetime('now', '-1 day'), 'ticket://12349'),
('support', 'lisa_park', 'Custom domain SSL certificate not provisioning. Stuck in pending state for 48 hours.', datetime('now', '-7 days'), 'ticket://12350'),
('support', 'david_brown', 'Worker CPU time limit exceeded on free plan but script is very simple.', datetime('now', '-4 days'), 'ticket://12351'),
('support', 'jennifer_liu', 'Custom domain deployment returns 522 error after 30 seconds timeout.', datetime('now', '-3 days'), 'ticket://12352'),
('support', 'robert_garcia', 'Cron job execution is unreliable. Some runs are completely skipped.', datetime('now', '-2 days'), 'ticket://12353'),
('support', 'maria_rodriguez', 'API authentication failing with "invalid token" despite using correct credentials.', datetime('now', '-6 hours'), 'ticket://12354'),
('support', 'thomas_anderson', 'Worker deployment UI is very confusing after the recent redesign.', datetime('now', '-4 days'), 'ticket://12355'),
('support', 'patricia_wong', 'D1 database performance degraded significantly. Simple queries taking 20+ seconds.', datetime('now', '-6 days'), 'ticket://12356'),
('support', 'james_taylor', '522 timeout errors on custom domain, works fine on workers.dev subdomain.', datetime('now', '-1 day'), 'ticket://12357'),
('support', 'linda_martinez', 'Cannot find rollback feature in new UI. Accidentally deployed broken code.', datetime('now', '-5 days'), 'ticket://12358'),
('support', 'kevin_lee', 'Scheduled cron triggers missing execution logs. Cannot debug why they are not running.', datetime('now', '-12 hours'), 'ticket://12359');

-- EMAIL (Weight: 4) - 12 emails
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('email', 'developer@company.com', 'The new deployment UI is confusing. Cannot find the rollback button anymore.', datetime('now', '-3 days'), 'email://msg001'),
('email', 'cto@startup.io', 'Getting 522 errors on all our Workers endpoints. This is affecting production!', datetime('now', '-2 days'), 'email://msg002'),
('email', 'team@agency.com', 'Feature request: Would love to see A/B testing support for Workers deployments.', datetime('now', '-10 days'), 'email://msg003'),
('email', 'ops@enterprise.net', 'D1 database backup and restore documentation is unclear. Need better guides.', datetime('now', '-6 days'), 'email://msg004'),
('email', 'engineer@tech.com', 'The deployment UI hangs when uploading workers with many dependencies.', datetime('now', '-4 days'), 'email://msg005'),
('email', 'support@saas.io', 'Cannot authenticate API requests. Getting invalid token errors even with fresh keys.', datetime('now', '-1 day'), 'email://msg006'),
('email', 'admin@business.org', 'Custom domains showing 522 gateway errors. Our production site is down!', datetime('now', '-18 hours'), 'email://msg007'),
('email', 'platform@scale.net', 'Cron jobs not executing on schedule. Missing critical data processing windows.', datetime('now', '-3 days'), 'email://msg008'),
('email', 'infra@global.io', 'D1 query performance issues making our app unusable. Seeing 30+ second timeouts.', datetime('now', '-7 days'), 'email://msg009'),
('email', 'devteam@startup.dev', 'UI redesign removed important features. Where is the deployment history?', datetime('now', '-5 days'), 'email://msg010'),
('email', 'security@corp.com', 'API token authentication is broken. Getting 401 errors with valid tokens.', datetime('now', '-2 days'), 'email://msg011'),
('email', 'operations@service.app', 'Worker deployment process is now much more complicated than before.', datetime('now', '-8 days'), 'email://msg012');

-- GITHUB ISSUES (Weight: 3) - 14 issues
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('github', 'octocat_dev', 'Deployment fails with custom domains - 522 timeout errors. Reproducible on all our workers.', datetime('now', '-2 days'), 'https://github.com/cloudflare/issues/5001'),
('github', 'rustacean42', 'Workers AI responses are inconsistent. Same prompt gives different results each time.', datetime('now', '-8 days'), 'https://github.com/cloudflare/issues/5002'),
('github', 'frontend_guru', 'UI bug: Dashboard doesnt update after deployment. Need to hard refresh browser.', datetime('now', '-5 days'), 'https://github.com/cloudflare/issues/5003'),
('github', 'backend_ninja', 'KV namespace binding not working in new workers. Getting undefined errors.', datetime('now', '-12 days'), 'https://github.com/cloudflare/issues/5004'),
('github', 'cloud_architect', 'Documentation missing for new D1 migration features. Examples would help.', datetime('now', '-9 days'), 'https://github.com/cloudflare/issues/5005'),
('github', 'devops_lead', 'Cron triggers not firing reliably. Missing several scheduled runs per day.', datetime('now', '-1 day'), 'https://github.com/cloudflare/issues/5006'),
('github', 'fullstack_sam', 'The new deployment UI is not intuitive. Rollback option is hidden.', datetime('now', '-3 days'), 'https://github.com/cloudflare/issues/5007'),
('github', 'code_master_99', 'Custom domain 522 errors are affecting multiple production deployments.', datetime('now', '-4 days'), 'https://github.com/cloudflare/issues/5008'),
('github', 'api_developer', 'Authentication tokens expiring prematurely or not being validated correctly.', datetime('now', '-3 days'), 'https://github.com/cloudflare/issues/5009'),
('github', 'db_specialist', 'D1 database performance regression. Queries 10x slower than last month.', datetime('now', '-8 days'), 'https://github.com/cloudflare/issues/5010'),
('github', 'ux_designer', 'New UI/UX is confusing. Users cannot find basic deployment features.', datetime('now', '-6 days'), 'https://github.com/cloudflare/issues/5011'),
('github', 'automation_eng', 'Scheduled workers (cron) randomly skip executions without any error logs.', datetime('now', '-4 days'), 'https://github.com/cloudflare/issues/5012'),
('github', 'performance_team', 'Worker script size limit seems incorrect. Getting errors at 800KB instead of 1MB.', datetime('now', '-10 days'), 'https://github.com/cloudflare/issues/5013'),
('github', 'reliability_eng', 'Custom domain SSL provisioning stuck in pending state for 48+ hours.', datetime('now', '-11 days'), 'https://github.com/cloudflare/issues/5014');

-- DISCORD (Weight: 2) - 16 messages
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('discord', 'CloudFanatic#1234', 'Anyone else getting 522 errors with custom domains? Its been happening for days.', datetime('now', '-2 days'), 'discord://msg/ch001'),
('discord', 'WorkerBee#5678', 'The UI changes are kinda confusing tbh. Where did the old deploy button go?', datetime('now', '-3 days'), 'discord://msg/ch002'),
('discord', 'EdgeComputing#9999', 'D1 queries seem slower after the update. Anyone experiencing this?', datetime('now', '-5 days'), 'discord://msg/ch003'),
('discord', 'ServerlessJoe#4321', 'Love the new features but documentation could be better for D1 migrations!', datetime('now', '-9 days'), 'discord://msg/ch004'),
('discord', 'APIWizard#7890', 'Getting auth token errors randomly. API keys seem to expire too quickly.', datetime('now', '-1 day'), 'discord://msg/ch005'),
('discord', 'CronMaster#3456', 'My cron jobs stopped running. Checked the dashboard and nothing shows up.', datetime('now', '-1 day'), 'discord://msg/ch006'),
('discord', 'WebDev2024#7777', 'Production is down with 522 errors on custom domain. Help!', datetime('now', '-3 days'), 'discord://msg/ch007'),
('discord', 'CodeNinja#5555', 'New UI is horrible. Cannot find anything. Where is rollback?', datetime('now', '-4 days'), 'discord://msg/ch008'),
('discord', 'DataEngineer#8888', 'D1 performance is really bad lately. Queries timing out constantly.', datetime('now', '-6 days'), 'discord://msg/ch009'),
('discord', 'BuildMaster#3333', 'Deployment takes forever now. Is there a way to speed it up?', datetime('now', '-7 days'), 'discord://msg/ch010'),
('discord', 'ScheduledTask#2222', 'Cron jobs are unreliable. Missing important scheduled runs.', datetime('now', '-2 days'), 'discord://msg/ch011'),
('discord', 'TokenTester#4444', 'API authentication is broken. Valid tokens being rejected.', datetime('now', '-5 hours'), 'discord://msg/ch012'),
('discord', 'DomainKing#6666', 'Custom domain SSL not working. Stuck on pending for 2 days.', datetime('now', '-9 days'), 'discord://msg/ch013'),
('discord', 'UIExpert#9991', 'The redesigned dashboard is confusing and hard to navigate.', datetime('now', '-8 days'), 'discord://msg/ch014'),
('discord', 'CronScheduler#1111', 'Cron triggers are not reliable anymore. Need fix ASAP.', datetime('now', '-10 hours'), 'discord://msg/ch015'),
('discord', 'DeploymentPro#7779', '522 timeout on custom domains. Workers.dev subdomain works fine though.', datetime('now', '-1 day'), 'discord://msg/ch016');

-- TWITTER (Weight: 1) - 13 tweets
INSERT INTO raw_feedback (source, author, content, timestamp, url) VALUES
('twitter', '@clouddev_2024', 'Loving @cloudflare workers but getting weird 522 errors with custom domains lately 😕', datetime('now', '-2 days'), 'https://twitter.com/status/001'),
('twitter', '@startup_cto', '@cloudflare the new dashboard UI is a bit confusing. Took me 10 mins to find rollback', datetime('now', '-3 days'), 'https://twitter.com/status/002'),
('twitter', '@indie_hacker', 'D1 database feels slower than before. Anyone else? @cloudflare', datetime('now', '-5 days'), 'https://twitter.com/status/003'),
('twitter', '@web_builder', 'Shoutout to @cloudflare for the AI features! But docs could use more examples 📚', datetime('now', '-8 days'), 'https://twitter.com/status/004'),
('twitter', '@saas_founder', 'API auth keeps failing on @cloudflare workers. Token issues? 🤔', datetime('now', '-1 day'), 'https://twitter.com/status/005'),
('twitter', '@devops_daily', 'Our @cloudflare workers cron jobs keep missing runs. Anyone else seeing this?', datetime('now', '-4 days'), 'https://twitter.com/status/006'),
('twitter', '@tech_startup', 'Custom domain 522 errors taking down our production site @cloudflare', datetime('now', '-6 hours'), 'https://twitter.com/status/007'),
('twitter', '@frontend_dev', 'New @cloudflare dashboard UI is confusing AF. Cant find basic features anymore', datetime('now', '-7 days'), 'https://twitter.com/status/008'),
('twitter', '@backend_eng', 'D1 queries are ridiculously slow now. What happened @cloudflare?', datetime('now', '-9 days'), 'https://twitter.com/status/009'),
('twitter', '@platform_team', 'Authentication tokens not working properly on @cloudflare API. Getting random 401s', datetime('now', '-3 days'), 'https://twitter.com/status/010'),
('twitter', '@deployment_bot', 'Cron jobs failing silently on @cloudflare. No errors, just not running 🤷', datetime('now', '-14 hours'), 'https://twitter.com/status/011'),
('twitter', '@security_first', '@cloudflare API token validation seems broken. Valid tokens being rejected', datetime('now', '-2 days'), 'https://twitter.com/status/012'),
('twitter', '@scale_master', 'Worker deployment UI redesign made everything harder to use @cloudflare', datetime('now', '-11 days'), 'https://twitter.com/status/013');

-- Mark all as unprocessed initially
UPDATE raw_feedback SET processed = 0;