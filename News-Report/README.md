# 📊 News-Report Skill

An expert-level generator of **strategic global macro & financial intelligence reports**.

The skill synthesizes the last few days of news via real-time web search, then turns it into a strategic briefing for investors and decision-makers — panoramic yet detailed, and **compared against past reports** to infer trends rather than capturing a single isolated day.

## Key Features

- **Overview Dashboard** — read the whole market in 30 seconds, with a change-vs-prior-period column.
- **20 Key Insights** — distill exactly the 20 most important events/trends, grouped by theme.
- **Impact Map** — impact analysis for 4 key regions: 🇺🇸 US, 🇨🇳 China, 🇹🇼 Taiwan, 🇭🇰 Hong Kong.
- **5 asset classes** — gold, real estate, crypto, equities, energy.
- **Historical comparison** — scan and compare 3–5 past reports in the folder to build a time series.
- **Reasoning & 7-day forecast** — causal arguments with confidence levels, not restated news.
- **Watchlist** — a prioritized list with thresholds to watch and two scenarios (bull/bear) per item.

## How to Trigger

Ask Claude with phrases like: *"economic report"*, *"market news"*, *"market update"*, *"market analysis"*, *"economic briefing"*, *"global markets"*…

## Configure Before Use

Open the skill file (`Skill/[ # news-report ].md`) and edit the **⚙️ CONFIGURATION** block at the top:

- `report_folder` — the project folder holding your past reports (rename to match yours, e.g. `Marketing - News`).
- `output_language` — the language of the generated report (default: `English`).
- `lookback_days` — how recent the news must be.
- `history_reports` — how many past reports to compare against (3–5 recommended).
