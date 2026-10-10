# Replacement for the "verified against v1.36" sentence

Original (`content/posts/kubernetes-2026.md`, in the "small honesty discipline" paragraph):

> "Intended to inject" became "injects (verified against v1.36)" only after the live test.

Replacement — points at the repo's record of what each run exercised rather than at a version:

> "Intended to inject" became "injects" only after a live test, and the repo's [CHANGELOG](https://github.com/bigelow/kubernetes-2026/blob/main/CHANGELOG.md) records which shapes each verification actually exercised.

Also in the same post, the earlier paragraph (line 37) ends with the v1.36.1 live-test list; it stays accurate as a description of that run. The one sentence to add after it:

> That run used containers without atomic fields, and the policy failed on ones that had them; see the October follow-up.

# Replacement for the suppression sentence

The published post does not name the ignore file literally; the closest sentence is in the "Scanners are a second opinion" paragraph:

> The triage rule that keeps scanners honest: every finding is either fixed or suppressed with a written rationale in the repo.

One-line replacement that names the file as it exists now and how it is loaded:

> The triage rule that keeps scanners honest: every finding is either fixed or suppressed with a written rationale in the repo's `.trivyignore.yaml`.
