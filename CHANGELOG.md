# Changelog

Newest first. Dates are when the change landed on main.

## 2026-11

- Nov 18: README got an "If something doesn't work" section.
- Nov 14: README got a "What I'd do next" section.
- Nov 11: README got a small diagram of what the stack builds.
- Nov 10: README got a CI status badge.
- Nov 6: CI now uses terraform-linters/setup-tflint v6 (tflint itself stays on v0.53.0).
- Nov 5: CI now uses hashicorp/setup-terraform v4.
- Nov 3: CI now uses actions/checkout v7.

## 2026-10

- Oct 31: Dependabot now watches the GitHub Actions and Terraform provider versions.
- Oct 30: CI runs Terraform 1.16.7 instead of 1.9.8.
- Oct 26: The default Kubernetes version moved from 1.31 to 1.35, so it stays in standard support.
- Oct 15: Trivy cleaned up: it scans before `terraform init` so downloaded modules are left out, and the findings that are on purpose (including the default network ACL) are ignored in `.trivyignore`, each with a reason. The test pod was hardened.
- Oct 15: First version: EKS cluster with a GPU node group that starts at zero, validated and scanned in CI. Never applied to a real account.
