---
name: sentry
description: Fix a Sentry error and create a PR. Usage: /sentry <issue-url-or-id>
---

# Sentry Issue Fixer

Automatically analyze a Sentry error, find the root cause, implement a fix, and create a PR.

## Input

The user provides either:
- A full Sentry issue URL (e.g., `https://sentry.io/organizations/pagecord/issues/123456/`)
- A short issue ID (e.g., `PAGECORD-123`)

If only an ID is provided, use organization slug `pagecord`.

## Steps

### 1. Get Issue Details

Use the Sentry MCP `get_issue_details` tool to fetch:
- Error message and type
- Stack trace
- Affected file(s) and line numbers
- Frequency and user impact

### 2. Get Root Cause Analysis

Use the Sentry MCP `analyze_issue_with_seer` tool to get AI-powered analysis:
- Root cause explanation
- Suggested fix approach

### 3. Explore the Codebase

Read the affected files identified in the stack trace. Understand:
- The code flow that led to the error
- Related code that might need changes
- Existing patterns in the codebase

### 4. Implement the Fix

- Create a new branch: `fix/sentry-{issue-id}` (lowercase, e.g., `fix/sentry-pagecord-123`)
- Make the minimal changes needed to fix the issue
- Follow existing code patterns and style
- Add a test if the fix is testable

### 5. Verify the Fix

Run relevant tests to ensure:
- The fix doesn't break existing functionality
- New test (if added) passes

### 6. Create a PR

Create a pull request with:
- Title: `Fix: {brief description of the error}`
- Body including:
  - Link to the Sentry issue
  - What was causing the error
  - How the fix resolves it
  - Test plan

## Output

Summarize:
- What the error was
- What caused it
- What was changed to fix it
- Link to the PR
