#!/bin/sh
# Instala todos los git hooks de Anshin
# Uso: sh hooks/setup-hooks.sh

HOOKS_DIR=".git/hooks"
SOURCE_DIR="hooks"

echo "📎 Instalando git hooks de Anshin..."

for hook in pre-commit pre-push commit-msg; do
  if [ -f "$SOURCE_DIR/$hook" ]; then
    cp "$SOURCE_DIR/$hook" "$HOOKS_DIR/$hook"
    chmod +x "$HOOKS_DIR/$hook"
    echo "  ✅ $hook instalado"
  fi
done

echo ""
echo "✅ Hooks instalados. Se ejecutarán automáticamente en cada commit/push."
