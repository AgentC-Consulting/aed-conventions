# External distribution targets — AED Conventions plugin

> **NOTHING HERE HAS BEEN SUBMITTED.** This is a research dossier only — no
> account was created, no PR opened, no post made, no form submitted. The
> owner decides what goes out, when, and from which account.

Researched and live-verified 2026-08-01. "Verified" means a live web fetch of
the actual URL that day, not a search-result snippet — noted per row below.
Two targets (Reddit) could not be directly fetched because the fetch tool is
blocked by Reddit's anti-bot layer; they're kept in because the communities
are unambiguously live and large, but flagged as **secondary-verification
only** — re-check the live rules page before posting.

The thing being listed: **AED (Agent-Enhanced Development)** — naming and
process-manager conventions for codebases written and maintained by humans
and coding agents together, shipped as the Claude Code plugin `aed` in the
`aed-conventions` marketplace (skills, a planning-stage naming linter, and an
edit-time hook for Ruby, Crystal, and Elixir).

Install one-liner to feature in every listing:
```
/plugin marketplace add AgentC-Consulting/aed-conventions
/plugin install aed@aed-conventions
```
Repo: https://github.com/AgentC-Consulting/aed-conventions

---

## Summary table

| # | Name | Type | Audience | Priority | Verified live 2026-08-01 |
|---|---|---|---|---|---|
| 1 | Official Claude community marketplace (`claude-plugins-community`) | Anthropic-run marketplace | Every Claude Code user browsing `/plugin` | **P1** | Yes — direct fetch of docs + repo |
| 2 | `hesreallyhim/awesome-claude-code` | Curated "awesome" list (GitHub) | Claude Code power users, 51.5k stargazers | **P1** | Yes — direct fetch, incl. CONTRIBUTING.md |
| 3 | `travisvn/awesome-claude-skills` | Curated skills list (GitHub) | Claude Skills authors/users, 14.5k stars | **P1** | Yes — direct fetch |
| 4 | SkillsClaude (skillsclaude.org) | Auto-crawled skills directory | Devs browsing/comparing skills, 7.2k listed | P2 | Yes — direct fetch |
| 5 | Claude Code Marketplaces (claudemarketplaces.com) | Traffic-heavy community directory | Devs discovering plugins, ~380k monthly visitors claimed | P2 | Yes — direct fetch (submission mechanism unclear, see notes) |
| 6 | Crystal Forum (forum.crystal-lang.org) | Language community forum | Crystal devs — direct audience for the linter | P2 | Yes — direct fetch |
| 7 | Elixir Forum (elixirforum.com) | Language community forum | Elixir devs — direct audience for the linter | P2 | Yes — direct fetch |
| 8 | dev.to | Blog/publishing platform | Broad dev audience, AI/agents tag active | P2 | Yes — direct fetch (site only; two v1.0-voice drafts already exist, unedited) |
| 9 | Hacker News "Show HN" | Launch/link-aggregator | Broad tech audience, high variance | P3 | Yes — direct fetch of guidelines |
| 10 | lobste.rs | Invite-only link aggregator | Careful, technical, low-hype crowd | P3 | Yes — direct fetch of /about |
| 11 | `ccplugins/awesome-claude-code-plugins` | Curated plugin list (GitHub) | Plugin-specific browsers, 893 stars | P3 | Yes — direct fetch, but repo activity is sparse (7 commits) |
| 12 | r/ClaudeAI (reddit) | Subreddit | Broad Claude user base | P3 | **Secondary only** — fetch blocked by Reddit; existence/size via search |
| 13 | r/ClaudeCode (reddit) | Subreddit | Claude Code specifically, ~355k members | P3 | **Secondary only** — same block |
| 14 | r/ruby (reddit) | Subreddit | Ruby devs | P3 | **Secondary only** — same block |

14 targets total, **11 directly fetched and confirmed live today**, 3 confirmed live only via secondary evidence (Reddit). Well above the ≥6 verified-live bar.

---

## P1 — submit first

### 1. Official Claude plugin community marketplace
- **URL (docs):** https://code.claude.com/docs/en/plugins#submit-your-plugin-to-the-official-marketplace
- **URL (catalog repo):** https://github.com/anthropics/claude-plugins-community (confirmed live: 332 stars, 81 forks, Apache-2.0, active)
- **URL (official curated repo, for contrast):** https://github.com/anthropics/claude-plugins-official (confirmed live: 32.9k stars, 2,763 commits — but this one is Anthropic-curated with **no application process**; do not target it directly)
- **Submission mechanism:** in-app/web form, reviewed by Anthropic, then synced nightly into a public GitHub catalog. Two form endpoints depending on account type:
  - claude.ai: `claude.ai/admin-settings/directory/submissions/plugins/new` — requires a Team/Enterprise org with directory-management access (org Owners have this by default)
  - Console (individual authors, our case): `platform.claude.com/plugins/submit`
- **Exact steps:**
  1. Run `claude plugin validate ./plugins/aed` locally first — same check the review pipeline runs, plus automated safety screening. Must print "Validation passed" (warnings OK, use `--strict` to catch them as errors before submitting).
  2. Submit via `platform.claude.com/plugins/submit` (individual author path — AgentC Consulting is not shown to be a Team/Enterprise org here).
  3. Wait for review + nightly sync. Approved plugins are pinned to a commit SHA in `anthropics/claude-plugins-community`'s `marketplace.json`; CI auto-bumps the pin on new commits.
  4. Once listed, users get it via `claude plugin marketplace add anthropics/claude-plugins-community` then `claude plugin install aed@claude-community` — a second, wider distribution surface alongside our own `aed-conventions` marketplace.
- **Effort:** S (the form itself) but gated on `claude plugin validate` passing and an unknown review turnaround.
- **Listing content needed:** plugin name (`aed`), one-liner description (already in `plugin.json`), repo URL, license, author.
- **Why P1:** this is the only channel that puts the plugin directly inside every Claude Code user's native `/plugin` browsing flow — no GitHub-literacy required from the installer.

### 2. `hesreallyhim/awesome-claude-code`
- **URL:** https://github.com/hesreallyhim/awesome-claude-code
- **Type:** curated GitHub "awesome" list, 51.5k stars, 1,412 commits — the largest, most active list found.
- **Audience:** developers actively browsing for Claude Code skills/plugins/tooling.
- **Submission mechanism:** **web UI issue form ONLY** — the repo explicitly warns that PRs are not the path: "ALL RECOMMENDATIONS MUST BE MADE USING THE WEB UI ISSUE FORM TEMPLATE, OR YOU RISK BEING RESTRICTED FROM INTERACTING WITH THIS REPOSITORY TEMPORARILY."
- **Exact steps:**
  1. Read CONTRIBUTING.md + Code of Conduct first.
  2. Open the issue form: https://github.com/hesreallyhim/awesome-claude-code/issues/new?template=recommend-resource.yml
  3. Fill every field. Write the description factually ("state what the software does"), single line, no emojis, no marketing address-to-reader language.
  4. A bot auto-validates format (not quality/acceptance) and auto-discovers the license from the repo's GitHub license file — our repo needs a machine-detectable LICENSE for this to register cleanly (we're dual-licensed: CC BY 4.0 for docs, MIT for `examples/` — confirm which one GitHub's license detector will surface).
- **Effort:** S.
- **Listing content needed:** factual one-line description, category (list has no rigid category taxonomy stated), confirmation of human authorship of the *recommendation* (fine — a human is doing the submitting).
- **Priority reason:** biggest audience of any list found; explicit, low-ambiguity submission path.

### 3. `travisvn/awesome-claude-skills`
- **URL:** https://github.com/travisvn/awesome-claude-skills
- **Type:** curated GitHub list specifically for Claude *Skills* (not just plugins) — 14.5k stars, 1.8k forks, 640 PRs, updated as recently as Feb 2026 per repo badge.
- **Audience:** builders/users of Claude Skills specifically — a strong match since `aed` ships 3 skills (`aed:naming`, `aed:planning`, `aed:process-managers`).
- **Submission mechanism:** fork → add entry to the right category section → PR. ("Fork, add to appropriate section, submit PR.")
- **Exact steps:** fork repo, edit README under the matching category (e.g. Development), add one line (name, link, short description), open PR against `main`.
- **Effort:** S.
- **Listing content needed:** name, repo/marketplace link, one-line description, category.
- **Priority reason:** skills-specific audience, clear low-friction PR path, active repo.

---

## P2

### 4. SkillsClaude
- **URL:** https://skillsclaude.org/skills · submit at `/submit`
- **Type:** auto-crawled directory, 7,246 skills listed, five-level trust ladder (official / featured / tested / verified / unverified).
- **Submission mechanism:** submit the GitHub repo URL at `/submit`; the site reads the skill straight from GitHub and grades it.
- **Exact steps:** visit `/submit`, paste `https://github.com/AgentC-Consulting/aed-conventions` (or the specific skill path), wait for crawl/grading.
- **Effort:** S.
- **Listing content needed:** none beyond the repo URL — it reads `SKILL.md` frontmatter directly, so the existing `description:` fields in each skill do the work.

### 5. Claude Code Marketplaces (claudemarketplaces.com)
- **URL:** https://claudemarketplaces.com/ (marketplaces index: `/marketplaces`)
- **Type:** high-traffic community directory (~380k monthly visitors claimed on-page), independent, not Anthropic-affiliated.
- **Submission mechanism:** **unclear from the public page** — no visible submit form for marketplaces/plugins; the only prominent CTA is an `/advertise` (paid) link. May be auto-crawled from GitHub topics/marketplace.json files, or may require contacting the site owner (built by "mertbuilds.com" per footer).
- **Exact steps:** check `/advertise` and look for a contact link before assuming this needs a paid slot; do not pay for a listing without owner sign-off regardless.
- **Effort:** M (mechanism needs to be resolved first).
- **Listing content needed:** unknown pending mechanism confirmation.

### 6. Crystal Forum
- **URL:** https://forum.crystal-lang.org/ — category: **Community** (`/c/community/7`)
- **Type:** official language community forum.
- **Audience:** Crystal developers — one of the three languages the linter/hook directly supports.
- **Submission mechanism:** forum post (standard Discourse). Category "Community" is described as the place to "gather together to work on ideas or shards to be implemented in the community" — the right fit for an announcement. "Crystal Contrib" (`/c/crystal-contrib/6`) is a secondary option if positioned as tooling/convention-relevant rather than a community project.
- **Exact steps:** create/log into a forum account, post in Community with title + the 1-paragraph blurb + install one-liner + repo link.
- **Effort:** S (posting) but content should be the owner's voice, not the v1.0-voice drafts already in `drafts/`.
- **Listing content needed:** title, 1-paragraph blurb, link.

### 7. Elixir Forum
- **URL:** https://elixirforum.com/ — category: **News > Announcing** (`/news/announcing`)
- **Type:** official language community forum, very active (posts dated the same day as this research).
- **Audience:** Elixir developers — second of the three supported languages.
- **Submission mechanism:** forum post; Announcing is explicitly for library/tool releases. Suggested tags: `#library`, `#project`, possibly `#ai`.
- **Exact steps:** account + post, same content pattern as Crystal Forum.
- **Effort:** S.
- **Listing content needed:** title, 1-paragraph blurb, tags.

### 8. dev.to
- **URL:** https://dev.to/
- **Type:** blog/publishing platform, 4M+ developers, active AI/agents/programming tags.
- **Audience:** broad technical readership; strong fit for a longer-form piece on the doctrine (token windows, naming, process managers).
- **Submission mechanism:** create account, write + publish a post.
- **Important:** two dev.to drafts already exist in this repo (`drafts/devto-post-a-code-that-reads-like-statements.md`, `drafts/devto-post-b-writing-code-for-the-agents.md`) — **both are v1.0-voice, describe AED as only the six edit-level rules, and have never been published.** They need the owner's voice review and a v1.1.0-rc.1 reframe before they're postable. Per the "Do not" boundary on this job, they were **not edited** here.
- **Effort:** L (needs the actual rewrite, not just a submit click).
- **Listing content needed:** full post body (existing drafts are the starting point, not the deliverable).

---

## P3

### 9. Hacker News "Show HN"
- **URL:** https://news.ycombinator.com/showhn.html
- **Type:** launch/link-aggregator, one-shot, high variance (front page or ignored).
- **Submission mechanism:** post titled "Show HN: …", must be something people can try with minimal friction (no signup/email walls — a `curl`/`/plugin install` one-liner satisfies this well).
- **Exact steps:** submit via HN's normal submit form once logged in, title starting "Show HN:", link to the repo or a landing page.
- **Effort:** S to post, but reputationally one-shot — best timed deliberately, not as a first move.
- **Listing content needed:** title + the repo link; HN discourages "reading-only content" so the repo itself (installable) is the right link, not a blog post.

### 10. lobste.rs
- **URL:** https://lobste.rs/about
- **Type:** invite-only technical link aggregator, live since 2012, active moderation.
- **Submission mechanism:** **requires an invitation** — "the quickest way to receive an invitation is to talk to someone you recognize from the site," or join their chat first. New accounts also carry a 70-day restriction on submitting to new domains and on flagging.
- **Effort:** M–L (the barrier is the invite, not the post).
- **Listing content needed:** none yet — this is blocked on getting an account.

### 11. `ccplugins/awesome-claude-code-plugins`
- **URL:** https://github.com/ccplugins/awesome-claude-code-plugins
- **Type:** curated plugin list, 893 stars, 341 forks — but only **7 commits** on the repo, so activity is sparse despite the star count.
- **Submission mechanism:** README states "Contributions are welcome! You can add your favorite plugins... or submit your own marketplace," implying a PR-based flow, but no CONTRIBUTING.md content was surfaced to confirm exact format.
- **Effort:** S, but confirm the PR format against actual merged PRs before submitting (172 PRs listed on the repo — check a recent merged one as a template).
- **Priority reason (P3 not P2):** decent star count but low commit activity raises maintenance-risk; check for a recent merge before relying on it.

### 12–14. Reddit (r/ClaudeAI, r/ClaudeCode, r/ruby)
- **URLs:** reddit.com/r/ClaudeAI, reddit.com/r/ClaudeCode (~355k members), reddit.com/r/ruby
- **Verification caveat:** the fetch tool used for this research is blocked from `reddit.com` and `old.reddit.com` outright (anti-bot measure, not a dead-site signal) — sizes/existence above come from a secondary source (a subreddit-stats aggregator), not a direct fetch of the subreddit or its rules page. **Re-check each subreddit's live rules/sidebar for self-promotion policy before posting** — most programming subreddits gate self-promo behind a minimum karma/tenure or a specific weekly thread, and that can change without notice.
- **Submission mechanism:** standard Reddit post, once account meets whatever karma/age gate the mods enforce.
- **Effort:** S to post, but S–M to first confirm you're eligible to post at all.
- **Priority reason (P3):** real audience, but unverified rules today = higher risk of a removed post or a ban-on-sight for low-karma self-promotion.

---

## Ready-to-paste blurbs

**1-paragraph (listing / forum-post body):**

> AED (Agent-Enhanced Development) is a set of naming and process conventions
> for codebases that humans and coding agents write together. The core rule:
> prefer the form that reads like a plain statement of intent, and reach for
> shorthand only when it makes the intent clearer, never just shorter. AED
> covers verbose naming (`list_of_`, boolean-as-question), process managers
> built from When-statements, feature stories for briefing an agent, and
> six edit-level style rules — plus a Claude Code plugin that ships it as
> skills, a planning-stage naming linter, and an edit-time hook, for Ruby,
> Crystal, and Elixir. Naming conventions your coding agent can actually
> follow, enforced from pseudocode to release. Install: `/plugin marketplace
> add AgentC-Consulting/aed-conventions` then `/plugin install
> aed@aed-conventions`.

**3-line blurb:**

> AED gives your coding agent naming conventions it can actually follow —
> verbose, unambiguous, checked from pseudocode through review.
> Ships as a Claude Code plugin: naming + process-manager skills, a
> planning-stage name checker, and an edit-time hook, for Ruby, Crystal, and
> Elixir.
> `/plugin marketplace add AgentC-Consulting/aed-conventions` →
> `/plugin install aed@aed-conventions`

**Tweet-length blurb (234 characters):**

> Naming conventions your coding agent can actually follow — enforced from
> pseudocode to release. AED ships as a Claude Code plugin: skills + a
> linter, for Ruby/Crystal/Elixir.
> `/plugin marketplace add AgentC-Consulting/aed-conventions`

---

## Notable finding

Anthropic runs **two** public marketplaces, not one: `claude-plugins-official`
(Anthropic-curated, no application process — don't bother submitting there
directly) and `claude-plugins-community` (public, third-party submissions via
`platform.claude.com/plugins/submit` or a claude.ai Team/Enterprise form,
reviewed, then nightly-synced into a public GitHub catalog). This is the
single highest-leverage listing found — see P1 §1 above for the exact
`claude plugin validate` + submit steps.
