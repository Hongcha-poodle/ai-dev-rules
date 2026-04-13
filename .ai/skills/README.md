# AI Skills

Custom skills and extensions. Referenced by `core.md` §6 Context Loading.

## Adding a skill

Preferred structure:

```text
.ai/skills/
  {skill-name}/
    SKILL.md
    references/
    scripts/
    assets/
```

For very small skills, a single `{skill-name}.md` file is also acceptable.

1. Create `.ai/skills/{skill-name}/SKILL.md`.
2. Follow this structure:

```markdown
# Skill Name

## Purpose
- Problem this skill solves

## Trigger
- Auto-load condition (e.g. "on security review request")

## Capabilities
- Key features

## Usage
- Example scenarios

## Constraints
- Known limitations
```

3. Use `references/` for bulky decision guides, templates, and examples.
4. Use `scripts/` for deterministic repeated actions that the agent should run instead of retyping.
5. See `@.ai/rules/development/agent-authoring.md` for detailed authoring guide.

## Bundled Skill Pattern

Use a bundled skill when:
- The workflow needs Progressive Disclosure
- The skill ships templates or examples
- The skill needs reusable scripts
- The skill has more than one or two decision branches

Example:

```text
.ai/skills/my-skill/
  SKILL.md
  templates/
    starter.md
  references/
    decision-guide.md
```
