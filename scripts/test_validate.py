#!/usr/bin/env python3
"""
Lightweight self-check for scripts/validate.py (ADR-0009 resource rules).
No test framework — three inline fixtures, exit non-zero on regression.
Run: python3 scripts/test_validate.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate import check_resources  # noqa: E402

FIXTURES = {
    # (should_fail, yaml)
    "pod missing resources": (True, """
kind: Pod
metadata: {name: bad-pod}
spec:
  containers:
    - name: app
      image: registry.internal.example.com/app:1
"""),
    "deployment initContainer missing resources": (True, """
kind: Deployment
metadata: {name: api}
spec:
  template:
    spec:
      initContainers:
        - name: migrate
          image: registry.internal.example.com/migrate:1
      containers:
        - name: api
          image: registry.internal.example.com/api:1
          resources:
            requests: {cpu: 100m, memory: 128Mi}
            limits: {cpu: 500m, memory: 512Mi}
"""),
    "valid statefulset": (False, """
kind: StatefulSet
metadata: {name: db}
spec:
  template:
    spec:
      containers:
        - name: db
          image: registry.internal.example.com/db:1
          resources:
            requests: {cpu: 250m, memory: 256Mi}
            limits: {cpu: "1", memory: 1Gi}
"""),
    "valid cronjob": (False, """
kind: CronJob
metadata: {name: export}
spec:
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: exporter
              image: registry.internal.example.com/exporter:1
              resources:
                requests: {cpu: 100m, memory: 128Mi}
                limits: {cpu: 250m, memory: 256Mi}
"""),
    "cronjob missing resources": (True, """
kind: CronJob
metadata: {name: export}
spec:
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: exporter
              image: registry.internal.example.com/exporter:1
"""),
    # --- Malformed-manifest crash cases: must be reported cleanly, never raise.
    "null container list": (True, """
kind: Pod
metadata: {name: bad-pod}
spec:
  containers:
"""),
    "null spec": (True, """
kind: Deployment
metadata: {name: bad-deploy}
spec:
"""),
    "non-dict top-level document": (True, """
- not
- a
- mapping
"""),
}


def main() -> int:
    failures = []
    for name, (should_fail, text) in FIXTURES.items():
        errors: list[str] = []
        check_resources(yaml.safe_load(text), Path(f"<fixture:{name}>"), errors)
        if bool(errors) != should_fail:
            failures.append(f"{name}: expected fail={should_fail}, got errors={errors}")

    if failures:
        print("validate.py self-check FAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1

    print(f"validate.py self-check passed ({len(FIXTURES)} fixtures).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
