#!/usr/bin/env node
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..", "..", "..");
const statusDir = path.join(repoRoot, "docs", "status");
const codexDir = path.join(repoRoot, "docs", "codex_pack");
const manifestPath = path.join(codexDir, "manifest.yml");

const readYaml = async (filePath) => parseYaml(await fs.readFile(filePath, "utf8"));

const listStatusNotes = async () => {
  const entries = await fs.readdir(statusDir, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(".md"))
    .map((entry) => ({
      name: entry.name,
      path: path.join(statusDir, entry.name),
      relPath: path.join("docs", "status", entry.name)
    }));
};

const loadTaskMetadata = async () => {
  const manifest = await readYaml(manifestPath);
  const statusToId = new Map();
  const pathToId = new Map();
  for (const task of manifest.tasks ?? []) {
    statusToId.set(task.status_note.replace(/\\/g, "/"), task.id);
    const taskPath = task.path ?? `tasks/${task.id}.md`;
    const normalized = path
      .join("docs", "codex_pack", taskPath)
      .replace(/\\/g, "/");
    pathToId.set(normalized, task.id);
    pathToId.set(
      normalized.replace(/^docs\//, ""),
      task.id
    );
  }
  return { statusToId, pathToId };
};

const errors = [];

const validateStatusNote = async (note, taskMap) => {
  const content = await fs.readFile(note.path, "utf8");
  const followUpIndex = content.indexOf("Follow-up");
  if (followUpIndex === -1) {
    return; // not every status note must have follow-up
  }
  // naive: search for `codex_pack/tasks/`
  const matches = content.match(/(?:docs\/)?codex_pack\/tasks\/[A-Za-z0-9-]+\.md/g);
  if (!matches) {
    errors.push(`${note.relPath} reference missing Codex task link in Follow-up`);
    return;
  }
  for (const match of matches) {
    const normalized = match.startsWith("docs/")
      ? match.replace(/\\/g, "/")
      : `docs/${match}`.replace(/\\/g, "/");
    if (!taskMap.pathToId.has(normalized)) {
      errors.push(`${note.relPath} references unknown task '${normalized}'`);
    }
  }
};

const validateTasks = async (taskMap, notes) => {
  const notePaths = new Set(notes.map((note) => note.relPath.replace(/\\/g, "/")));
  for (const [statusNote, taskId] of taskMap.statusToId.entries()) {
    if (!notePaths.has(statusNote)) {
      errors.push(`Task '${taskId}' references missing status note '${statusNote}'`);
    }
  }
};

const main = async () => {
  const noteList = await listStatusNotes();
  const taskMap = await loadTaskMetadata();
  await Promise.all(noteList.map((note) => validateStatusNote(note, taskMap)));
  await validateTasks(taskMap, noteList);
  if (errors.length > 0) {
    console.error("Status/Codex link validation failed:");
    for (const err of errors) {
      console.error(` • ${err}`);
    }
    process.exit(1);
  } else {
    console.log("Status/Codex link validation passed.");
  }
};

main().catch((error) => {
  console.error("Failed to validate status links:", error);
  process.exit(1);
});

