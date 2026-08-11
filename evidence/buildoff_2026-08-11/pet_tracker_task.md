You are working in a Crystal / Amber web application template you have never seen before. Read CLAUDE.md first, then build the following feature completely.

Feature: a pet tracker. Basic CRUD, no authentication.

Requirements:
1. A `Pet` resource with fields: name (required string), species (required string), breed (optional string), birthdate (optional date/time).
2. A migration SQL file under `db/migrations/` following the naming and format conventions of the existing migration files there. Do NOT run the migration — just write the file.
3. A Grant model under `src/models/` following the conventions of the existing models.
4. A RESTful controller under `src/controllers/` with index, show, new, create, edit, update, and destroy actions, following the conventions of the existing controllers (parameter validation, responses, error handling).
5. Routes registered the way the existing routes are registered.
6. An index view page listing pets and a form page for creating/editing, built with the template's component-based view system, consistent with how existing pages are built (read the view/component conventions before writing these).
7. The whole application must type-check cleanly when you are done: `crystal build --no-codegen src/premium_agentc_app_template.cr` must exit with no errors. Run it yourself and fix anything it reports before finishing.

Do not run migrations, do not run the spec suite, do not start the server. Work autonomously to completion; do not ask questions. When finished, summarize what you created in one short paragraph.
