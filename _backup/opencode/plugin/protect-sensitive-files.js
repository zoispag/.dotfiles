/**
 * Protect Sensitive Files Plugin for OpenCode
 * 
 * Blocks ALL access (read/write) to sensitive files like .env, credentials, secrets, etc.
 * 
 * Security Level: MAXIMUM
 * - Blocks read operations (read, grep, glob, etc.)
 * - Blocks write operations (write, edit)
 * - Blocks bash commands accessing sensitive files
 * - Blocks script execution bypasses
 * - Blocks LSP operations on sensitive files
 */

// ============================================================================
// CONFIGURATION
// ============================================================================

const ENABLED = true;

// Sensitive file patterns - comprehensive list
const SENSITIVE_FILE_PATTERNS = [
  // Environment files
  /\.env($|\.)/, // .env, .env.local, .env.production, etc.
  /env\.local$/,
  /env\.production$/,
  /env\.staging$/,
  /env\.development$/,
  
  // Certificates & keys
  /\.key$/,
  /\.pem$/,
  /\.p12$/,
  /\.pfx$/,
  /\.crt$/,
  /\.cer$/,
  /\.der$/,
  /privatekey/i,
  /private[_-]?key/i,
  
  // SSH keys
  /id_rsa/,
  /id_ed25519/,
  /id_ecdsa/,
  /id_dsa/,
  /\.ssh\/config$/,
  /known_hosts$/,
  /authorized_keys$/,
  
  // Configuration with tokens
  /\.npmrc$/,
  /\.pypirc$/,
  /\.netrc$/,
  /\.aws\/credentials$/,
  /\.aws\/config$/,
  /\.docker\/config\.json$/,
  /auth\.json$/,
  
  // Database configs
  /database\.yml$/,
  /database\.json$/,
  /\.pgpass$/,
  /\.my\.cnf$/,
  /db\.config/i,
  
  // Git credentials
  /\.git-credentials$/,
];

// Whitelist exceptions - these files are OK to read
const WHITELIST_PATTERNS = [
  /\.example$/,
  /\.template$/,
  /\.sample$/,
  /\.dist$/,
  /\.default$/,
  /README/i,
  /EXAMPLE/i,
];

// Tools that access files
const FILE_READ_TOOLS = [
  'read',
  'glob',
  'grep',
  'look_at',
  'lsp_hover',
  'lsp_goto_definition',
  'lsp_find_references',
  'lsp_document_symbols',
  'lsp_diagnostics',
  'lsp_prepare_rename',
  'lsp_rename',
  'lsp_code_actions',
  'lsp_code_action_resolve',
];

const FILE_WRITE_TOOLS = [
  'write',
  'edit',
  'multiedit',
];

// Bash commands that read files
const FILE_READ_COMMANDS = [
  'cat', 'grep', 'egrep', 'fgrep', 'rg', 'ag', 'ack',
  'head', 'tail', 'less', 'more', 'strings', 'nl', 'od', 'xxd',
  'sed', 'awk', 'perl',
  'vim', 'vi', 'nano', 'emacs', 'ed',
  'tac', 'rev', 'cut', 'paste', 'sort', 'uniq',
  'diff', 'cmp', 'comm',
  'file', 'stat', 'wc', 'md5sum', 'sha256sum',
];

// Script interpreters that could read files
const SCRIPT_INTERPRETERS = [
  'python', 'python3', 'python2',
  'node', 'nodejs',
  'ruby', 'irb',
  'perl',
  'php',
  'bash', 'sh', 'zsh',
];

// ============================================================================
// CORE DETECTION LOGIC
// ============================================================================

/**
 * Check if a file path is sensitive
 */
function isSensitiveFile(filePath) {
  if (!filePath) return false;
  
  // Normalize path
  const normalizedPath = filePath.trim();
  
  // Check whitelist first (these are OK)
  if (WHITELIST_PATTERNS.some(pattern => pattern.test(normalizedPath))) {
    return false;
  }
  
  // Extract filename
  const fileName = normalizedPath.split('/').pop() || '';
  
  // Check against sensitive patterns
  return SENSITIVE_FILE_PATTERNS.some(pattern => 
    pattern.test(fileName) || pattern.test(normalizedPath)
  );
}

/**
 * Check if a file path is whitelisted (safe to access)
 */
function isWhitelisted(filePath) {
  if (!filePath) return false;
  return WHITELIST_PATTERNS.some(pattern => pattern.test(filePath));
}

/**
 * Extract potential file references from a bash command
 */
function extractFileReferences(command) {
  if (!command) return [];
  
  const files = new Set();
  
  // Pattern 1: Command with file argument
  // Examples: cat .env, grep foo .env, vim .env
  const commandPattern = new RegExp(
    `(?:${FILE_READ_COMMANDS.join('|')})\\s+(?:(?:-[a-zA-Z0-9]+)\\s+)*([^\\s;|&><]+)`,
    'g'
  );
  let match;
  while ((match = commandPattern.exec(command)) !== null) {
    files.add(match[1]);
  }
  
  // Pattern 2: Redirection operators
  // Examples: < .env, > .env, >> .env
  const redirectPattern = /(?:<|>|>>)\s*([^\s;|&><]+)/g;
  while ((match = redirectPattern.exec(command)) !== null) {
    files.add(match[1]);
  }
  
  // Pattern 3: Process substitution
  // Examples: $(cat .env), `cat .env`
  const processSubPattern = /(?:\$\(|`)\s*(?:cat|head|tail)\s+([^\s;|&><)]+)/g;
  while ((match = processSubPattern.exec(command)) !== null) {
    files.add(match[1]);
  }
  
  // Pattern 4: Variable assignment followed by usage
  // Examples: FILE=.env; cat $FILE
  const varPattern = /(\w+)=([^\s;|&]+)/g;
  const vars = {};
  while ((match = varPattern.exec(command)) !== null) {
    vars[match[1]] = match[2];
  }
  
  // Check if any variable references a file
  for (const [varName, value] of Object.entries(vars)) {
    if (isSensitiveFile(value)) {
      files.add(value);
    }
  }
  
  // Pattern 5: Git operations on files
  // Examples: git diff .env, git show HEAD:.env
  const gitPattern = /git\s+(?:diff|show|cat-file)\s+(?:[^\s]+\s+)?([^\s;|&]+)/g;
  while ((match = gitPattern.exec(command)) !== null) {
    const file = match[1].replace(/^HEAD:/, '');
    files.add(file);
  }
  
  // Pattern 6: Script execution with file reference
  // Examples: python -c "open('.env')", node -e "fs.readFileSync('.env')"
  const scriptPattern = new RegExp(
    `(?:${SCRIPT_INTERPRETERS.join('|')})\\s+(?:-[ce]\\s+)?["\'].*?([^"'\\/\\s]+\\.env[^"']*)`,
    'g'
  );
  while ((match = scriptPattern.exec(command)) !== null) {
    files.add(match[1]);
  }
  
  // Pattern 7: Wildcards
  // Examples: *.env, .env*
  const wildcardPattern = /([^\s;|&><]*\*[^\s;|&><]*\.env[^\s;|&><]*|\.env[^\s;|&><]*\*[^\s;|&><]*)/g;
  while ((match = wildcardPattern.exec(command)) !== null) {
    files.add(match[1]);
  }
  
  // Pattern 8: Quoted file paths
  const quotedPattern = /["']([^"']*\.env[^"']*)["']/g;
  while ((match = quotedPattern.exec(command)) !== null) {
    files.add(match[1]);
  }
  
  return Array.from(files);
}

/**
 * Check if a bash command attempts to access sensitive files
 */
function containsSensitiveFileAccess(command) {
  if (!command) return false;
  
  // Extract all potential file references
  const fileReferences = extractFileReferences(command);
  
  // Check if any reference is to a sensitive file
  return fileReferences.some(ref => {
    // Remove quotes if present
    const cleanRef = ref.replace(/^["']|["']$/g, '');
    return isSensitiveFile(cleanRef) && !isWhitelisted(cleanRef);
  });
}

/**
 * Check if command uses dangerous patterns
 */
function hasDangerousPattern(command) {
  if (!command) return false;
  
  // Check for script interpreters with inline code that might read files
  const dangerousPatterns = [
    /python.*-c.*open\s*\(/i,
    /node.*-e.*readFile/i,
    /ruby.*-e.*File\.read/i,
    /perl.*-e.*open/i,
    /bash.*-c.*cat/i,
    /sh.*-c.*cat/i,
  ];
  
  return dangerousPatterns.some(pattern => pattern.test(command));
}

// ============================================================================
// ERROR MESSAGES
// ============================================================================

function generateBlockedMessage(filePath, operation, tool) {
  return `🚫 **Sensitive file access blocked**

Access to sensitive files is completely blocked for security.

**Blocked file:** ${filePath || 'sensitive file'}
**Operation:** ${operation} ${tool ? `(${tool})` : ''}

**Why this is blocked:**
This file likely contains secrets, credentials, or sensitive configuration.
AI assistants should NEVER have access to:
- Passwords, API keys, tokens
- Private keys, certificates  
- Production credentials
- Database connection strings
- SAML/OAuth secrets

**What you can do:**
1. Use .env.example or template files instead
2. Provide specific values manually when needed
3. Store secrets in a secure vault (1Password, AWS Secrets Manager)
4. Reference documentation instead of reading actual config
5. Ask the user to manually edit sensitive files

**To override (NOT RECOMMENDED):**
Edit ~/.config/opencode/plugin/protect-sensitive-files.js
Set ENABLED = false (⚠️  you will be exposing secrets!)
`;
}

// ============================================================================
// MAIN PLUGIN EXPORT
// ============================================================================

export default async (ctx) => {
  if (!ENABLED) {
    return {};
  }

  return {
    // Hook into tool execution BEFORE it runs
    "tool.execute.before": async (input, output) => {
      const { tool } = input;
      const { args } = output;

      // ====================================================================
      // BLOCK FILE READ TOOLS
      // ====================================================================
      if (FILE_READ_TOOLS.includes(tool)) {
        const filePaths = [
          args?.filePath,
          args?.path,
          args?.file_path,
          args?.pattern,
          ...(args?.paths || []),
        ].filter(Boolean);

        for (const path of filePaths) {
          if (isSensitiveFile(path) && !isWhitelisted(path)) {
            throw new Error(generateBlockedMessage(path, 'read', tool));
          }
        }
      }

      // ====================================================================
      // BLOCK FILE WRITE TOOLS
      // ====================================================================
      if (FILE_WRITE_TOOLS.includes(tool)) {
        const filePaths = [
          args?.filePath,
          ...(args?.edits?.map(e => e.filePath) || []),
        ].filter(Boolean);

        for (const path of filePaths) {
          if (isSensitiveFile(path) && !isWhitelisted(path)) {
            throw new Error(generateBlockedMessage(path, 'write', tool));
          }
        }
      }

      // ====================================================================
      // BLOCK BASH COMMANDS
      // ====================================================================
      if (tool === 'bash') {
        const command = args?.command;
        
        if (command) {
          // Check for sensitive file access
          if (containsSensitiveFileAccess(command)) {
            const files = extractFileReferences(command);
            const sensitiveFiles = files.filter(f => 
              isSensitiveFile(f) && !isWhitelisted(f)
            );
            
            throw new Error(generateBlockedMessage(
              sensitiveFiles[0] || 'sensitive file',
              'bash command',
              'bash'
            ));
          }
          
          // Check for dangerous patterns (script execution)
          if (hasDangerousPattern(command)) {
            throw new Error(generateBlockedMessage(
              'potentially sensitive file',
              'script execution',
              'bash'
            ));
          }
        }
      }

      // ====================================================================
      // BLOCK AST_GREP (could search sensitive content)
      // ====================================================================
      if (tool === 'ast_grep_search') {
        const paths = args?.paths || [];
        for (const path of paths) {
          if (isSensitiveFile(path) && !isWhitelisted(path)) {
            throw new Error(generateBlockedMessage(path, 'ast search', tool));
          }
        }
      }
    },
  };
};
