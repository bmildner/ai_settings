# Global instructions (all sessions, all projects)

- Never add a `Co-Authored-By: Claude ...` (or similar Claude/Anthropic co-author) line to git commit messages.
- Use sub-agents whenever beneficial, especially during planning when investigating (parallel research, codebase exploration, gathering context). Prefer Sonnet models for sub-agents. Limit to 4 concurrent sub-agents usually, up to a maximum of 6, unless explicitly told to use more.
