"""Runtime diagnostics for the graphify CLI."""

from __future__ import annotations

import json
import os
import platform
import shutil
import site
import sys
from importlib import metadata, util
from pathlib import Path
from typing import Any


_DEPENDENCIES: tuple[tuple[str, str, str], ...] = (
    ("graphify", "graphify", "graphifyy"),
    ("networkx", "networkx", "networkx"),
    ("tree_sitter", "tree_sitter", "tree-sitter"),
    ("openai", "openai", "openai"),
    ("tiktoken", "tiktoken", "tiktoken"),
    ("anthropic", "anthropic", "anthropic"),
    ("boto3", "boto3", "boto3"),
    ("pypdf", "pypdf", "pypdf"),
    ("markdownify", "markdownify", "markdownify"),
    ("openpyxl", "openpyxl", "openpyxl"),
    ("python-docx", "docx", "python-docx"),
    ("watchdog", "watchdog", "watchdog"),
    ("psycopg", "psycopg", "psycopg"),
)

_CREDENTIALS: dict[str, tuple[str, ...]] = {
    "gemini": ("GEMINI_API_KEY", "GOOGLE_API_KEY"),
    "openai": ("OPENAI_API_KEY",),
    "anthropic": ("ANTHROPIC_API_KEY",),
    "kimi": ("MOONSHOT_API_KEY",),
    "deepseek": ("DEEPSEEK_API_KEY",),
    "bedrock": (
        "AWS_ACCESS_KEY_ID",
        "AWS_PROFILE",
        "AWS_REGION",
        "AWS_DEFAULT_REGION",
    ),
    "ollama": ("OLLAMA_BASE_URL",),
}


def _realpath(value: str | None) -> str | None:
    if not value:
        return None
    try:
        return str(Path(value).resolve())
    except OSError:
        return value


def _in_nix_store(value: str | None) -> bool:
    real = _realpath(value)
    return bool(real and real.startswith("/nix/store/"))


def _wrapper_status(command_path: str | None) -> dict[str, Any]:
    if not command_path:
        return {"detected": False, "reason": "graphify not found on PATH"}
    try:
        text = Path(command_path).read_text(encoding="utf-8", errors="replace")[:4096]
    except OSError as exc:
        return {"detected": False, "reason": f"could not read command: {exc}"}
    detected = ".graphify-wrapped_" in text or "PYTHONNOUSERSITE" in text
    return {"detected": detected, "sets_python_no_user_site": "PYTHONNOUSERSITE" in text}


def _command_path() -> str | None:
    argv0 = sys.argv[0]
    if argv0 and (os.sep in argv0 or (os.altsep and os.altsep in argv0)):
        return argv0
    return shutil.which(argv0) or shutil.which("graphify")


def _dependency_status() -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for display_name, import_name, dist_name in _DEPENDENCIES:
        spec = util.find_spec(import_name)
        path = getattr(spec, "origin", None) if spec is not None else None
        try:
            version = metadata.version(dist_name) if spec is not None else None
        except metadata.PackageNotFoundError:
            version = None
        out[display_name] = {
            "available": spec is not None,
            "import_name": import_name,
            "version": version,
            "path": _realpath(path),
            "in_nix_store": _in_nix_store(path),
        }

    git_path = shutil.which("git")
    out["git"] = {
        "available": git_path is not None,
        "path": _realpath(git_path),
        "in_nix_store": _in_nix_store(git_path),
    }
    return out


def _credential_status() -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for backend, keys in _CREDENTIALS.items():
        present = [key for key in keys if os.environ.get(key)]
        out[backend] = {
            "available": bool(present),
            "env_vars_checked": list(keys),
            "env_vars_present": present,
        }
    return out


def _graph_state(out_name: str) -> dict[str, Any]:
    out_dir = Path(out_name)
    graph_path = out_dir / "graph.json"
    pending_path = out_dir / ".graphify_semantic_pending.json"
    needs_update_path = out_dir / "needs_update"
    state: dict[str, Any] = {
        "out_dir": str(out_dir.resolve()),
        "graph_json": str(graph_path.resolve()),
        "graph_json_exists": graph_path.exists(),
        "needs_update": needs_update_path.exists(),
        "semantic_pending": pending_path.exists(),
        "nodes": None,
        "edges": None,
        "read_error": None,
    }
    if graph_path.exists():
        try:
            data = json.loads(graph_path.read_text(encoding="utf-8"))
            state["nodes"] = len(data.get("nodes", []))
            state["edges"] = len(data.get("edges", []))
        except Exception as exc:
            state["read_error"] = str(exc)
    return state


def _recommend(graph_state: dict[str, Any], credentials: dict[str, dict[str, Any]]) -> str:
    if graph_state["graph_json_exists"]:
        if graph_state["needs_update"] or graph_state["semantic_pending"]:
            return "graphify update . --no-viz"
        return 'graphify query "<question>"'
    if any(status["available"] for status in credentials.values()):
        return "graphify extract . --no-viz"
    return "graphify extract . --local-only --no-viz"


def collect(out_name: str = "graphify-out") -> dict[str, Any]:
    command_path = _command_path()
    command_realpath = _realpath(command_path)
    package_path = _realpath(__file__)
    dependencies = _dependency_status()
    credentials = _credential_status()
    graph_state = _graph_state(out_name)
    wrapper = _wrapper_status(command_path)
    nix = {
        "command_in_store": _in_nix_store(command_realpath),
        "python_in_store": _in_nix_store(sys.executable),
        "package_in_store": _in_nix_store(package_path),
        "wrapper_detected": bool(wrapper.get("detected")),
    }
    nix["hermetic"] = (
        nix["command_in_store"]
        and nix["python_in_store"]
        and nix["package_in_store"]
        and nix["wrapper_detected"]
    )
    return {
        "command": {
            "argv0": sys.argv[0],
            "path": command_path,
            "realpath": command_realpath,
        },
        "package": {
            "path": package_path,
            "in_nix_store": _in_nix_store(package_path),
        },
        "nix": nix,
        "wrapper": wrapper,
        "python": {
            "executable": sys.executable,
            "version": platform.python_version(),
            "prefix": sys.prefix,
            "base_prefix": sys.base_prefix,
            "usersite_enabled": bool(site.ENABLE_USER_SITE),
        },
        "dependencies": dependencies,
        "credentials": credentials,
        "graph_state": graph_state,
        "recommended_next_command": _recommend(graph_state, credentials),
    }


def render_text(data: dict[str, Any]) -> str:
    nix = data["nix"]
    graph = data["graph_state"]
    lines = [
        "Graphify doctor",
        f"Command: {data['command']['realpath'] or data['command']['argv0']}",
        f"Package: {data['package']['path']}",
        f"Python: {data['python']['executable']} ({data['python']['version']})",
        (
            "Hermetic Nix: "
            f"{'yes' if nix['hermetic'] else 'no'} "
            f"(command={nix['command_in_store']}, python={nix['python_in_store']}, "
            f"package={nix['package_in_store']}, wrapper={nix['wrapper_detected']})"
        ),
        "Dependencies:",
    ]
    for name, status in data["dependencies"].items():
        marker = "ok" if status["available"] else "missing"
        version = f" {status['version']}" if status.get("version") else ""
        lines.append(f"  {name}: {marker}{version}")
    available_backends = [
        name for name, status in data["credentials"].items() if status["available"]
    ]
    lines.append(
        "Credentials: "
        + (", ".join(available_backends) if available_backends else "none detected")
    )
    graph_summary = "present" if graph["graph_json_exists"] else "missing"
    if graph["nodes"] is not None and graph["edges"] is not None:
        graph_summary += f" ({graph['nodes']} nodes, {graph['edges']} edges)"
    if graph["needs_update"]:
        graph_summary += "; needs_update"
    if graph["semantic_pending"]:
        graph_summary += "; semantic_pending"
    lines.append(f"Graph state: {graph_summary}")
    lines.append(f"Recommended next command: {data['recommended_next_command']}")
    return "\n".join(lines) + "\n"
