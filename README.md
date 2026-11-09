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

No apps exist yet. They get created from requirements with one command each.

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

## Deploying

Follow `infra/README.md` ("First time initialization") to set up AWS
accounts and environments. For Rails apps, `bin/new-app` has already applied the
environment-independent settings from the Rails template's deployment guide:
NAT gateway, Cognito, `/rails/tmp` volume, `SECRET_KEY_BASE`, and RDS IAM auth.
Set the domain and HTTPS per environment in `infra/<app>/app-config/<env>.tf`.

## Repo layout

```text
bin/                  repo tooling (new-app, setup-env, doctor, cods-upgrade) + infra scripts
stack/versions.env    every pinned version
stack/cods/           files bin/new-app copies into apps (CoDS CSS build step, compat styles)
stack/lib/            helpers used by bin/*
infra/ .github/ docs/ from the Strata AWS infra template
<app>/                one directory per app (created by bin/new-app)
```
