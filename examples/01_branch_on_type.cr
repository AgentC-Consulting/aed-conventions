# AED Rule 1 — Branch on type with an explicit `if … is_a?`, not a clever `case`
#
# Context: a login controller that stores a different session shape depending
# on which kind of user just authenticated. `user` is a union type
# (Users::Regular | Users::Admin) returned by an ORM lookup.

# ── BEFORE ────────────────────────────────────────────────────────────────────
# `case … in` demands exhaustive matching and, under the Grant ORM's
# `Grant::Base+` inference, fails to compile:
#   Error: case is not exhaustive. Missing types: Grant::Base
#
#   case user
#   in Users::Regular
#     session[:user_type] = "regular"
#     session[:session_version] = user.session_version
#   in Users::Admin
#     session[:user_type] = "admin"
#   end
#
# The dot-receiver sugar compiles, but the leading dot is a riddle the reader
# must decode before they even reach the branch bodies:
#
#   case user
#   when .is_a?(Users::Regular)
#     session[:user_type] = "regular"
#     session[:session_version] = user.session_version
#   when .is_a?(Users::Admin)
#     session[:user_type] = "admin"
#   end

# ── AFTER (AED) ───────────────────────────────────────────────────────────────
# An ordinary `if` reads like a sentence: "if the user is a regular user,
# record a regular session; otherwise it is an admin session."

if user.is_a?(Users::Regular)
  session[:user_type] = "regular"
  session[:session_version] = user.session_version
else
  session[:user_type] = "admin"
end
