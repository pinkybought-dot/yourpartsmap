#!/usr/bin/env bash
# build.sh — injects credentials into index.html → dist/index.html
# Credentials come from either: (1) .env file (local dev) or (2) env vars already set (CI/GitHub Actions)
set -euo pipefail

# Load .env if present (local dev). In CI, secrets are already exported as env vars.
if [ -f .env ]; then
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^[[:space:]]*#.*$ || -z "$key" ]] && continue
    # Only set if not already in environment
    [ -z "${!key+x}" ] && export "$key"="$value"
  done < .env
fi

# Validate required vars are now set
for var in SUPABASE_URL SUPABASE_PUBLISHABLE_KEY ANTHROPIC_API_KEY; do
  if [ -z "${!var:-}" ]; then
    echo "Error: $var is not set. Add it to .env or set it as an environment variable."
    exit 1
  fi
done

mkdir -p dist

sed \
  -e "s|__SUPABASE_URL__|${SUPABASE_URL}|g" \
  -e "s|__SUPABASE_KEY__|${SUPABASE_PUBLISHABLE_KEY}|g" \
  -e "s|__ANTHROPIC_API_KEY__|${ANTHROPIC_API_KEY}|g" \
  index.html > dist/index.html

echo "✓ Built dist/index.html"
echo ""
echo "Deploy: copy dist/index.html to your GitHub Pages root,"
echo "        or push with the GitHub Actions workflow."
