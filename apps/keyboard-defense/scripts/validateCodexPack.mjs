#!/usr/bin/env node
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..", "..");
const codexDir = path.join(repoRoot, "docs", "codex_pack");
const manifestPath = path.join(codexDir, "manifest.yml");
const statusPath = path.join(codexDir, "task_status.yml");
const tasksDir = path.join(codexDir, "tasks");

const errors = [];

const readYaml = async (filePath) => {
  const content = await fs.readFile(filePath, "utf8");
  return parseYaml(content);
};

const parseFrontMatter = (content, taskPath) => {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    throw new Error(`Missing front matter in ${taskPath}`);
  }
  return parseYaml(match[1]);
};

const fileExists = async (filePath) => {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
};

const validate = async () => {
  const manifest = await readYaml(manifestPath);
  const status = await readYaml(statusPath);
  if (!Array.isArray(manifest?.tasks)) {
    errors.push("manifest.yml must define a top-level tasks array");
    return;
  }

  const manifestIds = new Set();
  for (const entry of manifest.tasks) {
    if (!entry?.id) {
      errors.push("Each manifest entry must include an id");
      continue;
    }
    if (manifestIds.has(entry.id)) {
      errors.push(`Duplicate task id '${entry.id}' in manifest.yml`);
    }
    manifestIds.add(entry.id);
    const expectedPath = entry.path
      ? path.join(codexDir, entry.path)
      : path.join(tasksDir, `${entry.id}.md`);
    if (!(await fileExists(expectedPath))) {
      errors.push(
        `Task '${entry.id}' points to missing file (${entry.path ?? "default path"})`
      );
      continue;
    }
    const content = await fs.readFile(expectedPath, "utf8");
    let frontMatter;
    try {
      frontMatter = parseFrontMatter(content, expectedPath);
    } catch (error) {
      errors.push(error.message);
      continue;
    }
    if (!frontMatter.status_note) {
      errors.push(`Task '${entry.id}' is missing status_note in front matter`);
    } else {
      const notePath = path.join(repoRoot, frontMatter.status_note);
      if (!(await fileExists(notePath))) {
        errors.push(
          `Task '${entry.id}' references missing status note '${frontMatter.status_note}'`
        );
      }
    }
    if (!Array.isArray(frontMatter.backlog_refs) || frontMatter.backlog_refs.length === 0) {
      errors.push(`Task '${entry.id}' requires at least one backlog reference`);
    }
    if (Array.isArray(frontMatter.depends_on)) {
      for (const dep of frontMatter.depends_on) {
        if (!manifestIds.has(dep)) {
          errors.push(`Task '${entry.id}' depends on unknown task '${dep}'`);
        }
      }
    }
  }

  if (!status?.tasks || typeof status.tasks !== "object") {
    errors.push("task_status.yml must define a 'tasks' map");
  } else {
    const ownerInProgress = new Map();
    for (const [taskId, info] of Object.entries(status.tasks)) {
      if (!manifestIds.has(taskId)) {
        errors.push(`task_status.yml references unknown task '${taskId}'`);
        continue;
      }
      if (!["todo", "in-progress", "done"].includes(info.state)) {
        errors.push(`Task '${taskId}' has invalid state '${info.state}'`);
      }
      const owner = info.owner ?? "unassigned";
      if (info.state === "in-progress" && owner !== "unassigned") {
        const list = ownerInProgress.get(owner) ?? [];
        list.push(taskId);
        ownerInProgress.set(owner, list);
      }
    }
    for (const [owner, list] of ownerInProgress.entries()) {
      if (list.length > 1) {
        errors.push(
          `Owner '${owner}' has multiple in-progress tasks: ${list.join(", ")}`
        );
      }
    }
    for (const id of manifestIds) {
      if (!status.tasks[id]) {
        errors.push(`task_status.yml missing entry for '${id}'`);
      }
    }
  }
};

const main = async () => {
  await validate().catch((error) => {
    errors.push(error.message);
  });
  if (errors.length > 0) {
    console.error("Codex Pack validation failed:");
    for (const message of errors) {
      console.error(` • ${message}`);
    }
    process.exit(1);
  } else {
    console.log("Codex Pack validation passed.");
  }
};

main();
