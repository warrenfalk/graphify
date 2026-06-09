from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


PYTHON = sys.executable


def _run(args: list[str], cwd: Path, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        [PYTHON, "-m", "graphify"] + args,
        cwd=cwd,
        capture_output=True,
        text=True,
        env=env,
    )


def _without_backend_keys() -> dict[str, str]:
    env = os.environ.copy()
    for key in (
        "GEMINI_API_KEY",
        "GOOGLE_API_KEY",
        "OPENAI_API_KEY",
        "ANTHROPIC_API_KEY",
        "DEEPSEEK_API_KEY",
        "MOONSHOT_API_KEY",
        "AWS_PROFILE",
        "AWS_REGION",
        "AWS_DEFAULT_REGION",
        "AWS_ACCESS_KEY_ID",
        "OLLAMA_BASE_URL",
    ):
        env.pop(key, None)
    return env


def test_doctor_json_reports_runtime_and_graph_state(tmp_path):
    r = _run(["doctor", "--json"], tmp_path, env=_without_backend_keys())

    assert r.returncode == 0, r.stderr
    data = json.loads(r.stdout)
    assert data["python"]["executable"] == sys.executable
    assert "graphify" in data["dependencies"]
    assert "networkx" in data["dependencies"]
    assert data["graph_state"]["graph_json_exists"] is False
    assert data["recommended_next_command"] == "graphify extract . --local-only --no-viz"


def test_doctor_text_mentions_hermetic_status(tmp_path):
    r = _run(["doctor"], tmp_path, env=_without_backend_keys())

    assert r.returncode == 0, r.stderr
    assert "Graphify doctor" in r.stdout
    assert "Hermetic Nix" in r.stdout
    assert "Recommended next command" in r.stdout
