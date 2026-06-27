# 🗓️ Plan-My-Day — Daily planning skill → Google Calendar

This skill plans **your day today** based on YOUR weekly schedule, then pushes it to Google Calendar via an interactive Artifact. The skill is designed to be **personalized by each user** — you only paste your weekly schedule into one single place.

## ⚡ Setup in 4 steps

### Step 1 — Generate your weekly schedule
Copy the prompt below, paste it into Claude (or any AI), fill in your **main goal**, and grab the JSON it returns:

```
# Goal
Create a weekly study and work plan.

## User info
**Main goal:** ____________________
**Special requirements (optional):** ____________________

## Requirements
Based on the user's goal:
- Build a schedule from Monday to Sunday.
- Each day has one main focus.
- For Monday through Saturday, propose suitable skill blocks (name + duration).
- Sunday is review and active rest only.
- If information is missing, ask back.
- Return only JSON matching this schema:

{
  "week": {
    "Monday": {
      "focus": "...",
      "blocks": [
        { "name": "...", "duration": "2–3h" },
        { "name": "...", "duration": "45m" }
      ]
    }
  }
}
```

### Step 2 — Paste the JSON into the skill
Open `Skill/[ # plan-my-day ].md`, find the **`## ⚙️ PERSONAL CONFIGURATION` → `### 1. Weekly schedule`** block, and paste the JSON you received over the sample JSON.

### Step 3 — Adjust settings (optional)
Still in the `## ⚙️ PERSONAL CONFIGURATION` block, under `### 2. Personal settings`, edit if needed:
- `day_window` — your day start/end time (default `07:00–22:00`).
- `timezone` — Google Calendar timezone (default `Asia/Ho_Chi_Minh`).
- `output_language` — language of the schedule text & Artifact UI (default `English`).
- `google_client_id` — to push to Calendar; see `Skill/references/gcal-setup.md`. Leave empty if you only want a `.ics` file.

### Step 4 — Use it
Type `/plan-my-day` (or "plan my day"). The skill reads your weekly schedule, builds today's timeline (auto-adding breaks/meals), and creates an Artifact to push to Google Calendar.

## ❓ Notes
- You only edit the **`## ⚙️ PERSONAL CONFIGURATION` block** — the ENGINE below stays untouched.
- If the JSON is missing today, the skill asks back instead of inventing one.
- Breaks, lunch, and wind-down are added by the skill automatically — NO need to declare them in the JSON.
- To push directly to Google Calendar you need a Google connection (OAuth Client ID) — see `Skill/references/gcal-setup.md`.
