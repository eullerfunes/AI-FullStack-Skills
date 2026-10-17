# Install — Kilo Code Agent Skills

This library installs agent skills into Kilo Code so they are available as `container.skills` in the Claude API Messages Agent Skills surface.

## Prerequisites

- Kilo Code (CLI or extension) with Agent Skills support
- Git

## One-time install

Clone this repository:

```bash
git clone https://github.com/eullerfunes/AI-FullStack-Skills.git
cd AI-FullStack-Skills
```

Then point Kilo Code at the `skills/` directory. The exact mechanism depends on your Kilo Code host:

- **Kilo Code CLI:** add the `skills/` folder to your project's skill path (see your host's `CLAUDE.md` / skill configuration).
- **Managed worktree:** each `skills/<category>/<origin>/<skill>/SKILL.md` is a standalone skill directory; copy or symlink the ones you need into `~/.claude/skills/` (or your host's skills directory).

## Selective install

You do not need all 191 skills. Pick by category or origin:

```bash
# Example: only security + qa skills
cp -r skills/security skills/qa ~/.claude/skills/
```

## Verify

After install, confirm each skill directory contains a valid `SKILL.md` with frontmatter (`name`, `description`, `metadata.author`, `metadata.version`).

## Uninstall

Remove the `skills/` directory (or the specific skill subdirectories you copied) from your Kilo Code skills path.
