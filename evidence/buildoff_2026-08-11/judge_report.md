# Judge reports — pet-tracker build-off (2026-08-11)

Adversarial review of all four runs' uncommitted diffs. Same reviewer (a larger
model), same rubric, deliberately harsh, applied identically. Framework behavior
claims were verified against the framework source in-repo before grading (router,
CSRF pipe, params handling), and one formatting claim was verified by executing
Crystal. Condensed from the reviewer's two reports; defect locations kept verbatim.

## Verified framework basis (checked, not assumed)

- Amber `resources` registers GET/POST plus PUT|PATCH and DELETE on `/x/:id`.
- **`_method` override does not work in this Amber**: routing matches the real HTTP
  verb only (`router.cr:61`); the `_method` constant exists but nothing rewrites the
  verb. An HTML form can only GET/POST.
- **CSRF is enforced** on the `:web` pipeline for every write; forms without `_csrf`
  403.
- Repo flash convention: `flash[:danger]`, surfaced via `flash_error:` on the layout.
- Design system classes that exist: `.btn--primary/--secondary/--danger/--ghost/--sm`,
  `.field/.field__label/.field__input`, `.stack/.stack-lg/.stack-sm`, `.grid/.grid-2/3/4`.
  `Time#to_s` is strftime-style: `to_s("YYYY-MM-DD")` emits the literal string
  `YYYY-MM-DD` (executed and confirmed).

## Scores

| | before-1 | before-2 | after-1 | after-2 |
|---|---|---|---|---|
| Completeness /10 | 5 | 4 | 6 | 8 |
| Conformance /10 | 5 | 4 | 6 | 8 |
| Defects (major, minor) | 4, 6 | 2, 9 | 3, 8 | 2, 7 |
| Naming /10 | 7 | 5 | 7 | 8 |
| **Working journeys /5** | **0** | **0** | **2** | **4** |
| JSON serialization correct | ✗ | ✗ | ✓ | ✓ |
| Flash key convention | ✗ | ✗ | ✓ | ✓ |
| Flash actually renders | ✗ | ✗ | ✗ | ✓ |
| CSRF on forms | ✗ | ✗ | ✗ | ✓ (not index) |
| Real design-system classes | ✗ | ✗ | ✗ | ✓ |
| `Public::` namespace | ✓ | ✓ | ✓ | ✗ |
| Forms match registered routes | ✗ | ✓ | ✗ | ✗ (delete only) |
| Ran any write path | ✗ | ✗ | ✗ | ✗ |

Ranking: after-2 > after-1 ≫ before-1 > before-2.

## Major defects per run (verbatim locations)

**before-1** (0/5 journeys): index double-encodes JSON
(`pets.map(&.to_json).to_json`, controller:12 + index component:8) and the inline
`rescue` swallows the parse failure, so /pets always renders "No pets yet"; edit form
POSTs to a PUT/PATCH-only route (404, update unreachable); delete form POSTs
`/pets/:id/destroy`, which doesn't exist (404); no `_csrf` on any form (403 on every
write).

**before-2** (0/5): same JSON double-encoding, but the `TypeCastError` lands outside
the rescue, so /pets 500s the moment one pet exists; no `_csrf` anywhere; plus a
`show` action that was never routed and renders an edit form, a dead ternary
(`action == "update" ? "POST" : "POST"`), and an edit form whose birthdate is always
blank.

**after-1** (2/5): no `_csrf` (403 on create); edit and delete forms rely on
`_method` tunneling this Amber ignores, against patch/delete-only routes (404,
update and destroy unreachable). Serialization, flash keys, namespacing, and the
migration are correct; `to_s("YYYY-MM-DD")` renders a literal string into the date
input; `first_name` for a pet's name is a lying identifier and propagates to the
column.

**after-2** (4/5): delete form POSTs `/pets/:id` with `_method=DELETE`; because it
also registered `post "/pets/:id" → :update`, **clicking Delete silently updates the
pet and reports success** (the most dangerous failure in the experiment); the index
form also renders an empty `_csrf`. Everything else works: index, show, create,
edit/update, correct CSRF elsewhere, correct flash plumbing, and the only markup in
the experiment using the design system that actually exists.

## The reviewer's arm-level findings

1. **The before arm failed the same way twice.** Both terse-arm runs independently
   wrote the identical double-encoding line shape; it destroyed the index in both
   (silently empty / hard 500). Neither after-run made it: 2/2 vs 0/2, both
   directions. Same clean split on the flash convention.
2. **What improved is what conventions can carry** (serialization shape, flash keys,
   reading the real stylesheet). What did not: facts nobody wrote down, chiefly that
   this Amber has no `_method` tunneling; both after-runs assumed it (now documented,
   premium-agentc-app-template PR #26).
3. **The invariant across all four runs: no agent executed a write path.** Every
   difference above is a difference in how good the guessing was.
