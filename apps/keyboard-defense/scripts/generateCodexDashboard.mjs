#!/usr/bin/env node
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..", "..");
const codexDir = path.join(repoRoot, "docs", "codex_pack");
const docsDir = path.join(repoRoot, "docs");
const backlogPath = path.join(
  repoRoot,
  "apps",
  "keyboard-defense",
  "docs",
  "season1_backlog.md"
);

const priorityOrder = { P1: 1, P2: 2, P3: 3 };

const readYaml = async (filePath) => parseYaml(await fs.readFile(filePath, "utf8"));

const readManifest = async () => {
  const manifest = await readYaml(path.join(codexDir, "manifest.yml"));
  const status = await readYaml(path.join(codexDir, "task_status.yml"));
  const tasks = manifest.tasks ?? [];
  return tasks.map((task) => {
    const tracker = status?.tasks?.[task.id] ?? {};
    return {
      id: task.id,
      title: task.title,
      priority: task.priority ?? "P?",
      status: tracker.state ?? task.status ?? "todo",
      owner: tracker.owner ?? "unassigned",
      status_note: task.status_note,
      backlog_refs: task.backlog_refs ?? [],
      depends_on: task.depends_on ?? []
    };
  });
};

const extractBacklogRefs = async () => {
  const content = await fs.readFile(backlogPath, "utf8");
  const lines = content.split(/\r?\n/);
  const references = {};
  for (const line of lines) {
    const match = line.match(/^(\d+)\.\s+.*?\(Codex:\s+`([A-Za-z0-9\-]+)`/);
    if (match) {
      const backlogId = `#${match[1]}`;
      const taskId = match[2];
      references[taskId] = backlogId;
    }
  }
  return references;
};

const dashboardPath = path.join(docsDir, "codex_dashboard.md");

const main = async () => {
  const tasks = await readManifest();
  const backlogMap = await extractBacklogRefs();
  const sorted = tasks.sort((a, b) => {
    const pa = priorityOrder[a.priority] ?? 99;
    const pb = priorityOrder[b.priority] ?? 99;
    if (pa !== pb) return pa - pb;
    if (a.status !== b.status) {
      const order = { "in-progress": 0, todo: 1, done: 2 };
      return (order[a.status] ?? 3) - (order[b.status] ?? 3);
    }
    return a.id.localeCompare(b.id);
  });

  const lines = [];
  lines.push("# Codex Dashboard");
  lines.push("");
  lines.push("| Task | Priority | State | Owner | Status Note | Backlog |");
  lines.push("| --- | --- | --- | --- | --- | --- |");
  for (const task of sorted) {
    const backlogRefs = task.backlog_refs.length
      ? task.backlog_refs.join(", ")
      : backlogMap[task.id] ?? "";
    lines.push(
      `| \`${task.id}\` | ${task.priority} | ${task.status} | ${task.owner} | ${task.status_note} | ${backlogRefs} |`
    );
  }
  lines.push("");
  lines.push("Generated automatically via `npm run codex:dashboard`.");
  await fs.writeFile(dashboardPath, lines.join("\n"), "utf8");
  console.log(`Codex dashboard updated: ${path.relative(repoRoot, dashboardPath)}`);
};

main().catch((error) => {
  console.error("Failed to generate Codex dashboard:", error);
  process.exit(1);
});
