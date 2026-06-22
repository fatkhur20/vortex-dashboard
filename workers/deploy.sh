#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Load env
if [ -f .env ]; then
  set -a; source .env; set +a
fi

# Map legacy CF_ vars to CLOUDFLARE_ vars
: "${CLOUDFLARE_API_TOKEN:=${CF_API_TOKEN:-}}"
: "${CLOUDFLARE_ACCOUNT_ID:=${CF_ACCOUNT_ID:-}}"
export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID

# Wrangler v2 needs PREFIX for Termux
export PREFIX=/data/data/com.termux/files/usr
WRANGLER="node /data/data/com.termux/files/home/.npm-global/lib/node_modules/wrangler/bin/wrangler.js"

case "${1:-deploy}" in
  login)
    echo "🔑 Login requires browser. Use CF_API_TOKEN env var instead."
    echo "   Set in .env:"
    echo "   echo 'CF_API_TOKEN=your_token' >> .env"
    echo "   echo 'CF_ACCOUNT_ID=your_id' >> .env"
    ;;

  init-db)
    echo "📦 Creating D1 database..."
    $WRANGLER d1 create vortex-tracker 2>&1
    echo ""
    echo "⚠️  Copy the database_id from above and add to .env:"
    echo "   echo 'CF_D1_DATABASE_ID=xxxx' >> .env"
    echo "   Then update database_id in wrangler.toml"
    ;;

  schema)
    DB_ID="${CF_D1_DATABASE_ID:-}"
    if [ -z "$DB_ID" ]; then
      echo "❌ CF_D1_DATABASE_ID not set"
      exit 1
    fi
    echo "🗄️  Running schema.sql..."
    $WRANGLER d1 execute vortex-tracker --file=schema.sql 2>&1
    ;;

  deploy|publish)
    echo "🚀 Publishing..."
    $WRANGLER publish 2>&1
    ;;

  all)
    $0 init-db
    $0 schema
    $0 deploy
    ;;

  *)
    echo "Usage: ./deploy.sh [login|init-db|schema|deploy|all]"
    ;;
esac
