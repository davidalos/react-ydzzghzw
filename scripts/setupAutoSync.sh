#!/bin/sh
# ⚡️ TEAMWORK: Auto-Sync GitHub + Supabase Integration Script
# ✨ Created: 2025-06-06T03:38:33Z
# Use inside Codex or Bolt terminal or as a setup script for full sync automation

# 1. Initialize Supabase if not done yet
npx supabase init

# 2. Set up live Supabase CLI linking to project
supabase link --project-ref YOUR_PROJECT_REF

# Optional: Store credentials securely for smoother automation
# echo "SUPABASE_ACCESS_TOKEN=your-token-here" >> .env

# 3. Set up Git post-merge hook (auto-fetch + hard reset after each merge)
cat <<'HOOK' > .git/hooks/post-merge
#!/bin/sh
git fetch origin
git reset --hard origin/main
npx supabase db push
HOOK

chmod +x .git/hooks/post-merge

# 4. Push latest migrations automatically to Supabase
npx supabase db push

