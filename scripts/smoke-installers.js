const fs = require("fs");
const path = require("path");
const os = require("os");
const http = require("http");
const { spawnSync } = require("child_process");

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
  const result = spawnSync(command, args, {
    cwd: options.cwd || repoRoot,
    env: { ...process.env, ...(options.env || {}) },
    encoding: "utf-8",
    timeout: options.timeoutMs || 120000,
  });

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    throw new Error(
      [
        `Command failed: ${command} ${args.join(" ")}`,
        result.stdout || "",
        result.stderr || "",
      ]
        .filter(Boolean)
        .join("\n")
    );
  }

  return result;
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

function detectPythonCommand() {
  const candidates =
    process.platform === "win32"
      ? [
          ["python"],
          ["py", "-3"],
          ["py"],
        ]
      : [["python3"], ["python"]];

  for (const [command, ...args] of candidates) {
    const probe = spawnSync(command, [...args, "--version"], {
      encoding: "utf-8",
      timeout: 10000,
    });
    if (!probe.error && probe.status === 0) {
      return [command, ...args];
    }
  }

  throw new Error("Could not locate a usable Python interpreter for smoke test.");
}

function detectPowerShellCommand() {
  const candidates = [
    ["pwsh"],
    ["powershell.exe"],
  ];

  for (const [command, ...args] of candidates) {
    const probe = spawnSync(command, [...args, "-NoProfile", "-Command", "$PSVersionTable.PSVersion.ToString()"], {
      encoding: "utf-8",
      timeout: 10000,
    });
    if (!probe.error && probe.status === 0) {
      return [command, ...args];
    }
  }

  throw new Error("Could not locate a usable PowerShell executable for smoke test.");
}

function smokeInstalledProject(projectDir) {
  const expectedPaths = [
    ".ai/rules/workflow/long-running-guide.md",
    ".ai/entry-points/claude.md",
    ".ai/entry-points/copilot.md",
    ".ai/entry-points/antigravity.md",
    ".ai/entry-points/codex.md",
    "scripts/generate-hooks.sh",
    "scripts/generate-hooks.py",
    "CLAUDE.md",
    "AGENTS.md",
    ".github/copilot-instructions.md",
    ".agent/rules/rules.md",
    "docs/index.md",
  ];

  expectedPaths.forEach((target) => requirePath(projectDir, target));
  requireText(projectDir, "CLAUDE.md", "Project Specific Instructions");
  requireText(projectDir, "AGENTS.md", "## Project Map");

  const pythonCommand = detectPythonCommand();
  const settingsPath = path.join(projectDir, ".claude/settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
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

  run(pythonCommand[0], [...pythonCommand.slice(1), "scripts/apply-hooks.py", ".ai/config/quality.yaml", ".claude/settings.json"], {
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

  const claudePath = path.join(projectDir, "CLAUDE.md");
  fs.appendFileSync(claudePath, "\n- Smoke test custom marker\n", "utf-8");
}

async function main() {
  const server = await serveRepo(repoRoot);
  const projectDir = fs.mkdtempSync(path.join(os.tmpdir(), "ai-dev-rules-smoke-"));
  const env = { REPO_URL: server.url, AI_TOOL: "all" };

  try {
    if (process.platform === "win32") {
      const powerShell = detectPowerShellCommand();
      run(powerShell[0], [...powerShell.slice(1), "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", path.join(repoRoot, "templates", "setup-project.ps1")], {
        cwd: projectDir,
        env,
      });
      smokeInstalledProject(projectDir);
      run(powerShell[0], [...powerShell.slice(1), "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", path.join(repoRoot, "templates", "setup-project.ps1")], {
        cwd: projectDir,
        env,
      });
    } else {
      run("bash", [path.join(repoRoot, "templates", "setup-project.sh")], {
        cwd: projectDir,
        env,
      });
      smokeInstalledProject(projectDir);
      run("bash", [path.join(repoRoot, "templates", "setup-project.sh")], {
        cwd: projectDir,
        env,
      });
    }

    requireText(projectDir, "CLAUDE.md", "Smoke test custom marker");
    console.log(`Installer smoke test passed on ${process.platform}: ${projectDir}`);
  } finally {
    await server.close();
    fs.rmSync(projectDir, { recursive: true, force: true });
  }
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
