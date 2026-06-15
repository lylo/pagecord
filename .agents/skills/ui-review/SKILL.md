---
name: ui-review
description: Review UI changes for state, timing, redirects, async behaviour, and browser-level test gaps. Use when the user asks specifically for a UI review or frontend workflow review.
allowed-tools: Bash, Read, Grep
---

# UI Review

When reviewing UI changes:

1. Check all state transitions: loading, sending, sent, and error.
2. Verify data availability after redirects, especially when background jobs are involved.
3. Confirm subscriber and record counts are not read before async work completes.
4. Test both happy path and timing edge cases.
5. Run the relevant system tests when they exist.

Lead with findings ordered by severity. If no issues are found, say that clearly and mention any untested browser or timing risk.
