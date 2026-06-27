---
name: plan-my-day
description: >
  Build a concrete, realistic, balanced one-day schedule, then **automatically push it all to
  Google Calendar** via an interactive React Artifact. The user logs into Google once, after which
  every time block is created as a Calendar event within seconds.

  Trigger AS SOON AS the user asks for any of the following:
  - "plan my day", "plan today", "today's schedule", "make a plan for today"
  - "I need to organize my work today", "help me plan"
  - "what should I do today", "arrange my time today"
  - "create google calendar events", "put it on my calendar", "sync my calendar"
  - the user lists tasks or goals and wants them organized into a time-blocked schedule
  - "schedule", "daily plan", "time block", "push to calendar"
  - any request combining a task list + time allocation + a calendar mention

  This is a fully integrated skill: do NOT just show a text schedule — ALWAYS create an Artifact
  so the user can push to Google Calendar.
---

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- ⚙️ MY WEEKLY SCHEDULE — PASTE JSON HERE (the user edits only this block) -->
<!-- ════════════════════════════════════════════════════════════════ -->

## ⚙️ PERSONAL CONFIGURATION

> The engine below READS from this block. The user edits only this block; do not touch the ENGINE.

### 1. Weekly schedule — paste the JSON output from the README prompt here

```json
{
  "week": {
    "Monday": {
      "focus": "Coding + AI Agent",
      "blocks": [
        { "name": "Build product/Portfolio", "duration": "2–3h" },
        { "name": "Daily Coding Sprint", "duration": "60m" },
        { "name": "AI Agent & Automation", "duration": "45m" },
        { "name": "English", "duration": "45–60m" },
        { "name": "Tech news", "duration": "≤30m" }
      ]
    }
  }
}
```

> 👆 This is sample JSON for one day only. Replace it with your full Monday → Sunday JSON.

### 2. Personal settings — edit if different from defaults

```yaml
day_window:        "07:00–22:00"          # your day start–end time
timezone:          "Asia/Ho_Chi_Minh"     # timezone for Google Calendar
output_language:   "English"              # language of the schedule text & Artifact UI
google_client_id:  "PASTE_YOUR_CLIENT_ID" # see references/gcal-setup.md (leave empty = .ics only)
block_colors:      "default"              # keep "default" or map your task groups → Google colorId
```

<!-- ════════════ END CONFIGURATION — the ENGINE below, DO NOT EDIT ════════════ -->

# Skill: Plan My Day → Google Calendar

## Objective

Turn a raw list of tasks and goals into a feasible daily schedule, then **push it automatically to Google Calendar** via an interactive React Artifact — no manual copy-paste.

---

## Step 1: Gather information

If the user hasn't provided enough, ask at most 2 questions (not all at once):

1. **What day/date is today?** (to apply the right template and create events on the right date)
2. **Any deadlines, fixed meetings, or special tasks today?**
3. Day start/end time if different from the default (07:00–22:00)

If the user already provided enough context → go straight to the schedule, ask nothing more.

---

## Step 2: Design the schedule

### Pareto 80/20 principle
- **20% of time produces 80% of results**: morning deep work (building the product, coding, client work)
- The other 80%: skill learning, maintenance, rest, admin

### Time-blocking
- 45–90 minute blocks, one task per block (no multitasking)
- 10–15 minute buffer between blocks
- At most 4–5 deep work blocks/day
- Always keep 60–90 minutes of unnamed buffer in the day

### Energy allocation
- **Morning (07–12)**: high-cognitive deep work → building the product, coding
- **Afternoon (13–17)**: lower energy → learning, communication, admin
- **Evening (18–21)**: light → learning/maintaining skills, day wrap-up

### Mandatory in every day's schedule
- ☕ Morning warm-up: 15–20 minutes (no social media)
- 🍚 Lunch: 60 minutes (no work)
- ☕ Afternoon break: 20–30 minutes (no screens)
- 🚶 Light movement: walking or stretching
- 🌙 Wind-down: 20–30 minutes before sleep

### Read today's schedule from the configuration
1. Determine **what day of the week today is** (by the real date / the user's answer).
2. Take `week["<Day>"]` from the `## ⚙️ PERSONAL CONFIGURATION` block:
   - `focus` → "🎯 Today's goal".
   - `blocks[]` → the list of tasks to place (each block has `name` + `duration`).
3. **If the JSON does NOT have today** (e.g. the user has only filled in Monday): ask gently
   *"The config has no schedule for [Day] — want me to propose one based on the nearest focus, or will you paste this day into the config block?"* — do NOT invent a schedule.

### The engine auto-inserts mandatory blocks
The user does NOT declare breaks/meals in the JSON — the engine adds them to every day's schedule:
morning warm-up, lunch, afternoon break, light movement, wind-down (per the "Mandatory in every day's schedule" section above).

### Lay blocks into the time window
- Use `day_window` in the config block (default `07:00–22:00`) as the day's start/end markers.
- Parse `duration`: supports `h`/`m` and ranges with `–` (e.g. `"2–3h"`, `"45–60m"`, `"≤30m"`). For a range, pick a sensible value based on remaining time in the day.
- Apply the energy-allocation principle: heavy/deep work in the morning, light/maintenance work in the evening.

### Reason out a detailed lesson for each block (MANDATORY)
Do NOT leave a block as a bare name. For EACH block in `blocks[]`, reason out a specific study/work session **anchored to the day's `focus`**, with 3 parts:
- **🎯 Session goal:** 1 sentence, a measurable result after the block (e.g. *"Understand and write async/await in Python myself"*).
- **🧩 Mini-tasks (split by minutes):** 2–4 small steps that fill exactly the `duration`. Example for block `"English" – 45m` on a *"Coding + AI Agent"* focus day:
  - `15'` read one English tech/AI blog post related to today's focus
  - `20'` note 10 new technical vocab words + write 3 sentences using them
  - `10'` shadow a short audio clip
- **✅ Output:** a small proof it's done (a note, commit, written passage, screenshot).

Reasoning rules:
- Mini-task content must **serve today's `focus`**, not be generic. For a language/reading block → tie the topic to the focus (on a "Coding + AI Agent" day, the English material is tech/AI).
- This entire section goes into the Google Calendar event `description` (Step 4) — open the calendar and know exactly what to do.

### Apply 20/80: prioritize & protect high-value blocks
1. **Classify** each block:
   - 🔴 **High-value (20% → 80% of results):** building the product/portfolio, deep work, coding, client work.
   - ⚪ **Maintenance/secondary (80% of time → 20% of results):** reading news, browsing, admin, light maintenance.
2. **Place 🔴 blocks in the golden hours** — the highest-energy morning (per `day_window`), scheduled BEFORE the rest.
3. **Tag with `⚡`** right before the 🔴 block name in the text schedule and in the Artifact event title.
4. **Protect:** when the day runs short, do NOT cut ⚡ blocks; only shorten/cut ⚪ blocks — and briefly explain why.
5. The schedule always opens with: **`⚡ Today's vital 20%:` [list 1–2 🔴 blocks]**.

---

## Step 3: Output the text schedule

Before creating the Artifact, show the schedule as a table for preview:

```
# 📅 Schedule for [Day] — [dd/MM/yyyy]
## 🎯 Today's goal: [focus + 1–2 sentences]
## ⚡ Today's vital 20%: [1–2 high-value 🔴 blocks]

| Time | Block | 🎯 Goal & mini-tasks | Priority |
|------|-------|----------------------|----------|
| 07:00–07:20 | 🌅 Warm-up | Review the day's goals, no social media | |
| 07:20–09:30 | ⚡ 🔨 [High-value block] | [session goal] · [mini-tasks by minute] | 🔴 |
| 09:45–10:30 | 📖 [Learning block] | [session goal] · [mini-tasks] | ⚪ |
| ... | | | |

> Each "Goal & mini-tasks" cell comes from the *detailed lesson reasoning* in Step 2 — it is the `description` pushed to Calendar.

## ✅ Checklist (generated from today's blocks)
[ ] ⚡ [🔴 block name] — [session goal]
[ ] [next block name] — [session goal]
[ ] ... (one line per block in `blocks[]`)
[ ] 🌙 Day wrap-up — record the output achieved
```

---

## Step 4: Create the React Artifact — Google Calendar Pusher

After showing the text schedule, **ALWAYS create a React Artifact** with all the features below.

### Artifact structure

The Artifact is a React app with 3 tabs:

**Tab 1 — View schedule**: shows the schedule as a visual timeline with colors by block type.

**Tab 2 — Edit**: an editable list of events (name, start time, end time, description, color).

**Tab 3 — Push to Calendar**: a "Connect Google" button + a "Create all events" button after auth.

### Block colors (Google Calendar colorId)

Map by **block type** (classify the user's block name into a type). 🔴 high-value blocks always use the Deep Work color to stand out:

```
🔴 Deep work / build product / main project  → colorId: "11" (Tomato/red)
🔨 Coding / technical practice               → colorId: "6"  (Tangerine/orange)
🤖 AI / automation / research                → colorId: "9"  (Blueberry/dark blue)
💼 Client / freelance / outside work          → colorId: "2"  (Sage/green)
📖 Language learning / reading docs          → colorId: "5"  (Banana/yellow)
🧩 Other skill learning/maintenance          → colorId: "3"  (Grape/purple)
☕ Rest / break / meal                        → colorId: "8"  (Graphite/gray)
🌙 Wrap-up / wind-down                        → colorId: "7"  (Peacock/light blue)
📰 News / low-value secondary task           → colorId: "4"  (Flamingo/light pink)
```

> The user can override this map via `block_colors` in the config block.

### Code template for the Artifact

```jsx
import { useState, useCallback } from "react";

// ===== SCHEDULE DATA (injected by Claude) =====
const SCHEDULE_DATE = "2025-01-15"; // format: YYYY-MM-DD
const EVENTS_DATA = [
  {
    id: 1,
    title: "🌅 Morning warm-up",
    start: "07:00",
    end: "07:20",
    description: "Review the day's goals, no social media",
    colorId: "8",
    category: "break"
  },
  // ... add events from the designed schedule
];

// ===== GOOGLE CALENDAR CONFIG =====
// Client ID from Google Cloud Console (the user must create one or use a demo)
const GOOGLE_CLIENT_ID = "YOUR_CLIENT_ID.apps.googleusercontent.com";
const SCOPES = "https://www.googleapis.com/auth/calendar.events";

export default function CalendarPusher() {
  const [events, setEvents] = useState(EVENTS_DATA);
  const [activeTab, setActiveTab] = useState("preview");
  const [isSignedIn, setIsSignedIn] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [results, setResults] = useState([]);
  const [tokenClient, setTokenClient] = useState(null);
  const [accessToken, setAccessToken] = useState(null);

  // Load Google Identity Services
  const initGoogleAuth = useCallback(() => {
    const script = document.createElement("script");
    script.src = "https://accounts.google.com/gsi/client";
    script.onload = () => {
      const tc = window.google.accounts.oauth2.initTokenClient({
        client_id: GOOGLE_CLIENT_ID,
        scope: SCOPES,
        callback: (response) => {
          if (response.access_token) {
            setAccessToken(response.access_token);
            setIsSignedIn(true);
          }
        },
      });
      setTokenClient(tc);
    };
    document.head.appendChild(script);
  }, []);

  const handleSignIn = () => {
    if (!tokenClient) {
      initGoogleAuth();
      setTimeout(() => tokenClient?.requestAccessToken(), 500);
    } else {
      tokenClient.requestAccessToken();
    }
  };

  // Create an event on Google Calendar
  const createEvent = async (event, token) => {
    const [startH, startM] = event.start.split(":").map(Number);
    const [endH, endM] = event.end.split(":").map(Number);
    
    const startDateTime = new Date(SCHEDULE_DATE);
    startDateTime.setHours(startH, startM, 0);
    
    const endDateTime = new Date(SCHEDULE_DATE);
    endDateTime.setHours(endH, endM, 0);

    const body = {
      summary: event.title,
      description: event.description,
      colorId: event.colorId,
      start: { dateTime: startDateTime.toISOString(), timeZone: "Asia/Ho_Chi_Minh" },
      end: { dateTime: endDateTime.toISOString(), timeZone: "Asia/Ho_Chi_Minh" },
    };

    const response = await fetch(
      "https://www.googleapis.com/calendar/v3/calendars/primary/events",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
      }
    );

    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  };

  const pushAllEvents = async () => {
    setIsLoading(true);
    setResults([]);
    const newResults = [];

    for (const event of events) {
      try {
        await createEvent(event, accessToken);
        newResults.push({ id: event.id, title: event.title, status: "success" });
      } catch (err) {
        newResults.push({ id: event.id, title: event.title, status: "error", error: err.message });
      }
      setResults([...newResults]);
    }
    setIsLoading(false);
  };

  // --- RENDER ---
  return (
    <div style={{ fontFamily: "sans-serif", maxWidth: 700, margin: "0 auto", padding: 20 }}>
      <h2>📅 Schedule → Google Calendar</h2>
      
      {/* Tabs */}
      <div style={{ display: "flex", gap: 8, marginBottom: 20 }}>
        {["preview", "edit", "push"].map(tab => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            style={{
              padding: "8px 16px",
              borderRadius: 8,
              border: "none",
              background: activeTab === tab ? "#4285f4" : "#e8eaed",
              color: activeTab === tab ? "white" : "#333",
              cursor: "pointer",
              fontWeight: activeTab === tab ? "bold" : "normal"
            }}
          >
            {tab === "preview" ? "👁 View" : tab === "edit" ? "✏️ Edit" : "🚀 Push to Calendar"}
          </button>
        ))}
      </div>

      {/* Tab: Preview */}
      {activeTab === "preview" && (
        <div>
          {events.map(ev => (
            <div key={ev.id} style={{
              display: "flex", gap: 12, padding: "10px 14px",
              marginBottom: 6, borderRadius: 8,
              background: getCategoryColor(ev.category),
              alignItems: "center"
            }}>
              <span style={{ fontWeight: "bold", minWidth: 120, fontSize: 13, color: "#555" }}>
                {ev.start} – {ev.end}
              </span>
              <div>
                <div style={{ fontWeight: "bold" }}>{ev.title}</div>
                {ev.description && <div style={{ fontSize: 12, color: "#666" }}>{ev.description}</div>}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Tab: Edit */}
      {activeTab === "edit" && (
        <div>
          {events.map((ev, idx) => (
            <div key={ev.id} style={{ border: "1px solid #ddd", borderRadius: 8, padding: 12, marginBottom: 8 }}>
              <input
                value={ev.title}
                onChange={e => {
                  const updated = [...events];
                  updated[idx] = { ...ev, title: e.target.value };
                  setEvents(updated);
                }}
                style={{ width: "100%", padding: 6, marginBottom: 6, borderRadius: 4, border: "1px solid #ccc" }}
              />
              <div style={{ display: "flex", gap: 8 }}>
                <input type="time" value={ev.start}
                  onChange={e => { const u = [...events]; u[idx] = { ...ev, start: e.target.value }; setEvents(u); }}
                  style={{ padding: 4, borderRadius: 4, border: "1px solid #ccc" }}
                />
                <span style={{ alignSelf: "center" }}>→</span>
                <input type="time" value={ev.end}
                  onChange={e => { const u = [...events]; u[idx] = { ...ev, end: e.target.value }; setEvents(u); }}
                  style={{ padding: 4, borderRadius: 4, border: "1px solid #ccc" }}
                />
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Tab: Push */}
      {activeTab === "push" && (
        <div style={{ textAlign: "center" }}>
          {!isSignedIn ? (
            <div>
              <p style={{ color: "#666", marginBottom: 16 }}>
                Sign in with Google to automatically create {events.length} events on your Calendar.
              </p>
              <button onClick={handleSignIn} style={{
                background: "#4285f4", color: "white", border: "none",
                padding: "12px 24px", borderRadius: 8, fontSize: 16, cursor: "pointer"
              }}>
                🔑 Sign in with Google
              </button>
              <p style={{ fontSize: 12, color: "#999", marginTop: 12 }}>
                Only needs permission to create events — no reading email or other data.
              </p>
            </div>
          ) : (
            <div>
              <p style={{ color: "#2e7d32", marginBottom: 16 }}>✅ Connected to Google</p>
              <button onClick={pushAllEvents} disabled={isLoading} style={{
                background: isLoading ? "#ccc" : "#34a853",
                color: "white", border: "none",
                padding: "12px 24px", borderRadius: 8, fontSize: 16, cursor: isLoading ? "not-allowed" : "pointer"
              }}>
                {isLoading ? "⏳ Creating events..." : `🚀 Create ${events.length} events on Calendar`}
              </button>

              {results.length > 0 && (
                <div style={{ marginTop: 20, textAlign: "left" }}>
                  {results.map(r => (
                    <div key={r.id} style={{ padding: "6px 10px", marginBottom: 4, borderRadius: 6,
                      background: r.status === "success" ? "#e8f5e9" : "#ffebee" }}>
                      {r.status === "success" ? "✅" : "❌"} {r.title}
                    </div>
                  ))}
                  {results.length === events.length && !isLoading && (
                    <p style={{ color: "#1565c0", marginTop: 12, fontWeight: "bold" }}>
                      🎉 Done! Open Google Calendar to see today's schedule.
                    </p>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function getCategoryColor(category) {
  const colors = {
    "deep-work": "#ffebee",
    "coding": "#fff3e0",
    "ai-agent": "#e8eaf6",
    "freelance": "#e8f5e9",
    "english": "#fffde7",
    "chinese": "#f3e5f5",
    "break": "#f5f5f5",
    "review": "#e1f5fe",
    "news": "#fce4ec",
  };
  return colors[category] || "#f9f9f9";
}
```

### Important notes when creating the Artifact

1. **Inject real data**: replace `SCHEDULE_DATE` with today (format `YYYY-MM-DD`) and fill in `EVENTS_DATA` from the schedule designed in Step 2. For each event:
   - `title`: the block name; **prefix `⚡` for high-value blocks (🔴)**.
   - `description`: exactly the **detailed lesson** reasoned in Step 2 (🎯 Session goal + 🧩 Mini-tasks by minute + ✅ Output) — never empty.
   - 🔴 blocks use the Deep Work `colorId` to stand out on Calendar.

2. **Google Client ID**: take the value from `google_client_id` in the `## ⚙️ PERSONAL CONFIGURATION` block and assign it to `GOOGLE_CLIENT_ID`. If the user left it empty → skip the Push tab, show only a "Download .ics" button.

3. **No localStorage**: use React state only.

4. **Timezone**: take it from `timezone` in the config block (default `Asia/Ho_Chi_Minh`) and set it on all events.

5. **ICS fallback**: if the user doesn't want to use the Google API, add a "Download .ics" button for manual import.

6. **Block colors**: if `block_colors = "default"` use the default colorId table above. If the user declared their own group→colorId map, use theirs.

---

## How to get a Google Client ID (shown in the Artifact)

When creating the Artifact, include this short guide or a link to it:

```
To use Google Calendar push:
1. Go to console.cloud.google.com
2. Create a new project (or pick an existing one)
3. APIs & Services → Enable "Google Calendar API"
4. Credentials → Create OAuth 2.0 Client ID → Web Application
5. Authorized JavaScript origins: add https://claude.ai
6. Copy the Client ID → paste it into the Artifact
```

---

## Core principle

**The schedule must be livable, not an ideal on paper.**

- If the user packs in too much → proactively trim it and explain why
- Completing 5/8 blocks well beats forcing 8/8 to exhaustion
- Never schedule deep work for more than 3 continuous hours
- Always have a real break (not a "break" spent checking the phone)

---

## References

- `references/gcal-setup.md` — detailed guide to configuring Google OAuth for the Artifact
- Today's schedule is built from the `## ⚙️ PERSONAL CONFIGURATION` block at the top of this file.
