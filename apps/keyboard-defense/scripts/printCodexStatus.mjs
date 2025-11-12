#!/usr/bin/env node
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..", "..");
const codexDir = path.join(repoRoot, "docs", "codex_pack");

const readYaml = async (filePath) => {
  const content = await fs.readFile(filePath, "utf8");
  return parseYaml(content);
};

const main = async () => {
  const manifest = await readYaml(path.join(codexDir, "manifest.yml"));
  const status = await readYaml(path.join(codexDir, "task_status.yml"));
  if (!Array.isArray(manifest?.tasks)) {
    console.error("manifest.yml missing tasks array");
    process.exit(1);
  }
  const rows = manifest.tasks.map((entry) => {
    const id = entry.id;
    const priority = entry.priority ?? "P?";
    const taskStatus = entry.status ?? "unknown";
    const owner =
      status?.tasks?.[id]?.owner ?? (taskStatus === "in-progress" ? "unassigned" : "");
    const state = status?.tasks?.[id]?.state ?? taskStatus;
    return { id, priority, state, owner };
  });
  console.log("| Task | Priority | State | Owner |");
  console.log("| --- | --- | --- | --- |");
  for (const row of rows) {
    console.log(
      `| ${row.id} | ${row.priority} | ${row.state ?? "unknown"} | ${row.owner ?? ""} |`
    );
  }
};

main().catch((error) => {
  console.error("Failed to print Codex status:", error);
  process.exit(1);
});
