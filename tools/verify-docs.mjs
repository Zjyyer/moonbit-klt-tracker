#!/usr/bin/env node
/** Verify repository documentation claims against checked-in project evidence. */

import { existsSync, readFileSync, statSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(fileURLToPath(new URL("..", import.meta.url)));
const readmes = ["README.md", "README.zh-CN.md"];
const requiredDocuments = [
  "docs/architecture.md",
  "docs/algorithm.md",
  "docs/references.md",
  "docs/provenance.md",
  "docs/development-journal.md",
  "docs/osc2026-self-audit.md",
  "CHANGELOG.md",
  "CONTRIBUTING.md",
];
const requiredAuditEvidence = [
  "License: Apache-2.0",
  "Default branch: main",
  "Source scale command: moon info",
  "History count command: git rev-list --count HEAD",
  "CI workflow: .github/workflows/check.yml",
  "Generated-interface gate: git diff --exit-code",
];

function fail(message) {
  console.error(`documentation verification failed: ${message}`);
  process.exit(1);
}

function checkedInFile(target) {
  if (/^(https?:|#|mailto:)/.test(target)) return true;
  const path = resolve(root, target.split("#", 1)[0]);
  return existsSync(path) && statSync(path).isFile();
}

for (const document of requiredDocuments) {
  if (!checkedInFile(document)) fail(`required document is missing: ${document}`);
}

const commandSource = readFileSync(resolve(root, "src/cli/main.mbt"), "utf8");
const acceptedCommands = new Set(
  [...commandSource.matchAll(/command != "([a-z]+)"/g)].map((match) => match[1]),
);
if (acceptedCommands.size === 0) {
  fail("could not discover accepted CLI commands from src/cli/main.mbt");
}

for (const readme of readmes) {
  const contents = readFileSync(resolve(root, readme), "utf8");
  for (const match of contents.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)) {
    if (!checkedInFile(match[1])) {
      fail(`${readme} links to a missing checked-in file: ${match[1]}`);
    }
  }
  const documentedCommands = new Set(
    [...contents.matchAll(/moon run src\/cli(?: --)? ([a-z]+)/g)].map((match) => match[1]),
  );
  if (
    documentedCommands.size !== acceptedCommands.size ||
    [...acceptedCommands].some((command) => !documentedCommands.has(command))
  ) {
    fail(
      `${readme} documents CLI commands ${JSON.stringify([...documentedCommands].sort())}, ` +
        `but the CLI accepts ${JSON.stringify([...acceptedCommands].sort())}`,
    );
  }
}

const audit = readFileSync(resolve(root, "docs/osc2026-self-audit.md"), "utf8");
for (const evidence of requiredAuditEvidence) {
  if (!audit.includes(evidence)) {
    fail(`OSC audit does not include required evidence: ${evidence}`);
  }
}

console.log("documentation verification passed");
