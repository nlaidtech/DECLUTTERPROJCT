# MCP Configuration for Supabase

## Setup Instructions

### Option 1: VS Code Copilot Extension (Recommended)

1. Open VS Code Settings (Cmd+,)
2. Search for "MCP"
3. Find "GitHub Copilot > MCP: Servers"
4. Add the Supabase MCP server configuration:

```json
{
  "supabase": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-supabase",
      "https://miqbkzkmfkyzpdjyglab.supabase.co",
      "sbp_8151b8b6c28cda7121e7f1ae9cacefc894d5bfb8"
    ]
  }
}
```

### Option 2: Global MCP Settings

Add to your global MCP settings file:

**Location:** `~/Library/Application Support/Code/User/globalStorage/github.copilot-chat/mcp.json`

Or for Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`

### Option 3: Project-specific (Created)

I've created `.vscode/mcp.json` in this project with your Supabase credentials.

## After Configuration

1. **Restart VS Code** or reload the window (Cmd+Shift+P → "Reload Window")
2. The Supabase MCP tools should become available in the next chat session
3. You'll be able to:
   - Query database tables
   - Run SQL commands
   - Manage storage buckets
   - View database schema
   - Execute migrations

## Verify MCP is Working

After restart, ask me to:
- "List all tables in my Supabase database"
- "Show me the schema for the profiles table"
- "Run a query on posts table"

If MCP is configured correctly, I'll have access to Supabase-specific tools.

## Security Note

The `.vscode/mcp.json` file contains your access token. Make sure it's gitignored!

## Troubleshooting

If MCP doesn't load:
1. Make sure you have Node.js installed
2. Check VS Code Copilot extension is up to date
3. Look at VS Code Output panel (View → Output → GitHub Copilot)
4. Try running manually: `npx -y @modelcontextprotocol/server-supabase --help`
