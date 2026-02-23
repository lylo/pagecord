---
name: support
description: Handle customer support emails - investigate issues and draft responses. Paste a customer email to get started.
---

# Customer Support Handler

Analyze customer emails, investigate their issues, and draft helpful responses.

## Input

The user pastes a customer email. This could be:
- A bug report or error they're experiencing
- A question about how something works
- A feature request or feedback
- Account/billing issues

## Process

### 1. Identify the Request Type

Read the email and categorize it:
- **Bug report**: Something isn't working as expected
- **How-to question**: User wants to know how to do something
- **Feature request**: User wants functionality that doesn't exist
- **Account/billing**: Issues with subscription, login, etc.

### 2. Investigate

**For bug reports:**
- Search the codebase for the affected feature
- Look at relevant models, controllers, and views
- Check for recent changes that might have caused the issue
- Identify the root cause or narrow down possibilities
- Suggest Rails console commands to investigate further if needed

**For how-to questions:**
- Search the codebase to understand how the feature works
- Check CLAUDE.md for documented features
- Check help.pagecord.com for existing help articles using WebFetch
- Find the relevant settings or steps the user needs

**For feature requests:**
- Check if the feature already exists (user might have missed it)
- Note if it's been considered or partially implemented
- Identify complexity/effort if implementation is straightforward

**For account/billing:**
- Check relevant models (User, Subscription, Blog)
- Look at Paddle webhook handling
- Identify what might have gone wrong

### 3. Prepare Response

Draft a customer-friendly email that:
- Acknowledges their issue/question
- Provides clear, helpful information
- Uses a friendly but professional tone
- Includes specific steps if applicable
- Offers to help further if needed

## Output

Always provide two sections:

### Internal Notes
- Summary of what was found
- Root cause (for bugs) or relevant code locations
- Recommended fix or investigation steps
- Any Rails console commands to run
- Links to relevant files in the codebase

### Draft Response
A ready-to-send email reply to the customer. Keep it:
- Concise and clear
- Friendly and helpful
- Specific to their issue
- Action-oriented when possible

**Formatting**: Output the draft response as plain text, NOT as a blockquote (no `>` prefixes). This makes it easy to copy and paste.

## Tips

- Check help.pagecord.com first for common questions - we may already have a help article
- For bugs, always try to reproduce the issue conceptually by reading the code
- If unsure, draft a response that asks clarifying questions
- For billing issues, remember Paddle handles all payment processing
- Consider if the user is on a trial vs subscribed (different feature access)
