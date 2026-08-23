#!/usr/bin/env node
/** Verify repository documentation claims against checked-in project evidence. */

import { existsSync, readFileSync, statSync } from "node:fs";
import { isAbsolute, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const defaultRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
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
  "Remote default branch:",
  "Source scale command: `scripts/line-count.ps1`",
  "History count command: git rev-list --count HEAD",
  ".github/workflows/check.yml",
  "Generated-interface gate: git diff --exit-code",
];

function fail(message) {
  console.error(`documentation verification failed: ${message}`);
  process.exit(1);
}

function isInsideRoot(root, path) {
  const fromRoot = relative(root, path);
  return (
    fromRoot === "" ||
    (!fromRoot.startsWith(`..${sep}`) && fromRoot !== ".." && !isAbsolute(fromRoot))
  );
}

export function checkedInFile(root, target) {
  if (/^(https?:|#|mailto:)/i.test(target)) return true;
  const path = resolve(root, target.split(/[?#]/, 1)[0]);
  if (!isInsideRoot(root, path)) return false;
  return existsSync(path) && statSync(path).isFile();
}

export function verifyDocs(root = defaultRoot) {
  for (const document of requiredDocuments) {
    if (!checkedInFile(root, document)) fail(`required document is missing: ${document}`);
  }

  const commandSourcePath = "src/cli_core/command.mbt";
  const commandSource = readFileSync(resolve(root, commandSourcePath), "utf8");
  const acceptedCommands = new Set(
    [...commandSource.matchAll(/command != "([a-z]+)"/g)].map((match) => match[1]),
  );
  if (acceptedCommands.size === 0) {
    fail(`could not discover accepted CLI commands from ${commandSourcePath}`);
  }

  for (const readme of readmes) {
    const contents = readFileSync(resolve(root, readme), "utf8");
    for (const match of contents.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)) {
      if (!checkedInFile(root, match[1])) {
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
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  verifyDocs();
}
