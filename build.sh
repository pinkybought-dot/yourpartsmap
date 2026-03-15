#!/usr/bin/env bash
# build.sh — injects .env credentials into index.html → dist/index.html
set -euo pipefail

if [ ! -f .env ]; then
  echo "Error: .env not found. Copy .env.example and fill in your credentials."
  exit 1
fi

# Load .env (skip comment lines and blanks)
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  export "$key"="$value"
done < .env

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
