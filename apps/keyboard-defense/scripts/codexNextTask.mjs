#!/usr/bin/env node
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..", "..");
const codexDir = path.join(repoRoot, "docs", "codex_pack");

const priorityOrder = { P1: 1, P2: 2, P3: 3 };

const readYaml = async (filePath) => parseYaml(await fs.readFile(filePath, "utf8"));

const main = async () => {
  const manifest = await readYaml(path.join(codexDir, "manifest.yml"));
  const status = await readYaml(path.join(codexDir, "task_status.yml"));
  if (!Array.isArray(manifest?.tasks)) {
    console.error("manifest.yml missing tasks array");
    process.exit(1);
  }

  const todo = manifest.tasks
    .filter((task) => {
      const tracker = status?.tasks?.[task.id];
      const state = task.status ?? tracker?.state ?? "todo";
      return state === "todo";
    })
    .sort((a, b) => {
      const pa = priorityOrder[a.priority] ?? 99;
      const pb = priorityOrder[b.priority] ?? 99;
      if (pa !== pb) return pa - pb;
      const da = Array.isArray(a.depends_on) ? a.depends_on.length : 0;
      const db = Array.isArray(b.depends_on) ? b.depends_on.length : 0;
      if (da !== db) return da - db;
      return a.id.localeCompare(b.id);
    });

  if (todo.length === 0) {
    console.log("No TODO Codex tasks remaining.");
    return;
  }

  const next = todo[0];
  const tracker = status?.tasks?.[next.id];
  console.log("Next Codex task:");
  console.log(`  id: ${next.id}`);
  console.log(`  title: ${next.title}`);
  console.log(`  priority: ${next.priority}`);
  console.log(`  status note: ${next.status_note}`);
  console.log(`  backlog refs: ${(next.backlog_refs ?? []).join(", ")}`);
  console.log(`  depends_on: ${(next.depends_on ?? []).join(", ") || "none"}`);
  console.log(`  current owner: ${tracker?.owner ?? "unassigned"}`);
  console.log("");
  console.log("Instructions:");
  console.log(" 1. Update docs/codex_pack/task_status.yml → set state=in-progress and owner=<you>.");
  console.log(` 2. Follow docs/codex_pack/tasks/${next.path ?? `${next.id}.md`} for context, steps, and verification.`);
  console.log(" 3. Run the checklist from docs/CODEX_GUIDE.md.");
};

main().catch((error) => {
  console.error("Failed to compute next Codex task:", error);
  process.exit(1);
});
