# UI Review Skill

When reviewing UI changes:
1. Check all state transitions (loading, sending, sent, error)
2. Verify data availability after redirects - are background jobs involved?
3. Confirm subscriber/record counts aren't read before async jobs complete
4. Test both happy path and edge cases for timing
5. Run the relevant system tests if they exist
