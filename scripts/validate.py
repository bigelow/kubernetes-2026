#!/usr/bin/env python3
"""
Validates every manifest across the reference-architecture folders for YAML
syntax correctness and a small set of house rules (ADR-0009: workload
containers must set resource requests/limits).

Kept deliberately simple — this is a structural sanity check, not a schema
validator. For full API-schema validation, run `kubeconform` in CI as a
complementary step.
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent

# Top-level folders containing Kubernetes manifests. The Compose file and
# backend configs under observability-telemetry/local-dev are deliberately
# excluded — they're Compose/Alloy/Prometheus/Tempo/Loki/Grafana syntax,
# not Kubernetes manifests, and don't use apiVersion/kind.
MANIFEST_DIRS = [
    "traffic-management",
    "security-policy",
    "observability-telemetry",
    "ai-scheduling",
    "cost-allocation",
    "workloads",
    "multi-tenancy",
]
EXCLUDE_NAMES = {"compose.yml", "compose.yaml", "docker-compose.yml", "docker-compose.yaml"}

# Kinds where every container must declare resources (ADR-0009).
RESOURCE_REQUIRED_KINDS = {"Pod", "Deployment", "StatefulSet", "DaemonSet", "Job", "CronJob"}


def iter_yaml_files():
    for dirname in MANIFEST_DIRS:
        root = REPO_ROOT / dirname
        if not root.exists():
            continue
        for pattern in ("*.yaml", "*.yml"):
            for path in root.rglob(pattern):
                if path.name in EXCLUDE_NAMES:
                    continue
                if "local-dev" in path.parts:
                    continue
                yield path


def load_documents(path: Path) -> list[dict]:
    with path.open() as f:
        return [doc for doc in yaml.safe_load_all(f) if doc]


# Container-like fields checked for resources (ADR-0009). ephemeralContainers
# only appear on bare Pods in practice, but the check is harmless elsewhere.
CONTAINER_FIELDS = ("containers", "initContainers", "ephemeralContainers")


def _name(doc: dict) -> str | None:
    meta = doc.get("metadata")
    return meta.get("name") if isinstance(meta, dict) else None


def _pod_spec_for(doc: dict):
    """Return the pod spec for a workload kind, or None if the doc's spec
    structure is missing/malformed (a malformed manifest, not a crash)."""
    spec = doc.get("spec")
    if not isinstance(spec, dict):
        return None
    kind = doc.get("kind")
    if kind == "Pod":
        # Bare Pods have a flat spec — no .template wrapper.
        return spec
    if kind == "CronJob":
        job = spec.get("jobTemplate")
        spec = job.get("spec") if isinstance(job, dict) else None
        if not isinstance(spec, dict):
            return None
    template = spec.get("template")
    tspec = template.get("spec") if isinstance(template, dict) else None
    return tspec if isinstance(tspec, dict) else None


def check_resources(doc: dict, path: Path, errors: list[str]) -> None:
    # A YAML document need not be a mapping (it can be a list or scalar); guard
    # so a malformed file yields a clean error instead of an AttributeError.
    if not isinstance(doc, dict):
        errors.append(
            f"{path}: top-level document is not a mapping "
            f"(got {type(doc).__name__}); expected a Kubernetes object"
        )
        return

    kind = doc.get("kind")
    if kind not in RESOURCE_REQUIRED_KINDS:
        return

    name = _name(doc)
    pod_spec = _pod_spec_for(doc)
    if pod_spec is None:
        errors.append(
            f"{path}: {kind} '{name}' has a missing or malformed pod spec"
        )
        return

    for field in CONTAINER_FIELDS:
        # Singular field name for the error message, e.g. "initContainer".
        label = field[:-1]
        if field not in pod_spec:
            continue
        containers = pod_spec[field]
        if containers is None:
            errors.append(
                f"{path}: {kind} '{name}' field '{field}' is null; "
                f"expected a list of containers"
            )
            continue
        if not isinstance(containers, list):
            errors.append(
                f"{path}: {kind} '{name}' field '{field}' must be a list "
                f"(got {type(containers).__name__})"
            )
            continue
        for c in containers:
            if not isinstance(c, dict):
                errors.append(
                    f"{path}: {kind} '{name}' has a malformed {label} entry "
                    f"(expected mapping, got {type(c).__name__})"
                )
                continue
            resources = c.get("resources") or {}
            if not isinstance(resources, dict):
                errors.append(
                    f"{path}: {label} '{c.get('name')}' in {kind} '{name}' "
                    f"has a malformed resources field"
                )
                continue
            if not resources.get("requests") or not resources.get("limits"):
                errors.append(
                    f"{path}: {label} '{c.get('name')}' in {kind} "
                    f"'{name}' is missing "
                    f"requests/limits (ADR-0009)"
                )


def main() -> int:
    errors: list[str] = []
    checked = 0

    for path in iter_yaml_files():
        checked += 1
        try:
            docs = load_documents(path)
        except yaml.YAMLError as e:
            errors.append(f"{path}: invalid YAML — {e}")
            continue

        for doc in docs:
            check_resources(doc, path, errors)

    print(f"Checked {checked} manifest file(s).")

    if errors:
        print(f"\n{len(errors)} problem(s) found:\n")
        for e in errors:
            print(f"  - {e}")
        return 1

    print("All manifests valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
