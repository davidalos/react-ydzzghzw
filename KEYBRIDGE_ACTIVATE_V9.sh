#!/bin/bash

FORCE_PUSH=false
SYNC_PLATFORMS=false

for arg in "$@"; do
  case $arg in
    --force)
      FORCE_PUSH=true
      ;;
    --sync)
      SYNC_PLATFORMS=true
      ;;
  esac
done

set -e

if [ ! -f .env ]; then
  cat > .env <<EOF
SUPABASE_DB_URL=postgres://postgres:UzRIlnmMX65dbD0S@db.kybhregztorltmcltjra.supabase.co:5432/postgres

# Supabase
VITE_SUPABASE_URL=https://kybhregztorltmcltjra.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtdGpzZWtveWxpeGNyYmZuYWJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDk2NTY5NzAsImV4cCI6MjAyNTIzMjk3MH0.0C_kQxJJXSz7svXg4J_0-cj_8yP1ESA_2cGHp5eNQpM
SUPABASE_URL=https://kybhregztorltmcltjra.supabase.co
SUPABASE_PROJECT_REF=kybhregztorltmcltjra

# For server-side only (do not expose to client!)
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhtdGpzZWtveWxpeGNyYmZuYWJwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwOTY1Njk3MCwiZXhwIjoyMDI1MjMyOTcwfQ.VE1NG_iBcnf_EC0JGLL2FPj_VYS-xGRvUcTGRiw-8Ks

# Turnstile (Cloudflare CAPTCHA)
VITE_TURNSTILE_SITE_KEY=0x4AAAAAABf8GGR3DrgJYy7g
TURNSTILE_SECRET_KEY=0x4AAAAAABf8GGSBgGvWBgwAZl_FYgQvP3
EOF
fi

source .env

mkdir -p supabase
cat > supabase/config.toml <<EOF
[project]
ref = "$SUPABASE_PROJECT_REF"
api_url = "$SUPABASE_URL"
anon_key = "$VITE_SUPABASE_ANON_KEY"
service_role_key = "$SUPABASE_SERVICE_ROLE_KEY"
EOF

if ! supabase projects list | grep -q "$SUPABASE_PROJECT_REF"; then
  npx supabase login
  npx supabase link --project-ref "$SUPABASE_PROJECT_REF"
fi

mkdir -p .github/workflows
cat > .github/workflows/supabase.yml <<EOF
name: Supabase Sync
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
        with:
          version: latest
      - run: supabase link --project-ref $SUPABASE_PROJECT_REF
        env:
          SUPABASE_ACCESS_TOKEN: \${{ secrets.SUPABASE_ACCESS_TOKEN }}
      - run: supabase db push
EOF

mkdir -p supabase/rules
cat > supabase/rules/production.lock.sql <<EOF
ALTER POLICY "Modify data"
  ON public.incidents
  USING (auth.role() IN ('admin', 'manager'));
EOF

cat > vercel.json <<EOF
{
  "env": {
    "SUPABASE_PROJECT_REF": "$SUPABASE_PROJECT_REF",
    "VITE_SUPABASE_ANON_KEY": "$VITE_SUPABASE_ANON_KEY",
    "TURNSTILE_SECRET_KEY": "$TURNSTILE_SECRET_KEY"
  },
  "build": {
    "env": {
      "SUPABASE_SERVICE_ROLE_KEY": "$SUPABASE_SERVICE_ROLE_KEY"
    }
  }
}
EOF

cat > .github/workflows/daily-backup.yml <<EOF
name: Daily Backup
on:
  schedule:
    - cron: '0 3 * * *'
jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
        with:
          version: latest
      - run: supabase gen types typescript --local
      - run: supabase db dump --file ./backups/backup_\$(date +%F).sql
EOF

cat > bolt.yaml <<EOF
settings:
  entrypoint: index.jsx
  ignore:
    - node_modules
    - .github
    - .env
  env:
    - SUPABASE_PROJECT_REF
    - VITE_SUPABASE_ANON_KEY
    - SUPABASE_SERVICE_ROLE_KEY
EOF

BRANCH="fix/keybridge-preview-v9"
MAIN_BRANCH="main"

git checkout -b $BRANCH || git checkout $BRANCH
git add .env supabase/config.toml supabase/rules .github workflows vercel.json bolt.yaml || true
git commit -m "KEYBRIDGE v9: Auto-link + sync + policy + backup workflows"

if $FORCE_PUSH; then
  git checkout $MAIN_BRANCH
  git merge $BRANCH --no-edit || true
  git push origin $MAIN_BRANCH
else
  git push origin $BRANCH
fi

if $SYNC_PLATFORMS; then
  git pull origin $MAIN_BRANCH
fi

cat > .env.example <<EOF
SUPABASE_PROJECT_REF=your-project-ref
VITE_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
EOF

echo ".env" >> .gitignore
echo "backups/" >> .gitignore

echo "KEYBRIDGE v9 COMPLETE"