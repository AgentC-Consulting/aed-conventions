# AED Rule 2 — Name the thing; don't make the reader decode a chain
#
# Context: an OAuth callback verifying the `state` parameter against the value
# issued at the start of the flow. This is security-critical code — exactly
# where a reader (human or agent) must be able to verify intent at a glance.

# ── BEFORE ────────────────────────────────────────────────────────────────────
# Terse, but the reader has to hold three operations in their head at once:
# a nilable session lookup, a block binding, and a comparison — all inside a
# negated guard.
#
#   return unless session["oauth_state"]?.try { |s| constant_time_equal?(s, state) }

# ── AFTER (AED) ───────────────────────────────────────────────────────────────
# Naming the intermediate turns the same logic into two plain statements:
# "this is the state we expected; refuse unless it exists and matches."

expected_state = session["oauth_state"]?
return unless expected_state && constant_time_equal?(expected_state, state)
