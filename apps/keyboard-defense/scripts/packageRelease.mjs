import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";
import archiver from "archiver";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..");

const version =
  process.argv[2] ??
  process.env.SEMANTIC_RELEASE_NEXT_VERSION ??
  process.env.npm_package_version;

if (!version) {
  console.error(
    "[release] Missing version argument. Pass it explicitly (`node scripts/packageRelease.mjs 1.2.3`) " +
      "or set SEMANTIC_RELEASE_NEXT_VERSION."
  );
  process.exit(1);
}

const releaseDir = path.join(projectRoot, "artifacts", "release");
const bundleName = `keyboard-defense-${version}.zip`;
const bundlePath = path.join(releaseDir, bundleName);
const manifestPath = path.join(releaseDir, `release-manifest-${version}.json`);

await fs.promises.rm(releaseDir, { recursive: true, force: true });
await fs.promises.mkdir(releaseDir, { recursive: true });

await createBundle(bundlePath);

const stats = await fs.promises.stat(bundlePath);
const sha256 = await hashFile(bundlePath);

const manifest = {
  version,
  createdAt: new Date().toISOString(),
  artifacts: [
    {
      file: bundleName,
      path: path.relative(projectRoot, bundlePath).replace(/\\/g, "/"),
      sizeBytes: stats.size,
      sha256,
      contents: [
        "public/**",
        "README.md",
        "CHANGELOG.md"
      ]
    }
  ]
};

await fs.promises.writeFile(manifestPath, JSON.stringify(manifest, null, 2));

console.log(
  `[release] Bundle ready -> ${bundleName} (${formatBytes(
    stats.size
  )}, sha256 ${sha256.slice(0, 12)}…)`
);
console.log(`[release] Manifest written to ${path.relative(projectRoot, manifestPath)}`);

async function createBundle(destination) {
  await new Promise((resolve, reject) => {
    const output = fs.createWriteStream(destination);
    const archive = archiver("zip", { zlib: { level: 9 } });

    output.on("close", resolve);
    output.on("error", reject);
    archive.on("error", reject);

    archive.pipe(output);

    archive.directory(path.join(projectRoot, "public"), "keyboard-defense/public");
    archive.file(path.join(projectRoot, "README.md"), { name: "keyboard-defense/README.md" });
    archive.file(path.join(projectRoot, "CHANGELOG.md"), { name: "keyboard-defense/CHANGELOG.md" });

    archive.finalize();
  });
}

async function hashFile(filePath) {
  const hash = crypto.createHash("sha256");
  await new Promise((resolve, reject) => {
    const stream = fs.createReadStream(filePath);
    stream.on("data", (chunk) => hash.update(chunk));
    stream.on("end", resolve);
    stream.on("error", reject);
  });
  return hash.digest("hex");
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  const units = ["KB", "MB", "GB"];
  let value = bytes / 1024;
  let idx = 0;
  while (value >= 1024 && idx < units.length - 1) {
    value /= 1024;
    idx += 1;
  }
  return `${value.toFixed(1)} ${units[idx]}`;
}

