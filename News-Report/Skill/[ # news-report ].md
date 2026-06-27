---
name: news-report
description: >
  Generate a strategic global macro & financial intelligence report. Triggers when the
  user asks for: "economic report", "market news", "market update", "economic/market
  analysis", "financial situation", "markets today/this week", "investment news",
  "news roundup", "financial/macro report", "economic briefing", "global markets".
  The report includes: an overview Dashboard, 20 Key Insights, an Impact Map (US, China,
  Taiwan, Hong Kong), analysis of 5 asset classes (gold, real estate, crypto, equities,
  energy), comparison against 3-5 past reports in the project folder, reasoning & a 7-day
  short-term forecast, and a Watchlist with two scenarios (bull/bear).
---

<!-- ════════════════════════════════════════════════════════════════ -->
<!-- ⚙️ CONFIGURATION — edit this block only -->
<!-- ════════════════════════════════════════════════════════════════ -->

## ⚙️ CONFIGURATION

> The engine below reads from this block. Edit only this block; do not touch the ENGINE.

```yaml
report_folder:    "Marketing - News"        # project folder holding past reports (rename to match yours)
output_language:  "English"                 # language of the generated report (e.g. "English", "Vietnamese")
lookback_days:    3                          # how recent the news must be
history_reports:  5                          # how many past reports to compare against (3-5 recommended)
```

<!-- ════════════ END CONFIGURATION — the ENGINE below, DO NOT EDIT ════════════ -->

# Skill: news-report — Strategic Global Economic & Financial Report

## Objective

Synthesize the last few days of news into an expert-level strategic report for investors and decision-makers. The report must be both panoramic and detailed, **compared against data from prior days** to infer trends, and presented visually in the configured `output_language`.

---

## Step 1: Research Phase

Run parallel searches across all topic groups below. Prioritize information from the **last `lookback_days` days**:

### Group A — Macroeconomics & Central Banks
- Monetary policy: Fed, ECB, BoJ, PBOC (rates, dot plot, statements)
- Inflation, GDP, labor data (CPI, PCE, PMI, NFP)
- FX (USD, JPY, EUR, CNY, TWD), government bonds

### Group B — Geopolitics & Energy
- Conflicts and tensions with economic impact
- Oil prices (Brent, WTI), natural gas, uranium, renewables

### Group C — Key Regions
- 🇺🇸 US: Fed, S&P 500, Nasdaq, IPOs, corporates
- 🇨🇳 China: PBOC, CSI 300, AI/semiconductors, exports
- 🇹🇼 Taiwan: TSMC, TAIEX, technology, geopolitics
- 🇭🇰 Hong Kong: Hang Seng, HK policy

### Group D — Companies & Technology
- AI: OpenAI, Anthropic, xAI, Google, DeepSeek, Huawei
- Semiconductors: NVIDIA, TSMC, AMD, Intel, ASML, Samsung
- IPOs, M&A, large funding rounds (>$500M)
- Notable startups and tech breakthroughs

### Group E — Financial Assets
- Gold (spot, ETF flows); Bitcoin/Ethereum (price, ETF flows)
- Real estate (mortgage rates, home prices, REITs)
- Equities (major indices, leading sectors)
- Energy (oil, uranium, renewables)

---

## Step 1.5: Compare Against Historical Data (MANDATORY — run before writing analysis)

Goal: every forecast must rest on **multi-day developments**, not a single-day snapshot.

1. **Scan the project folder `report_folder`** (see Configuration) for past report files (naming pattern `Global_economic_report_*.md`).
2. **Read the `history_reports` most recent reports** (ordered by date in filename / modification date). These are the official historical data source for comparison.
3. For each asset class & region, **extract a time series** from the past reports plus today's data, e.g.:
   - Price/index across periods (gold, BTC, S&P 500, oil, rates, FX…)
   - Trends noted in the prior period and **how well they played out** versus today's reality.
   - The prior report's "Next 7-day signals" → verify whether they materialized.
4. Build a short **Comparison Table** (see PART 4B) as the backbone of the reasoning.
5. If the folder has no past reports yet: state clearly "No historical data in folder — analysis based on the last few days of news" and continue.

> Principle: **never fabricate historical data.** Only cite real files in the folder or web sources actually found. Always name the specific report and date.

---

## Step 2: Report Structure

Save the file `Global_economic_report_[dd-mm-yyyy].md` into the user's workspace folder.

### PART 0: HEADER
```
# 📊 GLOBAL ECONOMIC & FINANCIAL REPORT
### Strategic analysis | Period: [date]–[date], [year]
> *Compiled by AI Strategic Analyst | Sources: [5-8 primary sources]*
> *Historical comparison: [list the 3-5 past reports used + dates]*
```

### PART 1: OVERVIEW DASHBOARD

A 10-row table at the top of the report — a 30-second read of the whole picture. Add a **Δ vs prior period** column to show change against the most recent past report:

| Category | Trend | Δ vs prior | Volatility | Key event | Outlook |
|---|---|---|---|---|---|
| 🌍 Global economy | ⬆️/⬇️/↔️ [desc] | [+/− / new] | 🔴/🟠/🟡/🟢 [level] | [key event] | [1 line] |
| 🇺🇸 United States | ... | ... | ... | ... | ... |
| 🇨🇳 China | ... | ... | ... | ... | ... |
| 🇹🇼 Taiwan | ... | ... | ... | ... | ... |
| 🇭🇰 Hong Kong | ... | ... | ... | ... | ... |
| 🥇 Gold | ... | ... | ... | ... | ... |
| 🏠 Real estate | ... | ... | ... | ... | ... |
| ₿ Crypto | ... | ... | ... | ... | ... |
| 📈 Equities | ... | ... | ... | ... | ... |
| ⚡ Energy | ... | ... | ... | ... | ... |

### PART 2: EXECUTIVE SUMMARY — 20 KEY INSIGHTS

Pick exactly the 20 most important events/trends, grouped by theme (4-6 groups).

Format for each insight:
```
**#[01-20] — [Emoji] [Short title]**
- **Summary:** [1-2 sentences + concrete figures]
- **Severity:** [🔴 Very high / 🟠 High / 🟡 Medium / 🟢 Low]
- **Short-term (7 days):** [expected impact]
- **Mid-term (6-12M):** [expected impact]
- **Markets:** [affected sectors/assets]
```

Prioritize events likely to shift capital flows, reverse sentiment, or shape long-term trends.

### PART 3: IMPACT MAP

3-5 bullet points of analysis for each region:
- 🌍 Global
- 🇺🇸 United States
- 🇨🇳 China
- 🇹🇼 Taiwan
- 🇭🇰 Hong Kong

Show the causal relationships between events (e.g.: Iran deal → oil down → inflation eases).

### PART 4: ANALYSIS OF 5 ASSET CLASSES

For each asset (gold, crypto, real estate, equities, energy):
- A concrete data table (price, % change, key indices)
- Tailwinds vs. headwinds
- Short-term (7 days) and mid-term (6-12M) outlook

### PART 4B: HISTORICAL COMPARISON TABLE

A table of developments across periods — the basis for reasoning in PART 5B:

| Asset/Indicator | Period (-2) | Period (-1) | Today | Direction | Was prior signal correct? |
|---|---|---|---|---|---|
| 🥇 Gold | ... | ... | ... | ⬆️/⬇️/↔️ | ✅ correct / ❌ wrong / ⏳ pending |
| ₿ BTC | ... | ... | ... | ... | ... |
| 📈 S&P 500 | ... | ... | ... | ... | ... |
| ⚡ Oil | ... | ... | ... | ... | ... |
| 💵 Rates/FX | ... | ... | ... | ... | ... |

### PART 5: STRATEGIC CONCLUSIONS

**A. Major trends** — 2-3 paragraphs of analysis (no bullets, written as an analytical essay)

### PART 5B: REASONING & SHORT-TERM FORECAST — NEXT 7 DAYS (core section)

This is the most important inference section. Do NOT just restate the news — **bridge from today's data + the historical series (PART 4B) → conclude what is likely to happen in the next 7 days.**

For each key asset class/region, write to this frame:
```
**[Asset/Region]**
- **Series observation:** [development across 3-5 periods → describe momentum/reversal]
- **Reasoning:** [why, causal links between signals, confidence %]
- **7-day forecast:** [base-case scenario + price/index thresholds to watch]
```

**Next 7-day Signals Table** — 7-10 events/indicators:
| # | Event / Indicator | Probability | Impact | Markets | Vs prior period |
|---|---|---|---|---|---|

### PART 5C: 🎯 WATCHLIST — WHAT TO MONITOR RIGHT NOW (as a list)

This section guides MONITORING actions for the user, written as a **list**. For each item to watch, reason out **two branches** clearly:

```
1. **[Thing to watch]** — *Why it matters:* [1 line]
   - 👀 **Level/threshold to watch:** [specific number, event, date/time]
   - 🟢 **If it goes WELL (holds/breaks above):** [consequence → suggested response]
   - 🔴 **If it goes BADLY (breaks down/reverses):** [consequence → suggested response]
2. ...
```

Requirements:
- List **5-8 items**, ranked by urgency/impact.
- Each item MUST include the threshold to watch + a good branch + a bad branch.
- Focus on **monitoring & preparation**, not outright buy/sell orders.
- Tie each item to data in PART 4B/5B for grounding.

**C. Opportunities & Risks** — a summary table of sectors/assets that benefit vs. those at risk

### FOOTER
```
*📅 Report updated: [date] | Next cycle: [date + lookback_days]*
*🔁 Compared against: [names of 3-5 past reports + dates]*
*⚠️ Disclaimer: This report is for reference only and is not investment advice.*
```

---

## Step 3: Publish

1. Save the `.md` file into the user's workspace folder
2. Call `present_files` to share the file
3. Summarize the 5 hottest points + 3 urgent watchlist items directly in chat
4. List references (Sources section) at the end of the response, including the past reports used for comparison

---

## Quality Standards

- **Concrete figures:** every claim carries data (%, $, bps, index points)
- **Timeliness:** use only news from the last `lookback_days` days for new items
- **Historical grounding:** MANDATORY comparison against `history_reports` past reports; every forecast rests on a data series, not a single day
- **Reasoning:** PART 5B must contain causal arguments + confidence levels, not restated news
- **Actionability:** PART 5C always has thresholds to watch + two scenarios (bull/bear)
- **Connectedness:** show causal relationships between events
- **Balance:** present both the bull case and the bear case
- **Honesty:** never fabricate historical data; cite sources and historical reports clearly
- **Language:** write the report in the configured `output_language`; keep common financial terms as-is (Fed, GDP, ETF...)
