# AED Rules 4 + 5 — Intention-revealing names; comments say WHY, never WHAT
#
# Context: session establishment after a successful login. The same behavior,
# written twice. Note that the AFTER version has FEWER comments — good names
# removed the need for most of them, and the one comment that remains carries
# information the code cannot: the attack it prevents.

# ── BEFORE ────────────────────────────────────────────────────────────────────
# Cryptic names force a comment per line, and every comment restates the code.
#
#   # process the user
#   def do_it(u)
#     # reset the session
#     session.reset
#     # set the id
#     session[:uid] = u.id
#     # set the version
#     tmp = u.session_version
#     session[:sv] = tmp
#   end

# ── AFTER (AED) ───────────────────────────────────────────────────────────────
# The method name states the intent; the locals state what they hold; the one
# surviving comment explains a security decision no name could carry.

def establish_session(user : Users::Regular) : Nil
  # Rotate the session id BEFORE writing identity: prevents session fixation
  # (an attacker pre-planting a known session id that survives login).
  session.reset

  session[:user_id] = user.id
  session[:session_version] = user.session_version
end
