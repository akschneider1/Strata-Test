# Strata-Test

A monorepo for building State of Colorado digital services on
[Nava Strata](https://github.com/navapbc/strata), styled with the
[Colorado Design System (CoDS)](https://github.com/coloradodigitalservice/colorado-design-system)
instead of plain USWDS.

It contains the full Strata suite, ready to generate apps from:

| Piece | What it gives you | Where it lives |
| --- | --- | --- |
| [AWS infra template](https://github.com/navapbc/template-infra) | Terraform, CI/CD workflows, PR + ADR templates | `infra/`, `.github/`, `docs/`, root `Makefile` (installed) |
| [Rails app template](https://github.com/navapbc/template-application-rails) + [Strata SDK](https://github.com/navapbc/strata-sdk-rails) | Server-rendered apps: intake forms, case management, staff tools | `bin/new-app rails <name>` |
| [Next.js app template](https://github.com/navapbc/template-application-nextjs) | React front ends, Storybook | `bin/new-app nextjs <name>` |
| [Flask app template](https://github.com/navapbc/template-application-flask) | Python APIs, data/batch jobs, OpenAPI | `bin/new-app flask <name>` |
| [nava-platform CLI](https://github.com/navapbc/platform-cli) | Installs and updates the templates | installed by `bin/setup-env` |

## Apps

| App | What it is |
| --- | --- |
| [`tax-portal`](tax-portal/) | Prototype Colorado individual income tax portal: taxpayer filing, automatic processing and examiner review (Rails, Strata SDK) |
| [`tax-engine`](tax-engine/) | Tax calculation API backed by PolicyEngine US (Flask) |

To see the prototype, run the two commands below and open <http://localhost:3100>.
The click-by-click script is in [docs/tax-portal/demo-guide.md](docs/tax-portal/demo-guide.md).
What to learn from the IRS's own free filing service is in
[docs/tax-portal/direct-file-lessons.md](docs/tax-portal/direct-file-lessons.md),
and a script for testing the prototype with people is in
[docs/tax-portal/usability-test-kit.md](docs/tax-portal/usability-test-kit.md).
The UX audit of the taxpayer portal is in
[docs/tax-portal/ux-audit.md](docs/tax-portal/ux-audit.md).

```bash
bin/setup-env --postgres
```

```bash
bin/demo
```

To show it somewhere other than your own machine or AWS (Docker, Render,
Replit and others), see [docs/hosting.md](docs/hosting.md).

More apps are created from requirements with one command each.

## Quick start

```bash
git clone https://github.com/akschneider1/Strata-Test.git && cd Strata-Test
```

```bash
bin/setup-env --postgres   # toolchain + a local Postgres (omit --postgres if you use Docker)
```

```bash
bin/doctor                 # confirm everything is installed and pinned correctly
```

```bash
bin/new-app rails intake   # or: nextjs <name> / flask <name>
```

`bin/new-app` installs the template and its infra layer, swaps USWDS for
CoDS, adds the Strata SDK (Rails only), commits each step, then installs
dependencies and runs the app's tests. After that, follow `<app>/README.md` to run it.

### Prerequisites

`bin/setup-env` installs most things. It expects these to be present already:
`git`, Node.js 20 or newer, `uv`, Python 3.13 (uv can install it), and `rbenv`.
Docker is optional; each app's `docker compose` setup works as Nava documents it.

## Commands

| Command | Purpose |
| --- | --- |
| `bin/setup-env [--postgres]` | Install or refresh the toolchain: nava-platform, Ruby (per `.ruby-version`), Poetry, terraform, actionlint, shellcheck. With `--postgres`, also start a local Postgres with the `app`/`secret123` role the templates use. |
| `bin/doctor` | Show tool versions, what's pinned, and the apps in the repo. |
| `bin/new-app <rails\|nextjs\|flask> <name> [--port N] [--skip-verify]` | Create an app from a Strata template. Ports default to 3000, 3100, 3200… |
| `bin/new-app --reapply <name>` | Re-apply the CoDS/Strata customizations (idempotent). Run this after a template update. |
| `bin/new-app --verify <name>` | Install dependencies and run the app's lint and tests. |
| `bin/demo [test\|reset]` | Run the tax prototype with demo data; `test` also runs the browser walkthrough. |
| `bin/serve [--reset]` | Run the tax prototype as a hosted demo (production-like, no Docker). See [docs/hosting.md](docs/hosting.md). |
| `bin/hosting-secrets` | Print a fresh set of secrets for a hosted demo. |
| `bin/cods-upgrade <version>` | Move every app to another CoDS release, after verifying the release checksums. |
| `make help` | Infra targets from the AWS template (`infra-lint`, `release-build`, …). |

## How the Colorado Design System is wired in

CoDS is built on USWDS 3.14: it keeps USWDS's `usa-*` markup and layers
Colorado tokens, fonts and `cods-*` components on top. That means USWDS
markup from the Strata templates, `react-uswds` and the Strata SDK renders
in Colorado style without forking any of them.

- **Package.** CoDS isn't on npm yet, so apps install the checksummed GitHub
  release archives (`@coloradodigitalservice/colorado-design-system` and
  `-tokens`), pinned in `stack/versions.env`. `@uswds/uswds` is pinned to the
  version CoDS is built on.
- **Rails.** `bin/cods-css` (from `stack/cods/cods-css.cjs`) runs first in
  `npm run build:css`. It copies the compiled CoDS stylesheet into
  `app/assets/builds` and rewrites its asset URLs so Sprockets fingerprints
  CoDS icons and fonts. Layouts load `colorado-design-system.css` before
  `application.css`. The app's Sass keeps `uswds-core` for its functions and
  mixins, but no longer compiles USWDS itself.
- **Next.js.** `layout.tsx` and Storybook's `preview.tsx` import
  `@coloradodigitalservice/colorado-design-system/styles.css`, and
  `styles.scss` no longer forwards `uswds`.
- **Flask.** API-only, so there's no UI to style. It's installed exactly as Nava
  ships it.
- **Compatibility layer.** `stack/cods/_cods-compat.scss` is copied into each
  UI app. It covers places where plain USWDS markup needs help under CoDS:
  outline buttons, and link colors, since CoDS doesn't enable USWDS's global
  link styles. Delete a rule once a CoDS release fixes it.
- **JavaScript.** Apps keep USWDS's `uswds.min.js` (same 3.14 release) for
  interactive components such as modal, date picker and combo box, which the
  Strata SDK uses. CoDS's own JS currently wraps only the accordion and can't
  run alongside the global USWDS bundle, so it isn't loaded yet.
- **New markup.** Write it CoDS-style: pair classes, for example
  `usa-button cods-button` or `usa-button usa-button--outline cods-button--secondary`
  (see the CoDS fixtures in `node_modules/@coloradodigitalservice/colorado-design-system/dist/fixtures/`).

## Upgrading

Everything that is pinned lives in [`stack/versions.env`](stack/versions.env).

- **CoDS:** run `bin/cods-upgrade 0.2.19`, then `bin/new-app --verify <app>`
  for each app, then commit.
- **App template:** bump `*_TEMPLATE_VERSION`, then run
  `nava-platform app update . <app>`, then
  `bin/new-app --reapply <app>` and `bin/new-app --verify <app>`.
- **Infra template:** `nava-platform infra update .`
- **Strata SDK:** bump `STRATA_SDK_REF`, then run
  `bin/new-app --reapply <rails-app>`. That updates the Gemfile and
  `Gemfile.lock`.

## CI/CD

All pipelines are GitHub Actions in `.github/workflows/`.

> **CI is paused.** The automatic triggers on the CI workflows (tests,
> lint, the generator checks, infra checks, container scans, docs links)
> and on the two daily AWS checks are commented out until the pipeline is
> fixed. Nothing runs on a pull request or a push except the Claude
> workflows. Each paused workflow can still be run by hand from the Actions
> tab. Until it is back, check changes locally with
> `bin/new-app --verify <app>` and `bin/demo test`.
>
> To switch everything back on:
>
> ```bash
> sed -i 's/^\( *\)#~/\1/' .github/workflows/*.yml
> ```

### What runs on every pull request (when CI is on)

| Workflow | Runs when | Checks |
| --- | --- | --- |
| `ci-stack.yml` (CI Stack) | `bin/new-app`, other repo scripts, or `stack/` change | Generates a Rails, a Next.js and a Flask app with `bin/new-app` against a Postgres service, runs each app's lint and tests, then confirms `--reapply` changes nothing |
| `ci-infra.yml` | `bin/`, `infra/` or workflows change | shellcheck, actionlint, terraform fmt/validate, checkov, tfsec |
| `ci-docs.yml` | always | Markdown link check |
| `claude-code-review.yml` (Claude Code Review) | every non-draft PR, on each push | Claude reviews the diff using the "Code review" rules in [`CLAUDE.md`](CLAUDE.md) and posts inline comments. It's advisory and never blocks a merge. |
| `claude.yml` | a comment mentioning `@claude` | Claude answers questions or pushes requested changes (only users with write access can trigger it) |

Each app created with `bin/new-app` adds its own workflows through the Nava
templates:
- `ci-<app>.yml`: lint and test on changes under `<app>/`.
- `ci-<app>-vulnerability-scans.yml`: container scanning.
- `ci-<app>-infra-service.yml`, `ci-<app>-pr-environment-*.yml` and `cd-<app>.yml`: these need AWS (see below).

### Turning on Claude Code Review (one-time, repo admin)

1. Install the Claude GitHub App on this repository:
   <https://github.com/apps/claude>.
2. Create a token with your Claude subscription. Reviews count against that
   plan's usage.

   ```bash
   claude setup-token
   ```

3. Save it as the repository secret `CLAUDE_CODE_OAUTH_TOKEN`
   (**Settings → Secrets and variables → Actions → New repository secret**).

Until the secret exists, both Claude workflows skip with a notice instead of
failing. Fork PRs never get secrets, so they are skipped too. To change what
the reviewer looks for, edit the "Code review" section of `CLAUDE.md`.

### Turning on CD (once AWS is ready)

The deploy workflows are installed but dormant: each `cd-<app>.yml` only runs
manually until its app has a `dev` environment. To switch them on:

1. Follow [`infra/README.md`](infra/README.md) → "Getting started":
   - set up the AWS account (this creates the Terraform backend and the GitHub
     Actions OIDC role named in `infra/project-config/main.tf`);
   - set up the network;
   - set up the app build repository;
   - set up the database;
   - set up the `dev` application environment.

   The region (`us-east-1`) and role come from `infra/project-config/main.tf`,
   so workflows need no edits.
2. Check that GitHub can reach AWS. Run the **Check CI/CD AWS authentication**
   workflow from the Actions tab, or:

   ```bash
   make infra-check-github-actions-auth
   ```

3. Enable push-to-main deploys, PR environments and the infra service checks
   for each app. Then review the diff and commit.

   ```bash
   nava-platform infra update-app --answers-only --data app_has_dev_env_setup=true . <app>
   ```

After that, merging to `main` builds, scans and deploys the app to `dev`.
Staging and production are deployed from the same `cd-<app>.yml` with
`workflow_dispatch`. See [`docs/releases.md`](docs/releases.md).

For Rails apps, `bin/new-app` has already applied the environment-independent
settings from the Rails template's deployment guide: NAT gateway, Cognito,
`/rails/tmp` volume, `SECRET_KEY_BASE`, and RDS IAM auth. Set the domain and
HTTPS per environment in `infra/<app>/app-config/<env>.tf`.

### Recommended branch protection for `main`

Under **Settings → Branches → Add rule**:
- Require a pull request before merging.
- Require status checks to pass: the `CI Stack`, `CI Infra Checks` and docs
  checks, plus each app's `CI <app>` once it exists.

Don't make `Claude Code Review` a required check. It reviews but never blocks.

## Repo layout

```text
bin/                  repo tooling (new-app, setup-env, doctor, cods-upgrade, demo, serve) + infra scripts
docker-compose.yml    the tax prototype as a hosted demo on any machine with Docker
render.yaml .replit   the same for Render and Replit (see docs/hosting.md)
stack/versions.env    every pinned version
stack/cods/           files bin/new-app copies into apps (CoDS CSS build step, compat styles)
stack/lib/            helpers used by bin/*
infra/ .github/ docs/ from the Strata AWS infra template
<app>/                one directory per app (created by bin/new-app)
```
