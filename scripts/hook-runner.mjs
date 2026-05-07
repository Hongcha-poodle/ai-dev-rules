#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import crypto from "node:crypto";
import { spawnSync } from "node:child_process";

const repoRoot = process.cwd();
const group = process.argv[2] || "";
const action = process.argv[3] || "";
const option = process.argv[4] || "";
const isWindows = process.platform === "win32";

function commandName(name) {
  return isWindows && ["npm", "npx"].includes(name) ? `${name}.cmd` : name;
}

function readJsonFile(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return {};
  }
}

function packageJson() {
  return readJsonFile(path.join(repoRoot, "package.json"));
}

function hasPackage(pkg, name) {
  return ["dependencies", "devDependencies", "peerDependencies", "optionalDependencies"].some((key) => {
    const values = pkg[key];
    return values && typeof values === "object" && Object.prototype.hasOwnProperty.call(values, name);
  });
}

function packageScripts(pkg) {
  return pkg.scripts && typeof pkg.scripts === "object" ? pkg.scripts : {};
}

function detectLanguage() {
  if (fs.existsSync(path.join(repoRoot, "package.json"))) {
    return "javascript";
  }
  if (fs.existsSync(path.join(repoRoot, "go.mod"))) {
    return "go";
  }
  if (["pyproject.toml", "requirements.txt", "setup.py", "tox.ini"].some((name) => fs.existsSync(path.join(repoRoot, name)))) {
    return "python";
  }
  return "generic";
}

function detectJavascriptTestRunner() {
  const pkg = packageJson();
  const scriptsText = Object.values(packageScripts(pkg)).filter((value) => typeof value === "string").join(" ");
  if (hasPackage(pkg, "vitest") || /(^|[^A-Za-z0-9_-])vitest([^A-Za-z0-9_-]|$)/.test(scriptsText)) {
    return "vitest";
  }
  if (hasPackage(pkg, "jest") || /(^|[^A-Za-z0-9_-])jest([^A-Za-z0-9_-]|$)/.test(scriptsText)) {
    return "jest";
  }
  return "";
}

function readHookPayload() {
  let raw = "";
  try {
    raw = fs.readFileSync(0, "utf8");
  } catch {
    return {};
  }
  if (!raw.trim()) {
    return {};
  }
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function editedFileFromPayload(payload) {
  const input = payload && typeof payload === "object" ? payload.tool_input || {} : {};
  return input.file_path || input.path || input.file || "";
}

function tailLines(text, count) {
  const lines = text.replace(/\s+$/u, "").split(/\r?\n/u).filter(Boolean);
  return lines.slice(-count).join("\n");
}

function printCommand(label, command, args) {
  console.log(`$ ${label || [command, ...args].join(" ")}`);
}

function runCommand(command, args, options = {}) {
  const label = options.label || [command, ...args].join(" ");
  const lines = options.lines || 20;
  printCommand(label, command, args);

  const result = spawnSync(command, args, {
    cwd: repoRoot,
    encoding: "utf8",
    env: process.env,
    shell: isWindows,
    windowsHide: true,
  });

  if (result.error) {
    console.log(`TODO: command unavailable: ${label}`);
    console.log(result.error.message);
    return 0;
  }

  const output = [result.stdout, result.stderr].filter(Boolean).join("");
  const trimmed = tailLines(output, lines);
  if (trimmed) {
    console.log(trimmed);
  }
  if (result.status && result.status !== 0) {
    console.log(`${label} exited with status ${result.status}.`);
  }
  return result.status || 0;
}

function localBinary(name) {
  const suffix = isWindows ? ".cmd" : "";
  const candidate = path.join(repoRoot, "node_modules", ".bin", `${name}${suffix}`);
  return fs.existsSync(candidate) ? candidate : "";
}

function runPackageBinary(name, args, options = {}) {
  const local = localBinary(name);
  if (local) {
    return runCommand(local, args, { ...options, label: `${name} ${args.join(" ")}` });
  }
  return runCommand(commandName("npx"), ["--no-install", name, ...args], { ...options, label: `npx --no-install ${name} ${args.join(" ")}` });
}

function runNpm(args, options = {}) {
  return runCommand(commandName("npm"), args, options);
}

function runJavascriptLint(lines = 20) {
  const scripts = packageScripts(packageJson());
  if (scripts.lint) {
    return runNpm(["run", "lint"], { label: "npm run lint", lines });
  }
  console.log("TODO: configure lint script in package.json.");
  return 0;
}

function runJavascriptTypecheck(lines = 20) {
  const pkg = packageJson();
  const scripts = packageScripts(pkg);
  if (scripts.typecheck) {
    return runNpm(["run", "typecheck"], { label: "npm run typecheck", lines });
  }
  if (hasPackage(pkg, "typescript") || fs.existsSync(path.join(repoRoot, "tsconfig.json"))) {
    return runPackageBinary("tsc", ["--noEmit"], { lines });
  }
  console.log("TODO: configure typecheck script in package.json.");
  return 0;
}

function runJavascriptTests(lines = 20) {
  const scripts = packageScripts(packageJson());
  if (scripts.test) {
    return runNpm(["test"], { label: "npm test", lines });
  }
  console.log("TODO: configure test script in package.json.");
  return 0;
}

function runJavascriptImpactedTests(filePath, runner, lines = 20) {
  if (!filePath) {
    console.log("No edited file path found in hook input; skipping impacted tests.");
    return 0;
  }

  const selectedRunner = runner || detectJavascriptTestRunner();
  if (selectedRunner === "vitest") {
    return runPackageBinary("vitest", ["related", filePath, "--run"], { lines });
  }
  if (selectedRunner === "jest") {
    const local = localBinary("jest");
    if (local) {
      return runCommand(local, ["--findRelatedTests", filePath], { label: `jest --findRelatedTests ${filePath}`, lines });
    }
    return runNpm(["test", "--", "--findRelatedTests", filePath], { label: `npm test -- --findRelatedTests ${filePath}`, lines });
  }

  console.log("TODO: no supported impacted test runner detected. Configure vitest or jest, or run full npm test.");
  return 0;
}

function runGoLint(lines = 20) {
  runCommand(commandName("gofmt"), ["-l", "."], { label: "gofmt -l .", lines: 10 });
  return runCommand(commandName("go"), ["vet", "./..."], { label: "go vet ./...", lines });
}

function runPythonLint(lines = 20) {
  return runCommand(commandName("ruff"), ["check", "."], { label: "ruff check .", lines });
}

function runPythonTypecheck(lines = 20) {
  return runCommand(commandName("mypy"), [".", "--no-error-summary"], { label: "mypy . --no-error-summary", lines });
}

function runLint(lines = 20) {
  const language = detectLanguage();
  if (language === "javascript") {
    return runJavascriptLint(lines);
  }
  if (language === "go") {
    return runGoLint(lines);
  }
  if (language === "python") {
    return runPythonLint(lines);
  }
  console.log("TODO: configure lint command for this repository.");
  return 0;
}

function runTypecheck(lines = 20) {
  const language = detectLanguage();
  if (language === "javascript") {
    return runJavascriptTypecheck(lines);
  }
  if (language === "go") {
    return runCommand(commandName("go"), ["test", "./..."], { label: "go test ./...", lines });
  }
  if (language === "python") {
    return runPythonTypecheck(lines);
  }
  console.log("TODO: configure typecheck command for this repository.");
  return 0;
}

function runImpactedTests(lines = 20) {
  const language = detectLanguage();
  if (language === "javascript") {
    const payload = readHookPayload();
    return runJavascriptImpactedTests(editedFileFromPayload(payload), option, lines);
  }
  if (language === "go") {
    return runCommand(commandName("go"), ["test", "./..."], { label: "go test ./...", lines });
  }
  if (language === "python") {
    return runCommand(commandName("pytest"), ["-q"], { label: "pytest -q", lines });
  }
  console.log("TODO: configure impacted test command for this repository.");
  return 0;
}

function runCoverageReport() {
  const language = detectLanguage();
  let status = 0;
  let output = "";

  if (language === "javascript") {
    const result = spawnSync(commandName("npm"), ["test", "--", "--coverage"], {
      cwd: repoRoot,
      encoding: "utf8",
      shell: isWindows,
      windowsHide: true,
    });
    status = result.status || 0;
    output = [result.stdout, result.stderr].filter(Boolean).join("");
  } else if (language === "go") {
    const result = spawnSync(commandName("go"), ["test", "./...", "-cover"], {
      cwd: repoRoot,
      encoding: "utf8",
      shell: isWindows,
      windowsHide: true,
    });
    status = result.status || 0;
    output = [result.stdout, result.stderr].filter(Boolean).join("");
  } else if (language === "python") {
    const result = spawnSync(commandName("pytest"), ["--cov"], {
      cwd: repoRoot,
      encoding: "utf8",
      shell: isWindows,
      windowsHide: true,
    });
    status = result.status || 0;
    output = [result.stdout, result.stderr].filter(Boolean).join("");
  } else {
    console.log("TODO: configure coverage command for this repository.");
    return 0;
  }

  const coverageLines = output
    .split(/\r?\n/u)
    .filter((line) => /Statements|Branches|Functions|Lines|coverage:|% Stmts|TOTAL|All files/u.test(line));
  console.log(tailLines(coverageLines.join("\n") || output, 20));
  if (status !== 0) {
    console.log(`coverage command exited with status ${status}.`);
  }
  return 0;
}

function runQualitySummary() {
  console.log("=== Quality Summary ===");
  runLint(10);
  runTypecheck(10);

  const language = detectLanguage();
  if (language === "javascript") {
    runJavascriptTests(10);
  } else if (language === "go") {
    runCommand(commandName("go"), ["test", "./..."], { label: "go test ./...", lines: 10 });
  } else if (language === "python") {
    runCommand(commandName("pytest"), ["-q"], { label: "pytest -q", lines: 10 });
  } else {
    console.log("TODO: configure quality summary commands for this repository.");
  }
  return 0;
}

function blockDestructiveCommand() {
  const payload = readHookPayload();
  const command = payload?.tool_input?.command || "";
  const destructive = /(rm\s+-rf|git\s+push\s+--force|git\s+reset\s+--hard|Remove-Item\b.*\b-Recurse\b.*\b-Force\b)/i;
  if (destructive.test(command)) {
    console.error("BLOCK: destructive command");
    return 2;
  }
  return 0;
}

function loopDetect() {
  const payload = readHookPayload();
  const filePath = editedFileFromPayload(payload);
  if (!filePath) {
    return 0;
  }
  const hash = crypto.createHash("sha256").update(`${repoRoot}:${filePath}`).digest("hex").slice(0, 16);
  const counterPath = path.join(os.tmpdir(), `ai-dev-rules-edit-counter-${hash}.txt`);
  let count = 0;
  try {
    count = Number.parseInt(fs.readFileSync(counterPath, "utf8"), 10) || 0;
  } catch {
    count = 0;
  }
  count += 1;
  fs.writeFileSync(counterPath, String(count), "utf8");
  if (count >= 4) {
    console.error(`LOOP DETECTED: ${filePath} edited ${count} times. Stop and reassess approach.`);
    try {
      fs.unlinkSync(counterPath);
    } catch {
      // Best-effort cleanup only.
    }
  }
  return 0;
}

function main() {
  if (group === "pre-bash" && action === "block-destructive") {
    return blockDestructiveCommand();
  }
  if (group === "post-edit" && action === "lint") {
    return runLint();
  }
  if (group === "post-edit" && action === "typecheck") {
    return runTypecheck();
  }
  if (group === "post-edit" && action === "impacted-tests") {
    return runImpactedTests();
  }
  if (group === "post-edit" && action === "loop-detect") {
    return loopDetect();
  }
  if (group === "stop" && action === "coverage-report") {
    return runCoverageReport();
  }
  if (group === "stop" && action === "quality-summary") {
    return runQualitySummary();
  }
  if (group === "stop" && action === "delivery-summary") {
    console.log("Delivery summary: verify smoke checks, rollback plan, and observability notes for risky changes.");
    return 0;
  }
  if (group === "stop" && action === "harness-summary") {
    console.log("Harness summary: confirm docs/index.md, docs/harness/, and cleanup loop remain current.");
    return 0;
  }

  console.log(`Unknown hook runner action: ${group} ${action}`.trim());
  return 0;
}

process.exitCode = main();
