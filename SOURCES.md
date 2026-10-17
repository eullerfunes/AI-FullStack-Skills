# Sources — Skill provenance and licenses

This library imports agent skills from the following upstream repositories. Each skill retains its original license; this repository does not relicense imported code.

| # | Origin | Repository | License | Notes |
|---|--------|------------|---------|-------|
| 1 | vercel-labs-agent-skills | vercel-labs/agent-skills | MIT | `skills/<name>/SKILL.md` |
| 2 | supabase-agent-skills | supabase/agent-skills | — | `skills/<name>/SKILL.md` |
| 3 | obra-superpowers | obra/superpowers | — | `skills/<name>/SKILL.md` |
| 4 | microsoft-playwright-cli | microsoft/playwright-cli | — | `skills/playwright-cli/SKILL.md` |
| 5 | anthropics-skills | anthropics/skills | — | `skills/<name>/SKILL.md` |
| 6 | getsentry-skills | getsentry/skills | — | `skills/<name>/SKILL.md` |
| 7 | getsentry-sentry-for-ai | getsentry/sentry-for-ai | Apache-2.0 | `skills-legacy/<sdk>/SKILL.md` (SDK skills) |
| 8 | trailofbits-skills | trailofbits/skills | CC BY-SA 4.0 | `plugins/<plugin>/skills/<skill>/`; preserve attribution |
| 9 | nextlevelbuilder-ui-ux-pro-max-skill | nextlevelbuilder/ui-ux-pro-max | MIT | `skill.json` platform listing; `.claude/skills/<name>/` |

## Duplicate skill names

The following skill names appear in more than one origin and are kept under their origin prefix to avoid collisions:

- `brand-guidelines` — anthropics-skills, getsentry-skills
- `doc-coauthoring` — anthropics-skills, getsentry-skills

## Import layout

Skills are copied verbatim into:

```
skills/<category>/<origin>/<skill>/
```

No source code is executed during import. Only `SKILL.md` (and accompanying assets) are copied.

## Attribution

- Trail of Bits skills are CC BY-SA 4.0: keep the plugin source attribution when redistributing.
- Sentry for AI SDK skills are Apache-2.0.
- NextLevelBuilder, Vercel Labs skills are MIT.
