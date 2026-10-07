# DevSecOps reference pipeline

A small Python API with a CI pipeline that **blocks a pull request** when it introduces insecure code, a leaked secret or a vulnerable dependency.

> 🇪🇸 Pipeline de referencia DevSecOps: una API pequeña en Python cuyo pipeline bloquea cualquier pull request que introduzca código inseguro, un secreto expuesto o una dependencia vulnerable.

## What runs on every pull request

| Control | Tool | Catches | Blocks merge when |
| --- | --- | --- | --- |
| Unit tests | pytest | Regressions, including security tests (SQL injection payloads, allow-list bypasses) | Any test fails |
| SAST | CodeQL (`security-extended`) | Injection, path traversal, unsafe deserialization and other code-level flaws | A new alert of high severity or above |
| Secret scanning | Gitleaks | API keys, tokens and passwords committed to the repository, across the full history | Any secret is found |
| Dependency audit | pip-audit | Known CVEs in `requirements.txt` | Any vulnerable package |
| Dependency review | GitHub dependency review | Vulnerable packages **added** by the pull request | A high or critical advisory |

A weekly scheduled run re-scans `main`, because new CVEs are published for code that did not change.

## See it working

The open pull request [**#3 "demo: introduce insecure changes"**](https://github.com/SV-Diablo/devsecops-pipeline/pull/3) adds three deliberate problems:

1. An endpoint that builds SQL with string formatting (SQL injection).
2. A hard-coded API key (fake, generated for this demo).
3. A dependency pinned to a version with known CVEs.

Each one is caught by a different control and the pull request cannot be merged. The PR is intentionally left open as evidence.

## Pipeline hardening decisions

- **Actions pinned by commit SHA**, not by tag: a moved or compromised tag cannot change what runs. Dependabot keeps the SHAs current.
- **Least-privilege `GITHUB_TOKEN`**: read-only by default; only the jobs that upload results get `security-events: write` or `pull-requests: write`.
- **Full-history secret scan** (`fetch-depth: 0`): a secret deleted in a later commit is still exposed in git history.
- **Fail closed**: every control is a required check on `main` through branch protection, and no one can push to `main` directly.
- **Owner approval**: `CODEOWNERS` assigns @SV-Diablo as reviewer of every file, so an outside pull request cannot be merged without the owner's approval, even with all checks green.
- **Fork workflows need approval**: Actions triggered by pull requests from outside contributors do not run until the owner approves them, so a fork cannot use the pipeline to run its own code.

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
pytest -q
```

## Author

Sebastian Villaseca · DevSecOps & Application Security · [LinkedIn](https://www.linkedin.com/in/sebastian-villaseca-19135523a)
