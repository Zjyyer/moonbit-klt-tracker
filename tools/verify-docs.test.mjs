import assert from "node:assert/strict";
import test from "node:test";
import { resolve } from "node:path";

import { checkedInFile } from "./verify-docs.mjs";

const root = resolve(import.meta.dirname, "..");

test("documentation links cannot escape the repository", () => {
  assert.equal(checkedInFile(root, "../../task_plan.md"), false);
});

test("documentation links can target checked-in files", () => {
  assert.equal(checkedInFile(root, "docs/architecture.md#packages"), true);
});
