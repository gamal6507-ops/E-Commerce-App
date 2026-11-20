# Store release implementation plan

> **For agentic workers:** Use superpowers:executing-plans task by task.

**Goal:** Repair the reviewed Flutter store and publish its source and web release.
**Architecture:** Flutter client, Firebase identity/data, trusted Vercel order API.
**Tech Stack:** Dart/Flutter, Node.js, Firebase Admin, Firestore.
**Spec:** docs/superpowers/specs/2026-11-19-store-design.md

## Global constraints
No password/PAN/CVV storage or logs. No simulated card payment. Every trusted write verifies Firebase identity. Secrets remain outside Git. Preserve Arabic/English UI.

## Review focus
- Price/quantity manipulation and out-of-stock concurrent orders.
- Duplicate order after timeouts or failed notification delivery.
- Legacy profiles/addresses and stale product cache.
- Web/native plugin differences and unavailable server credentials.
- Administrative authorization and cross-user access.

## Tasks
- [x] 1. Restore dependencies, replace counter test, add regressions for secrets/cache/sizes; repair client models and startup.
- [x] 2. Implement and test authenticated transactional order service, inventory, idempotency, transitions and account deletion.
- [x] 3. Connect checkout, full addresses, order details/actions, admin screens, identity verification and device tokens.
- [x] 4. Harden rules, add emulator tests, cleanup tools, CI and operational documentation.
- [x] 5. Run full checks, independent review, commit/push and deploy Vercel; smoke-check deployment and report blockers.

## Progress / rulings
- User's "do everything then upload" authorizes implementation and publication; continue without an additional design approval round.
- Use existing clean checkout on a feature branch; avoid introducing another worktree.
- External paid services are integrated only when an account is supplied; COD is the available method meanwhile.
