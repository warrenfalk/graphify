```powershell
# Always resolve Python through the currently installed graphify command.
# Do not cache the interpreter path: profiles and tool installs can change
# underneath a repo, and the interpreter must stay tied to the active executable.
New-Item -ItemType Directory -Force -Path graphify-out | Out-Null

if (-not (Get-Command graphify -ErrorAction SilentlyContinue)) {
    Write-Error "graphify is not installed or not on PATH. Install graphify first, then rerun /graphify."
    exit 1
}

$GRAPHIFY_PYTHON = (graphify interpreter 2>$null).Trim()

if (-not $GRAPHIFY_PYTHON -or -not (Test-Path $GRAPHIFY_PYTHON)) {
    Write-Error "graphify interpreter did not return an executable Python path."
    exit 1
}

& $GRAPHIFY_PYTHON -c "import graphify" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "graphify interpreter cannot import graphify. Reinstall or rebuild the active graphify package."
    exit 1
}

# Save scan root so `graphify update` (no args) knows where to look next time
(Resolve-Path INPUT_PATH).Path | Out-File -FilePath graphify-out\.graphify_root -Encoding utf8 -NoNewline
```

If the import succeeds, print nothing and move straight to Step 2.

**In every subsequent block, resolve Python with `graphify interpreter` in place of a bare `python3`. Do not cache the interpreter path.**
