#!/usr/bin/env node
// Knockoff — detector test runner. No dependencies:
//   node tests/run.js
// Loads the data files and detector into a sandbox (they're plain classic
// scripts, not modules) and checks every fixture title's verdict.

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const root = path.join(__dirname, "..");
const ctx = vm.createContext({});
[
  "data/abf-brands.js",
  "data/known-brands.js",
  "data/chinese-major.js",
  "data/flagged-brands.js",
  "data/generic-words.js",
  "src/detector.js"
].forEach((f) => {
  vm.runInContext(fs.readFileSync(path.join(root, f), "utf8"), ctx, { filename: f });
});

const Knockoff = ctx.Knockoff;
Knockoff.buildIndexes();

const fixtures = require("./fixtures.js");
const settings = { level: "standard", flagChineseMajor: false };
const none = new Set();

let pass = 0;
let fail = 0;
for (const [title, expected] of fixtures) {
  const r = Knockoff.classify(title, settings, none, none);
  if (r.verdict === expected) {
    pass++;
  } else {
    fail++;
    console.log(`✗ ${JSON.stringify(title)}`);
    console.log(`    expected ${expected}, got ${r.verdict}` +
      (r.brand ? ` (brand "${r.brand}", ${r.reason})` : ` (${r.reason})`));
  }
}

console.log(`\n${pass}/${pass + fail} fixtures pass`);
process.exit(fail ? 1 : 0);
