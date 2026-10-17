# AI-FullStack-Skills

Personal Agent Skills library for [Kilo Code](https://kilo.ai), organized by category and provenance.

## Structure

```
skills/<category>/<origin>/<skill>/SKILL.md
```

| Category | Skills |
|----------|--------|
| agents | 8 |
| backend | 30 |
| database | 2 |
| devops | 10 |
| frontend | 17 |
| qa | 27 |
| security | 70 |
| tools | 27 |
| **Total** | **191** |

Origins imported:
- `vercel-labs-agent-skills` — Vercel Labs agent skills (MIT)
- `supabase-agent-skills` — Supabase agent skills
- `obra-superpowers` — OBRA agent superpowers
- `microsoft-playwright-cli` — Playwright CLI QA skill
- `anthropics-skills` — Anthropic agent skills
- `getsentry-skills` — Sentry agent skills
- `getsentry-sentry-for-ai` — Sentry for AI SDK skills (Apache-2.0)
- `trailofbits-skills` — Trail of Bits security plugins (CC BY-SA 4.0)
- `nextlevelbuilder-ui-ux-pro-max-skill` — NextLevelBuilder UI/UX (MIT)

See [SOURCES.md](SOURCES.md) for full provenance and licenses.

## Central catalog

`CATALOG.json` lists every skill with `id`, `name`, `description`, `category`, `origin`, `skill`, `invocation_name`, `path`, `author`, `version`, and `license`.

- `id`: full identifier in the form `origin/skill`.
- `name`: short name as declared in the catalog (usually matches `skill`).
- `invocation_name`: name extracted from the frontmatter `name` of the skill's `SKILL.md`; this is the name used to invoke the skill in Kilo Code. It may differ from `skill` (the directory name).
- `skill`: directory name used as the installation destination.
- `path`: relative path to the skill's `SKILL.md` inside `skills/`.

## Install

See [INSTALL.md](INSTALL.md) for the Kilo Code install/update procedure.

## Update

See [UPDATE.md](UPDATE.md) for how to refresh skills from their upstream sources.

## License

Each skill retains its original license (see SOURCES.md). This repository does not relicense imported skills.
