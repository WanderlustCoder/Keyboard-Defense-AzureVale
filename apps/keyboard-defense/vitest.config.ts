import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

function tsExtensionResolver() {
  return {
    name: "ts-extension-resolver",
    enforce: "pre",
    resolveId(source, importer) {
      if (!importer) return null;
      if (!source.endsWith(".js")) return null;
      if (!source.startsWith(".") && !source.startsWith("/")) return null;
      const importerPath = normalizeImporterPath(importer);
      const importerDir = path.dirname(importerPath);
      const resolved = path.resolve(importerDir, source);
      const tsCandidate = resolved.replace(/\.js$/, ".ts");
      if (fs.existsSync(tsCandidate)) {
        return tsCandidate;
      }
      const distCandidate = resolveDistFallback(resolved);
      if (distCandidate && fs.existsSync(distCandidate)) {
        return distCandidate;
      }
      return null;
    }
  };
}

function normalizeImporterPath(importer: string) {
  if (importer.startsWith("file://")) {
    return fileURLToPath(importer);
  }
  if (importer.startsWith("/@fs/")) {
    return importer.slice(4);
  }
  return importer;
}

function resolveDistFallback(resolvedPath: string) {
  const marker = `${path.sep}src${path.sep}`;
  const markerIndex = resolvedPath.lastIndexOf(marker);
  if (markerIndex === -1) {
    return null;
  }
  return (
    resolvedPath.slice(0, markerIndex) +
    `${path.sep}public${path.sep}dist${path.sep}src${path.sep}` +
    resolvedPath.slice(markerIndex + marker.length)
  );
}

export default defineConfig({
  plugins: [tsExtensionResolver()],
  resolve: {
    extensions: [".ts", ".tsx", ".js", ".jsx", ".mjs", ".json"]
  },
  test: {
    exclude: ["tests/visual/**", "node_modules/**", "dist/**", "public/**"]
  }
});
