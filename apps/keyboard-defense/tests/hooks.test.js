import assert from "node:assert/strict";
import { test } from "vitest";

import {
  DEFAULT_COMMANDS,
  runChecks,
  runCommandSequence
} from "../scripts/hooks/runChecks.mjs";

test("runChecks skips when SKIP_HOOKS=1 is set", async () => {
  const result = await runChecks({
    env: { SKIP_HOOKS: "1" },
    runner: async () => 0
  });
  assert.equal(result.skipped, true);
  assert.deepEqual(result.results, []);
});

test("runChecks runs commands sequentially", async () => {
  const executed = [];
  const result = await runChecks({
    commands: ["lint", "test"],
    runner: async (descriptor) => {
      executed.push(descriptor.id);
      return 0;
    },
    env: {}
  });
  assert.equal(result.skipped, false);
  assert.deepEqual(executed, ["lint", "test"]);
  assert.equal(result.results.length, 2);
});

test("runCommandSequence surfaces failures and stops", async () => {
  const commands = DEFAULT_COMMANDS.slice(0, 3).map((id) => ({ id }));
  const attempted = [];
  await assert.rejects(
    () =>
      runCommandSequence(commands, {
        runner: async (descriptor) => {
          attempted.push(descriptor.id);
          return descriptor.id === commands[1].id ? 1 : 0;
        }
      }),
    /failed/
  );
  assert.deepEqual(attempted, [commands[0].id, commands[1].id]);
});

test("runCommandSequence dry-run logs without executing", async () => {
  const commands = [{ id: "lint", cmd: "npm", args: [] }];
  const result = await runCommandSequence(commands, { dryRun: true });
  assert.deepEqual(result, [{ id: "lint", status: "dry-run" }]);
});
