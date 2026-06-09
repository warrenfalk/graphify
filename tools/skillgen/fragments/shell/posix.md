```bash
# Always resolve Python through the currently installed graphify command.
# Do not cache the interpreter path: Nix/NixOS profiles can switch underneath
# a repo, and the interpreter must stay tied to the active graphify executable.
if ! command -v graphify >/dev/null 2>&1; then
    echo "ERROR: graphify is not installed or not on PATH. Install graphify first, then rerun /graphify."
    exit 1
fi

GRAPHIFY_PYTHON=$(graphify interpreter 2>/dev/null)
if [ -z "$GRAPHIFY_PYTHON" ] || [ ! -x "$GRAPHIFY_PYTHON" ]; then
    echo "ERROR: graphify interpreter did not return an executable Python path."
    exit 1
fi

if ! "$GRAPHIFY_PYTHON" -c "import graphify" >/dev/null 2>&1; then
    echo "ERROR: graphify interpreter cannot import graphify. Reinstall or rebuild the active graphify package."
    exit 1
fi

mkdir -p graphify-out
# Save scan root so `graphify update` (no args) knows where to look next time
echo "$(cd INPUT_PATH && pwd)" > graphify-out/.graphify_root
```

If the import succeeds, print nothing and move straight to Step 2.

**In every subsequent bash block, replace `python3` with `$(graphify interpreter)`. Do not cache the interpreter path.**
