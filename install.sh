#!/bin/bash
set -euo pipefail

# Claude Code Configuration Installer
# Installs settings, global instructions, and rules to ~/.claude/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/$(date +%Y%m%d_%H%M%S)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ──────────────────────────────────────
# 1. Ensure ~/.claude/ exists
# ──────────────────────────────────────
mkdir -p "$CLAUDE_DIR"

# ──────────────────────────────────────
# 2. Backup existing configuration
# ──────────────────────────────────────
backup_needed=false
for f in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md"; do
  [ -f "$f" ] && backup_needed=true && break
done
[ -d "$CLAUDE_DIR/rules" ] && backup_needed=true

if [ "$backup_needed" = true ]; then
  mkdir -p "$BACKUP_DIR"
  [ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$BACKUP_DIR/"
  [ -f "$CLAUDE_DIR/CLAUDE.md" ] && cp "$CLAUDE_DIR/CLAUDE.md" "$BACKUP_DIR/"
  [ -d "$CLAUDE_DIR/rules" ] && cp -r "$CLAUDE_DIR/rules" "$BACKUP_DIR/"
  info "Existing config backed up to $BACKUP_DIR"
fi

# ──────────────────────────────────────
# 3. Install settings.json (merge or fresh)
# ──────────────────────────────────────
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys

with open('$CLAUDE_DIR/settings.json') as f:
    existing = json.load(f)
with open('$SCRIPT_DIR/settings.json') as f:
    new = json.load(f)

# Merge permissions (union of allow, replace deny from new config)
ep = existing.get('permissions', {})
np = new.get('permissions', {})
merged_allow = list(dict.fromkeys(ep.get('allow', []) + np.get('allow', [])))
merged_deny  = list(dict.fromkeys(np.get('deny', [])))

# Merge top-level keys (new values win for non-permission keys)
merged = {**existing, **new}
merged['permissions'] = {**ep, **np, 'allow': merged_allow, 'deny': merged_deny}

# Preserve user's plugins and marketplaces
for key in ['enabledPlugins', 'extraKnownMarketplaces']:
    if key in existing:
        merged[key] = {**existing.get(key, {}), **merged.get(key, {})}

with open('$CLAUDE_DIR/settings.json', 'w') as f:
    json.dump(merged, f, indent=2)
    f.write('\n')
" && info "settings.json merged with existing config" || {
      warn "Merge failed, overwriting settings.json"
      cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    }
  else
    warn "python3 not found, overwriting settings.json"
    cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  fi
else
  cp "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
  info "settings.json installed"
fi

# ──────────────────────────────────────
# 4. Install CLAUDE.md
# ──────────────────────────────────────
cp "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
info "CLAUDE.md installed"

# ──────────────────────────────────────
# 5. Install rules
# ──────────────────────────────────────
if [ -d "$SCRIPT_DIR/rules" ]; then
  # Parse arguments for language selection
  LANGS=("$@")

  # Always install common rules
  mkdir -p "$CLAUDE_DIR/rules/common"
  cp -r "$SCRIPT_DIR/rules/common/"* "$CLAUDE_DIR/rules/common/"
  info "Common rules installed"

  if [ ${#LANGS[@]} -eq 0 ]; then
    # No languages specified: install all available
    for lang_dir in "$SCRIPT_DIR/rules"/*/; do
      lang=$(basename "$lang_dir")
      [ "$lang" = "common" ] && continue
      mkdir -p "$CLAUDE_DIR/rules/$lang"
      cp -r "$lang_dir"* "$CLAUDE_DIR/rules/$lang/"
      info "$lang rules installed"
    done
  else
    # Install only specified languages
    for lang in "${LANGS[@]}"; do
      if [ -d "$SCRIPT_DIR/rules/$lang" ]; then
        mkdir -p "$CLAUDE_DIR/rules/$lang"
        cp -r "$SCRIPT_DIR/rules/$lang/"* "$CLAUDE_DIR/rules/$lang/"
        info "$lang rules installed"
      else
        warn "Language '$lang' not found in rules/. Available: $(ls -d "$SCRIPT_DIR/rules"/*/ | xargs -I{} basename {} | grep -v common | tr '\n' ' ')"
      fi
    done
  fi
fi

# ──────────────────────────────────────
# 6. Summary
# ──────────────────────────────────────
echo ""
info "Installation complete!"
echo ""
echo "  Installed to: $CLAUDE_DIR"
echo ""
echo "  Files:"
echo "    - settings.json  (71 auto-allow, 16 deny rules)"
echo "    - CLAUDE.md      (global instructions)"
echo "    - rules/         (coding standards per language)"
echo ""
echo "  Restart Claude Code to apply changes."
echo ""
echo "  Optional: Add language to your response"
echo "    Add to settings.json: \"language\": \"korean\""
echo ""
