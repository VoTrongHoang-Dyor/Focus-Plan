# 🧩 Claude Skills Collection

A set of personal, production-ready **[Claude](https://claude.com/claude-code) skills** that turn everyday knowledge work into one-command workflows. Each skill is self-contained, fully configurable, and outputs in the language you choose.

## The Skills

| Skill | What it does | Needs |
|-------|--------------|-------|
| 📊 **[News-Report](News-Report/)** | Generates an expert-level strategic global macro & financial report — dashboard, 20 key insights, impact map, 5 asset classes, historical comparison, and a 7-day forecast. | Web search |
| 📬 **[Email-Summary](Email-Summary/)** | Summarizes a Gmail inbox into a professional summary table with priority scoring, an action list, and discreet handling of sensitive emails. | Gmail connector |
| 🗓️ **[Plans-My-Day](Plans-My-Day/)** | Builds a realistic, time-blocked daily schedule from your weekly plan and pushes it to Google Calendar via an interactive Artifact. | Google Calendar (OAuth) |

## Design Conventions

All three skills follow the same structure, so they are easy to read, fork, and personalize:

- **`README.md`** — a short, user-facing introduction (features, triggers, setup).
- **`Skill/[ # <name> ].md`** — the skill itself: YAML frontmatter (`name` + trigger `description`), a **⚙️ CONFIGURATION** block you edit, and the ENGINE you leave untouched.
- **`output_language`** — every skill exposes this config field (default `English`) so you can switch the output language without touching the engine.

## How to Use

1. **Install** — place a skill folder where your Claude runtime discovers skills (e.g. your skills directory), or invoke it by name.
2. **Configure** — open the skill's `Skill/[ # <name> ].md` and edit only the **⚙️ CONFIGURATION** block (folder names, timezone, output language, connector IDs…).
3. **Connect** — enable the required connector for skills that need one (Gmail, Google Calendar). See each skill's README.
4. **Trigger** — ask Claude in natural language (e.g. *"market update"*, *"summarize my inbox"*, *"plan my day"*) and the matching skill activates.

## Repository Layout

```text
skills/
├── README.md            ← you are here
├── News-Report/         ← strategic financial report generator
├── Email-Summary/       ← Gmail inbox → summary table
└── Plans-My-Day/        ← daily schedule → Google Calendar
```

## License

These skills are shared as-is for personal use and adaptation.
