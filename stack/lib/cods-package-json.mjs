#!/usr/bin/env node
// Idempotently points an app's package.json at a Colorado Design System
// release and keeps USWDS / Sass aligned with it.
//
// Usage: node stack/lib/cods-package-json.mjs <package.json> \
//          --cods <version> --uswds <version> --sass <range> [--rails] [--bootstrap-override]
//
//   --rails               also prefixes the "build:css" script with `node ./bin/cods-css`
//   --bootstrap-override  temporarily add the npm override needed to create the lockfile
import fs from "node:fs";
import { parseArgs } from "node:util";

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    cods: { type: "string" },
    uswds: { type: "string" },
    sass: { type: "string" },
    rails: { type: "boolean", default: false },
    "bootstrap-override": { type: "boolean", default: false },
  },
});
const [file] = positionals;
if (!file || !values.cods || !values.uswds || !values.sass) {
  console.error(
    "usage: cods-package-json.mjs <package.json> --cods V --uswds V --sass RANGE [--rails]",
  );
  process.exit(2);
}

const SYS = "@coloradodigitalservice/colorado-design-system";
const TOK = "@coloradodigitalservice/colorado-design-tokens";
const base = `https://github.com/coloradodigitalservice/colorado-design-system/releases/download/v${values.cods}`;

const pkg = JSON.parse(fs.readFileSync(file, "utf8"));
pkg.dependencies ??= {};
pkg.devDependencies ??= {};

// CoDS is not on npm yet: install the checksummed GitHub release archives.
pkg.dependencies[SYS] = `${base}/coloradodigitalservice-colorado-design-system-${values.cods}.tgz`;
pkg.dependencies[TOK] = `${base}/coloradodigitalservice-colorado-design-tokens-${values.cods}.tgz`;
// The system package depends on tokens@<exact version>, which is not on npm.
// An npm "override" pointing it at the release archive is needed once, to
// create the lockfile (--bootstrap-override). It must not stay in
// package.json: the npm 9 that ships in the Rails template's container
// image rejects URL overrides ("Invalid comparator"). Once the lockfile pins
// the archive, every npm version installs from it without the override.
const overrides = { ...(pkg.overrides ?? {}) };
if (values["bootstrap-override"]) overrides[TOK] = "$" + TOK;
else delete overrides[TOK];
if (Object.keys(overrides).length > 0) pkg.overrides = overrides;
else delete pkg.overrides;

// USWDS JS/images come from the same USWDS release CoDS is built on.
pkg.dependencies["@uswds/uswds"] = values.uswds;
pkg.devDependencies.sass = values.sass;

if (values.rails) {
  const s = pkg.scripts?.["build:css"];
  if (!s) {
    console.error(`${file}: no "build:css" script to patch`);
    process.exit(1);
  }
  if (!s.includes("bin/cods-css")) pkg.scripts["build:css"] = `node ./bin/cods-css && ${s}`;
}

const sortKeys = (o) =>
  Object.fromEntries(Object.entries(o).sort(([a], [b]) => a.localeCompare(b)));
pkg.dependencies = sortKeys(pkg.dependencies);
pkg.devDependencies = sortKeys(pkg.devDependencies);

fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + "\n");
console.log(
  `cods-package-json: ${file} -> CoDS ${values.cods}, USWDS ${values.uswds}, sass ${values.sass}`,
);
