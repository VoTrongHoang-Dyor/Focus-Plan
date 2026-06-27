# 📬 Email-Summary Skill

Summarize a **Gmail** inbox into a **professional summary table** you can read in 60 seconds.

The skill reads emails within the scope you request, classifies them by priority and required action, **handles sensitive/confidential emails discreetly**, then outputs a compact table plus a suggested action list. Read-only by default — it never sends, deletes, or labels without your confirmation.

## Key Features

- **At-a-glance table** — who sent it, what it's about, how urgent, what to do, and when it's due.
- **Priority scoring** — classify 🔴 Urgent / 🟠 To handle / 🟡 Waiting / 🟢 FYI / ⚪ Skim, applying 20/80 to push urgent items to the top.
- **Sensitive-info protection** — salary, contract, OTP, and personal-data emails are flagged 🔒 and their confidential details are kept out of the table.
- **To-do list** — pulled straight from the table with the person involved and the deadline.
- **Next actions** — draft replies, label, or archive skippable emails (always asks for confirmation first).

## Requirements

⚠️ The skill needs the **Gmail connector** enabled in Claude. Enable it at **Settings → Connectors → Gmail → Connect** and grant read access. If it is not connected, the skill will guide you to enable it before running.

## How to Trigger

Ask Claude with phrases like: *"summarize my email"*, *"summarize my inbox"*, *"unread emails today"*, *"what's in my inbox"*, *"catch me up on email"*…

## Configure Before Use

Open the skill file (`Skill/[ # email-summary ].md`) and edit the **⚙️ CONFIGURATION** block at the top if needed:

- `default_scope` — the default Gmail query when you are not specific (default: last 7 days in inbox).
- `email_limit` — max emails to scan per run.
- `output_language` — the language of the summary table (default: `English`).
- `timezone` — used to interpret "today", "this week".
- `filter_sensitive` / `hide_secret_details` — toggle discreet handling of sensitive emails.
