from __future__ import annotations

from pathlib import Path


FLAKE = Path(__file__).resolve().parent.parent / "flake.nix"


def test_default_nix_package_is_practical_and_core_output_remains_available():
    text = FLAKE.read_text(encoding="utf-8")
    assert "graphifyyCore" in text
    assert "graphify-core = graphifyyCore" in text
    assert "default = graphifyy" in text
    assert "graphify = graphifyy" in text


def test_nix_package_includes_common_semantic_backend_sdks_and_runtime_tools():
    text = FLAKE.read_text(encoding="utf-8")
    for expected in ("openai", "tiktoken", "anthropic", "boto3"):
        assert expected in text
    for expected in ("python.withPackages", "GRAPHIFY_INTERPRETER", "-I -m graphify", "git"):
        assert expected in text
    assert "makeWrapper" not in text
