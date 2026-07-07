# AED Rule 3 — Prefer explicit guard clauses to nested ternaries / one-liners
#
# Context: a password-verification method on a user model. Returns the user
# on success, nil on any failure. The guard-clause form doubles as the
# security argument: each line is one condition under which entry is refused.

# ── BEFORE ────────────────────────────────────────────────────────────────────
# One line, two nested ternaries, three outcomes. The author saved four lines;
# every future reader re-parses the precedence to find out what happens when.
#
#   def verify_password(password : String) : self?
#     password_digest.empty? ? nil : (Crypto::Bcrypt::Password.new(password_digest).verify(password) ? self : nil)
#   end

# ── AFTER (AED) ───────────────────────────────────────────────────────────────
# The guards read as a doorman's checklist: no digest, no entry; wrong
# password, no entry. Everything after the guards assumes both checks passed.

def verify_password(password : String) : self?
  return nil if password_digest.empty?
  return nil unless Crypto::Bcrypt::Password.new(password_digest).verify(password)

  self
end
