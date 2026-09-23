/**
 * Protect Sensitive Files Plugin for OpenCode V2.
 *
 * Blocks read, write, glob, grep, patch, and shell access to sensitive files.
 * Read and edit denies also live in opencode.jsonc permissions. This hook
 * covers grep paths, glob patterns, and shell commands, which permissions
 * cannot match reliably.
 */

const ENABLED = true;

const SENSITIVE_FILE_PATTERNS = [
  /\.env($|\.)/,
  /env\.local$/,
  /env\.production$/,
  /env\.staging$/,
  /env\.development$/,
  /\.key$/,
  /\.pem$/,
  /\.p12$/,
  /\.pfx$/,
  /\.crt$/,
  /\.cer$/,
  /\.der$/,
  /privatekey/i,
  /private[_-]?key/i,
  /id_rsa/,
  /id_ed25519/,
  /id_ecdsa/,
  /id_dsa/,
  /\.ssh\/config$/,
  /known_hosts$/,
  /authorized_keys$/,
  /\.npmrc$/,
  /\.pypirc$/,
  /\.netrc$/,
  /\.aws\/credentials$/,
  /\.aws\/config$/,
  /\.docker\/config\.json$/,
  /auth\.json$/,
  /database\.yml$/,
  /database\.json$/,
  /\.pgpass$/,
  /\.my\.cnf$/,
  /db\.config/i,
  /\.git-credentials$/,
];

const WHITELIST_PATTERNS = [
  /\.example$/,
  /\.template$/,
  /\.sample$/,
  /\.dist$/,
  /\.default$/,
  /README/i,
  /EXAMPLE/i,
];

const FILE_TOOLS = new Set([
  "read",
  "glob",
  "grep",
  "edit",
  "write",
  "patch",
  "look_at",
  "multiedit",
]);

const SHELL_TOOLS = new Set(["shell", "bash"]);

const FILE_READ_COMMANDS = [
  "cat", "grep", "egrep", "fgrep", "rg", "ag", "ack",
  "head", "tail", "less", "more", "strings", "nl", "od", "xxd",
  "sed", "awk", "perl",
  "vim", "vi", "nano", "emacs", "ed",
  "tac", "rev", "cut", "paste", "sort", "uniq",
  "diff", "cmp", "comm",
  "file", "stat", "wc", "md5sum", "sha256sum",
];

const SCRIPT_INTERPRETERS = [
  "python", "python3", "python2",
  "node", "nodejs",
  "ruby", "irb",
  "perl",
  "php",
  "bash", "sh", "zsh",
];

function isSensitiveFile(filePath) {
  if (!filePath) return false;

  const normalizedPath = String(filePath).trim();
  if (WHITELIST_PATTERNS.some((pattern) => pattern.test(normalizedPath))) {
    return false;
  }

  const fileName = normalizedPath.split("/").pop() || "";
  return SENSITIVE_FILE_PATTERNS.some((pattern) => pattern.test(fileName) || pattern.test(normalizedPath));
}

function isWhitelisted(filePath) {
  if (!filePath) return false;
  return WHITELIST_PATTERNS.some((pattern) => pattern.test(filePath));
}

function extractFileReferences(command) {
  if (!command) return [];

  const files = new Set();
  const commandPattern = new RegExp(
    `(?:${FILE_READ_COMMANDS.join("|")})\\s+(?:(?:-[a-zA-Z0-9]+)\\s+)*([^\\s;|&><]+)`,
    "g",
  );
  let match;
  while ((match = commandPattern.exec(command)) !== null) {
    files.add(match[1]);
  }

  const redirectPattern = /(?:<|>|>>)\s*([^\s;|&><]+)/g;
  while ((match = redirectPattern.exec(command)) !== null) {
    files.add(match[1]);
  }

  const processSubPattern = /(?:\$\(|`)\s*(?:cat|head|tail)\s+([^\s;|&><)]+)/g;
  while ((match = processSubPattern.exec(command)) !== null) {
    files.add(match[1]);
  }

  const varPattern = /(\w+)=([^\s;|&]+)/g;
  const vars = {};
  while ((match = varPattern.exec(command)) !== null) {
    vars[match[1]] = match[2];
  }
  for (const value of Object.values(vars)) {
    if (isSensitiveFile(value)) {
      files.add(value);
    }
  }

  const gitPattern = /git\s+(?:diff|show|cat-file)\s+(?:[^\s]+\s+)?([^\s;|&]+)/g;
  while ((match = gitPattern.exec(command)) !== null) {
    files.add(match[1].replace(/^HEAD:/, ""));
  }

  const scriptPattern = new RegExp(
    `(?:${SCRIPT_INTERPRETERS.join("|")})\\s+(?:-[ce]\\s+)?["'].*?([^"'\\/\\s]+\\.env[^"']*)`,
    "g",
  );
  while ((match = scriptPattern.exec(command)) !== null) {
    files.add(match[1]);
  }

  const wildcardPattern = /([^\s;|&><]*\*[^\s;|&><]*\.env[^\s;|&><]*|\.env[^\s;|&><]*\*[^\s;|&><]*)/g;
  while ((match = wildcardPattern.exec(command)) !== null) {
    files.add(match[1]);
  }

  const quotedPattern = /["']([^"']*\.env[^"']*)["']/g;
  while ((match = quotedPattern.exec(command)) !== null) {
    files.add(match[1]);
  }

  return Array.from(files);
}

function containsSensitiveFileAccess(command) {
  if (!command) return false;
  return extractFileReferences(command).some((ref) => {
    const cleanRef = ref.replace(/^["']|["']$/g, "");
    return isSensitiveFile(cleanRef) && !isWhitelisted(cleanRef);
  });
}

function hasDangerousPattern(command) {
  if (!command) return false;
  return [
    /python.*-c.*open\s*\(/i,
    /node.*-e.*readFile/i,
    /ruby.*-e.*File\.read/i,
    /perl.*-e.*open/i,
    /bash.*-c.*cat/i,
    /sh.*-c.*cat/i,
  ].some((pattern) => pattern.test(command));
}

function generateBlockedMessage(filePath, operation, tool) {
  return `Sensitive file access blocked

Access to sensitive files is completely blocked for security.

Blocked file: ${filePath || "sensitive file"}
Operation: ${operation}${tool ? ` (${tool})` : ""}

This file likely contains secrets, credentials, or sensitive configuration.
Use a .example or template file, or edit the sensitive file yourself.

To override (not recommended):
Edit ~/.config/opencode/plugins/protect-sensitive-files.js
Set ENABLED = false
`;
}

function blockedReference(command) {
  const sensitive = extractFileReferences(command).filter((file) => isSensitiveFile(file) && !isWhitelisted(file));
  return sensitive[0] || "sensitive file";
}

function assertCommandAllowed(command, tool) {
  if (!command) return;
  if (containsSensitiveFileAccess(command)) {
    throw new Error(generateBlockedMessage(blockedReference(command), "shell command", tool));
  }
  if (hasDangerousPattern(command)) {
    throw new Error(generateBlockedMessage("potentially sensitive file", "script execution", tool));
  }
}

function pathsFromInput(input) {
  if (!input || typeof input !== "object") return [];

  const edits = Array.isArray(input.edits)
    ? input.edits.map((edit) => edit?.filePath || edit?.path)
    : [];
  const patchPaths = typeof input.patchText === "string"
    ? [...input.patchText.matchAll(/^\*\*\* (?:Add|Update|Delete|Move) File: (.+)$/gm)].map((match) => match[1].trim())
    : [];

  return [
    input.path,
    input.filePath,
    input.file_path,
    input.pattern,
    ...(Array.isArray(input.paths) ? input.paths : []),
    ...edits,
    ...patchPaths,
  ].filter((value) => typeof value === "string" && value.length > 0);
}

function assertPathsAllowed(paths, operation, tool) {
  for (const path of paths) {
    if (isSensitiveFile(path) && !isWhitelisted(path)) {
      throw new Error(generateBlockedMessage(path, operation, tool));
    }
  }
}

export default {
  id: "protect-sensitive-files",
  async setup(ctx) {
    if (!ENABLED) return;

    await ctx.tool.hook("execute.before", (event) => {
      const tool = event.tool;
      const input = event.input ?? {};

      if (FILE_TOOLS.has(tool)) {
        assertPathsAllowed(pathsFromInput(input), "access", tool);
      }

      if (SHELL_TOOLS.has(tool)) {
        assertCommandAllowed(input.command, tool);
      }
    });

    await ctx.shell.hook("create.before", (event) => {
      assertCommandAllowed(event.command, "shell");
    });
  },
};
