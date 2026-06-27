---
name: email-summary
description: >
  Summarize a Gmail inbox into a **professional summary table**: read emails within the
  requested scope, classify them by priority & required action, handle sensitive/confidential
  emails discreetly, then output a table plus a suggested action list.

  Trigger AS SOON AS the user asks for any of the following:
  - "summarize email", "summarize inbox", "summarize gmail", "email summary", "inbox summary"
  - "what's in my inbox", "round up my emails", "read my emails for me", "email summary table"
  - "emails today", "emails this week", "unread emails", "check mail", "catch me up on email"
  - the user wants to grasp many emails quickly without reading each one

  This skill REQUIRES the Gmail connector enabled in Claude (Settings → Connectors → Gmail).
  If it is not connected, guide the user to enable it before running.
---

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- ⚙️ CONFIGURATION — edit this block only -->
<!-- ════════════════════════════════════════════════════════════════ -->

## ⚙️ CONFIGURATION

> The engine below reads from this block. Edit only this block; do not touch the ENGINE.

```yaml
default_scope:    "newer_than:7d in:inbox"  # default Gmail query when the user is not specific
email_limit:      25                         # max emails to scan per run (avoid overload)
timezone:         "Asia/Ho_Chi_Minh"         # used to interpret "today", "this week"
output_language:  "English"                  # language of the summary table
filter_sensitive: true                       # true = handle sensitive emails discreetly (see Step 4)
hide_secret_details: true                    # true = table shows a neutral title for confidential emails, no contents
```

<!-- ════════════ END CONFIGURATION — the ENGINE below, DO NOT EDIT ════════════ -->

# Skill: Email Summary → Professional Summary Table

## Objective

Turn a full inbox into **a summary table you can read in 60 seconds**: who sent it, what it's about, how urgent, and what you need to do. Prioritize accuracy and discretion — sensitive emails are handled carefully, and content is never fabricated.

---

## Step 0: Check the Gmail connection (MANDATORY — run first)

1. Try a light query through the Gmail connector (e.g. list labels or fetch the most recent thread).
2. **If the connector is off / permission fails:** stop and guide the user:
   > "This skill needs the Gmail connector. Please enable it at **Settings → Connectors → Gmail → Connect**, grant read access, then call me again."
3. Never fabricate email content when you cannot access the real inbox.

---

## Step 1: Define the scan scope

If the user has already specified a scope (e.g. "unread emails today", "mail from my boss this week") → use it, do NOT ask further.

If unclear, ask at most 1 concise question to pin down the scope, offering ready-made options:
- Time range (today / 7 days / custom)
- Unread only, or all?
- Filter by a specific sender / label?

When nothing is specified, use `default_scope` from the configuration block.

**Translate the request into a Gmail query** (Gmail search syntax):
| User says | Gmail query |
|---|---|
| unread emails | `is:unread in:inbox` |
| emails today | `newer_than:1d in:inbox` |
| this week | `newer_than:7d in:inbox` |
| from a person | `from:name@email.com` |
| important | `is:important` |
| with attachments | `has:attachment` |

Cap the number of threads fetched by `email_limit`. If results exceed it, prioritize `is:unread` and `is:important` first, and tell the user how many remain unscanned.

---

## Step 2: Read and extract content

For each thread in scope:
1. Fetch the thread content (sender, subject, time, main body, latest message in the chain).
2. Extract the **3 core elements**, without copying long verbatim text:
   - **Main point:** what this thread is about (1 sentence).
   - **Request/action:** does the sender need you to do something, or is it just an FYI?
   - **Timing:** is there a deadline / meeting date / reply-by date?
3. For multi-email chains, summarize the **current state**, not the whole history.

> Honesty principle: only summarize what is actually in the email. Do not infer deadlines, amounts, or commitments that are not explicitly stated.

---

## Step 3: Classify & score priority

Assign each email a **priority level** based on sender, urgency keywords, and deadline:

| Level | When | Marker |
|---|---|---|
| Urgent / act now | near-term deadline, direct request, important sender | 🔴 High |
| Needs handling | has an action but not urgent | 🟠 Medium |
| Follow-up / waiting | you are waiting on someone else's reply | 🟡 Waiting |
| Information / FYI | for awareness only, no action needed | 🟢 FYI |
| Skippable | newsletters, ads, automated | ⚪ Skim |

Apply **20/80**: identify the 2-3 "top 20%" emails and push them to the top of the table.

---

## Step 4: Handle sensitive/confidential emails (when `filter_sensitive: true`)

Some emails carry sensitive information: finance/salary, legal/contracts, passwords/OTP, personal data, internal "confidential" notes.

When such an email is detected:
- **Flag it 🔒** in the corresponding column of the table.
- If `hide_secret_details: true` → the table shows only a **neutral title** (e.g. *"Monthly salary info — review privately"*), and does NOT spread figures/passwords/terms into the table. Invite the user to open the email directly for details.
- **Never** repeat OTP codes, passwords, or card numbers in the summary.
- Do not send/share email content to any external channel.

> If the connector supports Gmail's sensitivity labels, you may suggest the user apply a label so Claude handles it discreetly next time.

---

## Step 5: Output the summary table

Present the result in exactly the frame below.

```
# 📬 Inbox Summary — [scope] · [dd/MM/yyyy]
> Scanned [N] emails · 🔴 [x] urgent · 🟠 [y] to handle · 🟡 [z] waiting
> ⚡ Top 20%: [1-3 most urgent emails]

| # | Priority | Sender | Subject | Summary & action needed | Deadline | 🔒 |
|---|----------|--------|---------|-------------------------|----------|----|
| 1 | 🔴 High | [name] | [subject] | [1 sentence of content + action] | [date/—] | |
| 2 | 🟠 Med | ... | ... | ... | ... | 🔒 |
| ... | | | | | | |

## ✅ To-do (pulled from the table, ranked by priority)
- [ ] 🔴 [action] — [person involved] — due [date]
- [ ] 🟠 [action] — ...

## 🕊 Can skip / archive
- [group newsletters, ads, automated notices — just count them]
```

Table requirements:
- The **Summary & action needed** column stays concise (≤ 2 sentences), stating clearly *who needs you to do what*.
- 🔒 emails follow the Step 4 rules.
- If the scope is empty (no emails): report "No emails match [scope]" instead of producing an empty table.

---

## Step 6: Next actions

After the table, briefly ask whether the user wants to:
- Draft a **reply** for the 1-2 most urgent emails (create a draft only, never auto-send).
- Label / archive the skippable group of emails.
- Dive deeper into a specific email.

> Any write action (sending mail, labeling, deleting) MUST be confirmed first. By default the skill only reads and summarizes.

---

## Quality Standards

- **Honesty:** only summarize real email content; never fabricate deadlines, figures, or commitments.
- **Discretion:** sensitive emails are flagged 🔒 and their confidential details are not spread into the table.
- **Correct priority:** urgent/action-needed items always rise to the top (apply 20/80).
- **Actionable:** every action email maps to a clear task + person involved + due date.
- **Scannable:** the whole table is understandable in ~60 seconds; each cell is concise.
- **Read-only by default:** do not send/delete/label without confirmation.
- **Language:** follow `output_language` in the configuration; keep proper nouns and original email subjects as-is when needed.
