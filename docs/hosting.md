# Hosting the tax prototype outside AWS

The repository's main deployment path is AWS, through the Nava infra
template (see the root README). This page is for showing the prototype
somewhere else: a laptop, a VM, or a hosting service.

Everything here is a **demo deployment**. It runs the portal in the Rails
template's `mock-production` environment with one-click demo sign-in, so
anyone who can reach the address can sign in as a demo taxpayer or examiner.
Never put real taxpayer data in it.

## What any host has to provide

| Need | Why |
| --- | --- |
| Two long-running processes | The portal (Rails) and the tax engine (Python) |
| About 4 GB of memory | The tax rules take about 3 GB once loaded; the portal needs a few hundred MB more |
| A Postgres database | One database is enough; the two apps' tables don't clash |
| One public port | Only the portal is public. The engine should stay private |
| A few secrets | Listed under [Settings](#settings) |

## Which hosts fit

| Host | Fits? | How | Tested |
| --- | --- | --- | --- |
| Any Linux machine with the tools | Yes | `bin/serve` | Yes, on a development machine |
| Any machine with Docker | Yes | `docker compose up --build` | No |
| Render | Yes | `render.yaml` blueprint | No |
| Fly.io, Railway, Google Cloud Run, Azure Container Apps | Yes | Build the two Dockerfiles; use the settings below | No |
| Replit | Probably | `.replit` runs `bin/serve`; needs a Reserved VM with 4 GB or more | No |
| Vercel, Netlify | **No** | See below | Not applicable |

"Tested: No" means the configuration was written from each host's
documented format and checked for syntax, but has not been run there. Expect
to adjust it the first time.

### Why not Vercel or Netlify

They run short-lived functions and static sites. This prototype is two
servers that stay running, one of which holds about 3 GB of tax rules in
memory and takes about a minute to start. Neither host can run that, and neither
runs Rails. A Next.js front end from this repository's Next.js template
could go on Vercel, but it would still need the engine and a database
somewhere else.

## Option 1: one command on a Linux machine (`bin/serve`)

For a VM, Replit, or your own container. It needs the toolchain and a
Postgres it can reach.

```bash
bin/setup-env --postgres
```

```bash
bin/serve
```

Then open port 3100. `bin/serve` builds the portal's assets, prepares the
database and starts both apps. Nothing else has to be loaded: each visitor
gets their own copy of the demo people the first time they choose one, and
a copy is erased after two hours without use. `bin/serve --reset` discards
every copy when starting.

- `PORT` sets the portal's port. Most hosts set it for you.
- `DATABASE_URL` points both apps at a hosted Postgres. Without it,
  `bin/serve` uses the local Postgres from `bin/setup-env --postgres`.
- Secrets that are not set are generated once into `tmp/serve.env`. That
  suits a machine whose disk persists. Elsewhere, set them in the host's
  secret store (see [Settings](#settings)).

It differs from `bin/demo`, which runs the apps in development mode for
working on the code.

## Option 2: Docker Compose

```bash
bin/hosting-secrets > .env
```

```bash
docker compose up --build
```

Then open <http://localhost:3100>. This starts Postgres, the engine and the
portal from `docker-compose.yml`. The first build takes several minutes.
`.env` is ignored by git; keep it, because the encryption keys in it are
needed to read what the portal has stored.

## Option 3: Render

`render.yaml` describes a database, the engine as a private service and the
portal as a web service. In Render, create a new Blueprint from this
repository. Render generates the secrets and connects the services.

The engine needs a plan with at least 4 GB of memory; the blueprint asks for
`pro`. Check the plan names and prices before applying.

## Option 4: Replit

Not yet tested on Replit. The same launcher has been run end to end on a
Linux development machine: the home page answered 7 seconds after start, the
tax engine was ready after about 75 seconds, and both apps together used
about 2.8 GB of memory.

### Set it up in the workspace

1. In Replit, create an app by importing this repository from GitHub. If
   Replit's Agent offers to set the project up or rewrite it, decline: the
   repository already has `.replit` and `replit.nix`.
2. Wait for Replit to install the tools listed in `replit.nix`.
3. Add a PostgreSQL database to the app (the Database tool). That sets
   `DATABASE_URL`, which `bin/serve` reads.
4. Make sure the workspace has at least 4 GB of memory.
5. Press **Run**. The first run installs dependencies and builds the
   portal, which takes several minutes. The portal then opens on port 3100;
   visitors can choose a demo person about a minute later, once the tax
   engine has loaded.

### Publish it

1. Generate the secrets once, in the Replit shell, and add each line to the
   app's **Secrets**. Leave out `DB_PASSWORD`; Replit's database has its own.

   ```bash
   bin/hosting-secrets
   ```

   Without this, a published app makes new secrets every time it is
   republished, and the stored demo people can no longer be read.
2. Choose **Publish**, then **Reserved VM**. Autoscale won't work: the tax
   engine has to stay loaded in memory.
3. Pick a machine with at least 4 GB of memory. 8 GB leaves headroom.
4. Build command: `bin/serve --build`. Run command: `bin/serve`. (`.replit`
   already says so; check that the publish screen shows the same.)
5. Make sure the published app has the database and the secrets attached.

Every visitor has their own copy of the demo, so there is nothing to reset
between showings. A visitor can choose **Start the demo over** on the home
page to put their own copy back to the start. From a shell,
`bin/serve --reset` discards everyone's copies when starting.

### If something fails

These are the likeliest first-run problems, since this has not been run on
Replit:

| What you see | Likely cause | What to try |
| --- | --- | --- |
| Replit can't build the environment | A package name or the Nix channel in `replit.nix` or `.replit` isn't available | Change `channel` in `.replit` to the newest stable one Replit offers |
| "Ruby X is installed, but the portal needs Ruby 3.4.x" | The Nix channel is too old to have Ruby 3.4 | Use a newer channel |
| A gem or Python package fails to install | A system library is missing | Add it to `replit.nix` |
| "an open port was not detected" when publishing | The run command isn't `bin/serve`, or the build step was skipped and the first start is slow | Set the build command to `bin/serve --build` |
| The app stops or restarts after a minute | Out of memory while the tax engine loads | Use a larger machine |
| The home page says "The demo is getting ready" and has no buttons | The tax engine hasn't finished loading, or failed | Wait a minute; then look at `tmp/serve/engine.log` |

Logs are in `tmp/serve/`. Send the last lines of the one that failed and it
can usually be fixed quickly.

## Other container hosts

Build `tax-engine/Dockerfile` and `tax-portal/Dockerfile` (the final stage
of each is the release image) and give them the settings below. Start
commands, as in `docker-compose.yml`:

- Engine: `poetry run db-migrate && poetry run gunicorn 'src.app:create_app()'`
- Portal: `./bin/rails db:prepare && ./bin/rails server -b 0.0.0.0`

## Keys and secrets: what you need to get

Nothing from anyone else. A demo deployment needs no account, licence or
API key from a third party.

- **PolicyEngine needs no API key.** The tax engine uses PolicyEngine US as
  an open-source Python library that runs inside this repository's
  `tax-engine` app. It never calls PolicyEngine's hosted service.
- **No AWS, Cognito or other cloud credentials.** Demo sign-in replaces the
  identity provider, and the prototype stores no files.
- **Five secrets, all made up on the spot.** Each is a random string that
  only has to stay the same between restarts:

| Secret | What it is for |
| --- | --- |
| `SECRET_KEY_BASE` | Signs the portal's session cookies |
| `AR_ENCRYPTION_PRIMARY_KEY`, `AR_ENCRYPTION_DETERMINISTIC_KEY`, `AR_ENCRYPTION_KEY_DERIVATION_SALT` | Encrypt the SSNs and bank account numbers of the demo people in the database |
| `TAX_ENGINE_API_TOKEN` | A password between the portal and this repository's own tax engine, so nothing else can call the engine |

  Docker Compose also needs a `DB_PASSWORD` for the Postgres it starts.

Where they come from:

| How you run it | What you do |
| --- | --- |
| `bin/serve` | Nothing. Missing secrets are generated on first run and kept in `tmp/serve.env` |
| Docker Compose | `bin/hosting-secrets > .env`, once |
| Render | Nothing. The blueprint asks Render to generate them |
| Another host | Run `bin/hosting-secrets` and paste the values into the host's secret store |

If the encryption keys change, the demo people's stored SSNs can no longer
be read. For a demo the fix is to discard them: `bin/serve --reset`.

## Settings

Tax engine:

| Setting | Value |
| --- | --- |
| `API_AUTH_TOKEN` | Secret. Callers send it in the `X-Auth` header |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSL_MODE` | The Postgres database |
| `PORT` | Port to listen on (default 3200) |
| `TAX_ENGINE_PRELOAD` | `true`, so the rules load at startup |
| `ENVIRONMENT` | Any name, for example `demo` |

Portal:

| Setting | Value |
| --- | --- |
| `RAILS_ENV` | `mock-production` |
| `AUTH_ADAPTER` | `mock` |
| `DEMO_MODE` | `true` |
| `SECRET_KEY_BASE` | Secret |
| `AR_ENCRYPTION_PRIMARY_KEY`, `AR_ENCRYPTION_DETERMINISTIC_KEY`, `AR_ENCRYPTION_KEY_DERIVATION_SALT` | Secrets. Keep them: they are needed to read stored SSNs and bank account numbers |
| `TAX_ENGINE_URL` | Address of the engine, for example `http://tax-engine:3200` |
| `TAX_ENGINE_API_TOKEN` | The engine's `API_AUTH_TOKEN` |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | The Postgres database |
| `PORT` | Port to listen on |
| `DISABLE_DATABASE_ENVIRONMENT_CHECK` | `1` |
| `BUCKET_NAME`, `AWS_DEFAULT_REGION` | Any value, for example `not-used` and `us-east-1`. The prototype stores no files, but the settings have to exist |

`bin/hosting-secrets` prints a fresh set of the secrets.

## What a demo deployment is not

- It is not the production setup. Production uses `RAILS_ENV=production`,
  real sign-in through Cognito and no demo people; that path is the AWS one.
- Background jobs run inside the portal process. On AWS a scheduled task
  picks up anything they miss; here, run `bin/rails tax:process_pending`
  yourself if a filed return stays at "Received".
- One engine process handles about one new calculation a second. That is
  plenty for a demonstration and nothing like enough for a filing season.
