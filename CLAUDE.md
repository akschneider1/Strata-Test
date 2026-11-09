# Strata-Test: notes for Claude

A monorepo of Nava Strata apps styled with the Colorado Design System (CoDS).
Read README.md first.

## Rules

- Create apps only with `bin/new-app <rails|nextjs|flask> <name>`. Never copy
  template files by hand. The script installs the template plus its infra
  layer through `nava-platform` (which records answers in
  `.template-application-*/<name>.yml` and `.template-infra/app-<name>.yml`),
  applies the CoDS/Strata customizations, commits, and runs the tests.
- All pinned versions are in `stack/versions.env`. Change versions there and
  re-run the scripts; don't edit pinned URLs or refs inside apps.
- Customizations live in `bin/new-app` (`customize_*` functions) and
  `stack/cods/`. They must stay idempotent: `bin/new-app --reapply <app>`
  on an up-to-date app should produce no diff.
- After `nava-platform app update`, run `bin/new-app --reapply <app>`.
- UI markup: use USWDS markup paired with CoDS classes, e.g.
  `class="usa-button cods-button"`. CoDS fixtures (canonical markup) are at
  `<app>/node_modules/@coloradodigitalservice/colorado-design-system/dist/fixtures/`.
  Put CoDS gap fixes in `stack/cods/_cods-compat.scss`, never in a single app.
- Rails apps: build features with the Strata SDK (`strata` gem: ApplicationForm,
  Case, flows, form builder, `Strata::US::*` components) before writing custom
  code. SDK docs: https://github.com/navapbc/strata-sdk-rails/tree/main/docs
- Don't load CoDS's JS bundle alongside `uswds.min.js`. Both bind the accordion.

## Running things

- Toolchain: `bin/setup-env --postgres`, then check with `bin/doctor`.
  Ruby versions are managed by rbenv; scripts put `$(rbenv root)/shims` on PATH.
- Check an app: `bin/new-app --verify <app>`.
  - Rails: `bundle exec rspec`. CSS is built by `npm run build:css`.
  - Next.js: `npm run lint && npm run ts:check && npm test && npm run build`.
  - Flask (native): `PY_RUN_APPROACH=local make test`, with `local.env` loaded and
    `DB_NAME=<app_with_underscores>`.
- Local Postgres: 127.0.0.1:5432, role `app` / `secret123`. Each app uses its own
  database name (`<app>_development`, `<app>_test`).
- Repo lint (also run in CI): `shellcheck bin/**`, `actionlint`,
  `make infra-lint-terraform`.
