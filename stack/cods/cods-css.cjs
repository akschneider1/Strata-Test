#!/usr/bin/env node
// Copies the Colorado Design System stylesheet into app/assets/builds,
// rewriting its relative asset URLs (./icons, ./img, ./fonts) to package
// paths so Sprockets can resolve and fingerprint them from node_modules.
//
// Managed by the repo's bin/new-app (source: stack/cods/cods-css.cjs).
// Runs as the first step of `npm run build:css`.
//
// CommonJS on purpose: installed as the extensionless bin/cods-css, and the
// template Dockerfile builds assets with Debian's (older) Node package.
"use strict";
const fs = require("fs");
const path = require("path");

const pkg = "@coloradodigitalservice/colorado-design-system/dist";
const root = path.resolve(__dirname, "..");
const src = path.join(root, "node_modules", pkg, "colorado-design-system.css");
const out = path.join(root, "app/assets/builds/colorado-design-system.css");

if (!fs.existsSync(src)) {
  console.error(`cods-css: ${path.relative(root, src)} not found; run npm install`);
  process.exit(1);
}

const css = fs
  .readFileSync(src, "utf8")
  .replace(/url\((["']?)\.\/([^"')]+)\1\)/g, (_m, q, p) => `url(${q}${pkg}/${p}${q})`);

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, css);
console.log(`cods-css: wrote ${path.relative(root, out)}`);
