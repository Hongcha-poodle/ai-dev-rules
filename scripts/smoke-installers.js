const fs = require("fs");
const path = require("path");
const os = require("os");
const http = require("http");
const { spawn } = require("child_process");

const repoRoot = path.resolve(__dirname, "..");

function serveRepo(rootDir) {
  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      if (!req.url) {
        res.statusCode = 400;
        res.end("missing url");
        return;
      }

      const requestPath = decodeURIComponent(req.url.split("?")[0]).replace(/^\/+/, "");
      const localPath = path.resolve(rootDir, requestPath || "README.md");

      if (!localPath.startsWith(rootDir)) {
        res.statusCode = 403;
        res.end("forbidden");
        return;
      }

      if (!fs.existsSync(localPath) || fs.statSync(localPath).isDirectory()) {
        res.statusCode = 404;
        res.end("not found");
        return;
      }

      fs.createReadStream(localPath)
        .on("error", (error) => {
          res.statusCode = 500;
          res.end(String(error));
        })
        .pipe(res);
    });

    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      resolve({
        url: `http://127.0.0.1:${address.port}`,
        close: () =>
          new Promise((closeResolve, closeReject) => {
            server.close((error) => (error ? closeReject(error) : closeResolve()));
          }),
      });
    });
  });
}

function run(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: options.cwd || repoRoot,
      env: { ...process.env, ...(options.env || {}) },
      windowsHide: true,
    });

    let stdout = "";
    let stderr = "";
    let finished = false;
    const timeoutMs = options.timeoutMs || 120000;

    const timer = setTimeout(() => {
      if (finished) {
        return;
      }
      finished = true;
      child.kill();
      const error = new Error(`Command timed out after ${timeoutMs}ms: ${command} ${args.join(" ")}`);
      error.stdout = stdout;
      error.stderr = stderr;
      reject(error);
    }, timeoutMs);

    child.stdout?.setEncoding("utf-8");
    child.stderr?.setEncoding("utf-8");
    child.stdout?.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr?.on("data", (chunk) => {
      stderr += chunk;
    });

    child.on("error", (error) => {
      if (finished) {
        return;
      }
      finished = true;
      clearTimeout(timer);
      error.stdout = stdout;
      error.stderr = stderr;
      reject(error);
    });

    child.on("close", (status) => {
      if (finished) {
        return;
      }
      finished = true;
      clearTimeout(timer);

      if (status !== 0) {
        reject(
          new Error(
            [
              `Command failed: ${command} ${args.join(" ")}`,
              stdout || "",
              stderr || "",
            ]
              .filter(Boolean)
              .join("\n")
          )
        );
        return;
      }

      resolve({ stdout, stderr, status });
    });
  });
}

function requirePath(baseDir, relativePath) {
  const target = path.join(baseDir, relativePath);
  if (!fs.existsSync(target)) {
    throw new Error(`Missing expected file: ${relativePath}`);
  }
}

function requireText(baseDir, relativePath, snippet) {
  const target = path.join(baseDir, relativePath);
  const content = fs.readFileSync(target, "utf-8");
  if (!content.includes(snippet)) {
    throw new Error(`Missing expected text in ${relativePath}: ${snippet}`);
  }
}

function appendText(baseDir, relativePath, text) {
  fs.appendFileSync(path.join(baseDir, relativePath), text, "utf-8");
}

function requireMissingPath(baseDir, relativePath) {
  const target = path.join(baseDir, relativePath);
  if (fs.existsSync(target)) {
    throw new Error(`Unexpected file exists: ${relativePath}`);
  }
}

async function detectPythonCommand() {
  const candidates =
    process.platform === "win32"
      ? [
          ["python"],
          ["py", "-3"],
          ["py"],
          ["uv", "--cache-dir", ".uv-cache", "run", "python"],
        ]
      : [["python3"], ["python"], ["uv", "--cache-dir", ".uv-cache", "run", "python"]];

  for (const [command, ...args] of candidates) {
    try {
      await run(command, [...args, "--version"], { timeoutMs: 10000 });
      return [command, ...args];
    } catch {
      // Try the next candidate.
    }
  }

  return null;
}

async function detectPowerShellCommand() {
  const candidates = [
    ["pwsh"],
    ["pwsh.exe"],
    ["powershell.exe"],
    ["C:\\Program Files\\PowerShell\\7\\pwsh.exe"],
    ["C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"],
  ];

  for (const [command, ...args] of candidates) {
    try {
      await run(command, [...args, "-NoProfile", "-Command", "$PSVersionTable.PSVersion.ToString()"], {
        timeoutMs: 10000,
      });
      return [command, ...args];
    } catch {
      // Try the next candidate.
    }
  }

  throw new Error("Could not locate a usable PowerShell executable for smoke test.");
}

async function detectBashCommand() {
  const candidates =
    process.platform === "win32"
      ? [
          ["C:\\Program Files\\Git\\bin\\bash.exe"],
          ["C:\\Program Files\\Git\\usr\\bin\\bash.exe"],
          ["bash"],
        ]
      : [["bash"]];

  for (const [command, ...args] of candidates) {
    try {
      await run(command, [...args, "--version"], { timeoutMs: 10000 });
      return [command, ...args];
    } catch {
      // Try the next candidate.
    }
  }

  return null;
}

function toBashPath(targetPath) {
  const normalized = targetPath.replace(/\\/g, "/");
  if (process.platform !== "win32") {
    return normalized;
  }

  return normalized.replace(/^([A-Za-z]):\//, (_match, drive) => `/${drive.toLowerCase()}/`);
}

async function smokeInstalledProject(projectDir) {
  const expectedPaths = [
    ".ai/rules/workflow/long-running-guide.md",
    ".ai/entry-points/claude.md",
    ".ai/entry-points/copilot.md",
    ".ai/entry-points/antigravity.md",
    ".ai/entry-points/codex.md",
    ".ai/skills/harness/SKILL.md",
    "scripts/generate-hooks.sh",
    "scripts/generate-hooks.py",
    "scripts/harness-audit.py",
    "scripts/hook-runner.mjs",
    "CLAUDE.md",
    "AGENTS.md",
    ".github/copilot-instructions.md",
    ".agent/rules/rules.md",
    "docs/index.md",
  ];

  expectedPaths.forEach((target) => requirePath(projectDir, target));
  requireText(projectDir, "CLAUDE.md", "Project Specific Instructions");
  requireText(projectDir, "AGENTS.md", "## Project Map");
  requireText(projectDir, ".ai/entry-points/codex.md", "## Harness Load Timing");
  requireText(projectDir, ".ai/skills/harness/SKILL.md", "### Phase 6. Decide whether the client must reload");
  requireText(projectDir, ".ai/skills/harness/SKILL.md", "Claude-managed artifact 없음, reload 불필요");
  requireText(projectDir, ".ai/entry-points/claude.md", "py -3 scripts/generate-hooks.py");

  const pythonCommand = await detectPythonCommand();
  const settingsPath = path.join(projectDir, ".claude/settings.json");
  if (pythonCommand) {
    fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
    fs.writeFileSync(
      path.join(projectDir, "package.json"),
      JSON.stringify(
        {
          private: true,
          scripts: {
            lint: "eslint .",
            typecheck: "tsc --noEmit",
            test: "vitest",
          },
          devDependencies: {
            vitest: "latest",
          },
        },
        null,
        2
      ) + "\n",
      "utf-8"
    );
    fs.writeFileSync(
      settingsPath,
      JSON.stringify(
        {
          model: "test-model",
          permissions: {
            allow: ["Bash(custom-existing-command *)"],
          },
        },
        null,
        2
      ) + "\n",
      "utf-8"
    );

    await run(pythonCommand[0], [...pythonCommand.slice(1), "scripts/apply-hooks.py", ".ai/config/quality.yaml", ".claude/settings.json"], {
      cwd: projectDir,
    });

    const generated = JSON.parse(
      fs.readFileSync(settingsPath, "utf-8")
    );

    if (!generated.hooks || !generated.hooks.PostToolUse || !generated.hooks.PreToolUse || !generated.hooks.Stop) {
      throw new Error("Generated hooks config is missing expected hook groups.");
    }
    if (generated.model !== "test-model") {
      throw new Error("Existing settings keys were not preserved during hook merge.");
    }
    if (!generated.permissions?.allow?.includes("Bash(custom-existing-command *)")) {
      throw new Error("Existing permissions were not preserved during hook merge.");
    }
    const hookCommands = JSON.stringify(generated.hooks);
    if (!hookCommands.includes("node scripts/hook-runner.mjs")) {
      throw new Error("Generated hooks should use the portable hook runner.");
    }
    if (!hookCommands.includes("post-edit impacted-tests vitest")) {
      throw new Error("Vitest package.json detection did not generate a vitest related-test hook.");
    }
    if (hookCommands.includes("--findRelatedTests")) {
      throw new Error("Vitest projects must not generate Jest --findRelatedTests commands.");
    }
    await run(pythonCommand[0], [...pythonCommand.slice(1), "scripts/harness-audit.py"], {
      cwd: projectDir,
    });
  } else {
    console.warn("Skipping hook merge runtime check: no usable Python interpreter was found.");
  }

  const claudePath = path.join(projectDir, "CLAUDE.md");
  fs.appendFileSync(claudePath, "\n- Smoke test custom marker\n", "utf-8");
}

function smokeCodexOnlyProject(projectDir) {
  requirePath(projectDir, ".ai/core.md");
  requirePath(projectDir, ".ai/entry-points/codex.md");
  requirePath(projectDir, ".ai/skills/harness/SKILL.md");
  requirePath(projectDir, "AGENTS.md");
  requireText(projectDir, "AGENTS.md", "## Project Map");
  requireText(projectDir, ".ai/entry-points/codex.md", "## Harness Load Timing");
  requireText(projectDir, ".ai/skills/harness/SKILL.md", "### Phase 6. Decide whether the client must reload");

  requireMissingPath(projectDir, "CLAUDE.md");
  requireMissingPath(projectDir, ".github/copilot-instructions.md");
  requireMissingPath(projectDir, ".agent/rules/rules.md");
}

function smokeThreeToolProject(projectDir) {
  requirePath(projectDir, ".ai/core.md");
  requirePath(projectDir, ".ai/entry-points/claude.md");
  requirePath(projectDir, ".ai/entry-points/antigravity.md");
  requirePath(projectDir, ".ai/entry-points/codex.md");
  requirePath(projectDir, ".ai/skills/harness/SKILL.md");
  requirePath(projectDir, "CLAUDE.md");
  requirePath(projectDir, "AGENTS.md");
  requirePath(projectDir, ".agent/rules/rules.md");
  requireMissingPath(projectDir, ".github/copilot-instructions.md");
  requireText(projectDir, "CLAUDE.md", "Project Specific Instructions");
  requireText(projectDir, "AGENTS.md", "## Project Map");
  requireText(projectDir, ".agent/rules/rules.md", "Google Antigravity");
  requireText(projectDir, ".ai/entry-points/codex.md", "## Harness Load Timing");
  requireText(projectDir, ".ai/skills/harness/SKILL.md", "### Phase 6. Decide whether the client must reload");
}

function addThreeToolCustomMarkers(projectDir, marker) {
  appendText(projectDir, "CLAUDE.md", `\n- ${marker} Claude marker\n`);
  appendText(projectDir, "AGENTS.md", `\n- ${marker} Codex marker\n`);
  appendText(projectDir, ".agent/rules/rules.md", `\n- ${marker} Antigravity marker\n`);
}

function requireThreeToolCustomMarkers(projectDir, marker) {
  requireText(projectDir, "CLAUDE.md", `${marker} Claude marker`);
  requireText(projectDir, "AGENTS.md", `${marker} Codex marker`);
  requireText(projectDir, ".agent/rules/rules.md", `${marker} Antigravity marker`);
}

async function runPowerShellInstaller(projectDir, env) {
  const powerShell = await detectPowerShellCommand();
  await run(powerShell[0], [...powerShell.slice(1), "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", path.join(repoRoot, "templates", "setup-project.ps1")], {
    cwd: projectDir,
    env,
  });
}

async function runBashInstaller(projectDir, env) {
  const bash = await detectBashCommand();
  if (!bash) {
    throw new Error("Could not locate a usable Bash executable for smoke test.");
  }

  await run(bash[0], [...bash.slice(1), toBashPath(path.join(repoRoot, "templates", "setup-project.sh"))], {
    cwd: projectDir,
    env,
  });
}

async function runPlatformInstaller(projectDir, env) {
  if (process.platform === "win32") {
    await runPowerShellInstaller(projectDir, env);
    return;
  }

  await runBashInstaller(projectDir, env);
}

async function main() {
  const server = await serveRepo(repoRoot);
  const cleanupDirs = [];
  const projectDir = fs.mkdtempSync(path.join(os.tmpdir(), "ai-dev-rules-smoke-"));
  const codexOnlyDir = fs.mkdtempSync(path.join(os.tmpdir(), "ai-dev-rules-codex-smoke-"));
  const threeToolDir = fs.mkdtempSync(path.join(os.tmpdir(), "ai-dev-rules-three-tools-smoke-"));
  cleanupDirs.push(projectDir, codexOnlyDir, threeToolDir);
  const env = { REPO_URL: server.url };

  try {
    await runPlatformInstaller(projectDir, { ...env, AI_TOOL: "all" });
    await smokeInstalledProject(projectDir);
    await runPlatformInstaller(projectDir, { ...env, AI_TOOL: "all" });

    requireText(projectDir, "CLAUDE.md", "Smoke test custom marker");
    await runPlatformInstaller(codexOnlyDir, { ...env, AI_TOOL: "codex" });
    smokeCodexOnlyProject(codexOnlyDir);
    await runPlatformInstaller(threeToolDir, { ...env, AI_TOOL: "claude,codex,antigravity" });
    smokeThreeToolProject(threeToolDir);
    addThreeToolCustomMarkers(threeToolDir, "Platform update");
    await runPlatformInstaller(threeToolDir, { ...env, AI_TOOL: "claude,codex,antigravity" });
    smokeThreeToolProject(threeToolDir);
    requireThreeToolCustomMarkers(threeToolDir, "Platform update");

    const bash = await detectBashCommand();
    if (bash && process.platform === "win32") {
      const bashThreeToolDir = fs.mkdtempSync(path.join(os.tmpdir(), "ai-dev-rules-bash-three-tools-smoke-"));
      cleanupDirs.push(bashThreeToolDir);
      await runBashInstaller(bashThreeToolDir, { ...env, AI_TOOL: "2,3,4" });
      smokeThreeToolProject(bashThreeToolDir);
      addThreeToolCustomMarkers(bashThreeToolDir, "Bash update");
      await runBashInstaller(bashThreeToolDir, { ...env, AI_TOOL: "2,3,4" });
      smokeThreeToolProject(bashThreeToolDir);
      requireThreeToolCustomMarkers(bashThreeToolDir, "Bash update");
    } else if (!bash) {
      console.warn("Skipping Bash installer smoke: no usable Bash executable was found.");
    }

    console.log(`Installer smoke test passed on ${process.platform}: ${projectDir}`);
  } finally {
    await server.close();
    for (const dir of cleanupDirs) {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
