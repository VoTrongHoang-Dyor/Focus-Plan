---
name: grill-me-chat
description: Interview the user relentlessly about a plan or design until you reach shared understanding, walking down every branch of the decision tree and resolving dependencies one at a time. The crucial difference from generic Q&A is that before asking anything, you review the CURRENT CHAT SESSION — skipping what's already decided, and actively surfacing open forks, unstated assumptions, contradictions, and hidden dependencies that came up earlier. Use this whenever the user says "/grill-me", "grill me", "grill tôi", "tra tấn cái plan này", "stress-test this plan or design", "poke holes in this", "phản biện thiết kế", "rà soát plan", "hỏi xoáy", or wants their plan, architecture, or decision pressure-tested before committing — even if they don't use the exact word "grill".
---
 
# grill-me
 
Interview the user relentlessly about every aspect of their plan or design until you both reach shared understanding. Walk down each branch of the decision tree, resolving dependencies between decisions one-by-one. The goal is not interrogation for its own sake — it's to surface and settle every unresolved decision so the plan is actually buildable.
 
## The core rule: mine the session before you ask
 
**If a question can be answered by reviewing the current chat session, review it instead of asking.** This is the whole point. Re-asking something the user already decided is the fastest way to lose their trust.
 
Before each question, scan the current conversation and sort what you find into four buckets:
 
1. **Already decided** → do not re-ask. Treat it as a fixed constraint and let it narrow downstream questions.
2. **Stated assumption** → the user asserted something as given. Grill it: is it actually true, and what breaks if it's wrong?
3. **Open fork** → a decision that was raised but never resolved, or where the user said "maybe" / "we'll see" / "TBD".
4. **Hidden dependency or contradiction** → two earlier statements that can't both hold, or a choice that silently forces another choice the user hasn't faced yet.
You are doing active gap-finding, not just deduplication. The valuable questions usually live in buckets 2–4 — the things the user *didn't* realize were still open.
 
If the session genuinely doesn't contain the answer, then ask.
 
## How to ask
 
**One question at a time.** Never batch. Each answer reshapes the tree, so wait for it before picking the next question.
 
**Always give your recommended answer.** For every question, state which way you'd go and why — including the trade-off you're accepting. A grilling without a recommendation is just a quiz. The recommendation is also what makes this collaborative: the user can react to a concrete position instead of starting from a blank page.
 
**Pick the delivery format to match the question:**
 
- *Discrete choice* (the answer is one of a small set of options) → use the tappable-options input tool (e.g. `ask_user_input_v0`). Phrase the options crisply and **mark the one you recommend** in the question text (e.g. "tôi nghiêng về B vì…"). This is the "AskUserQuestion but better" behavior — options *plus* an opinionated steer.
- *Open / generative* (the answer is a number, a name, a description, a design sketch) → ask in plain text, still with your recommended answer attached.
When in doubt, prefer the tappable tool for forks and plain text for everything else. Mobile users especially benefit from tappable options.
 
## Ordering: dependency × impact
 
Don't walk the tree left-to-right. Order questions so that:
 
- **Blockers go first.** If decision X changes what the options for Y even are, resolve X first. Resolving a parent can delete whole branches of children — that's the efficiency win.
- **High-impact, hard-to-reverse decisions outrank cosmetic ones.** Architecture before naming. Data model before button colors.
Relentless is the default — keep going until the tree is resolved — but it is *organized* relentlessness, not a random firehose. Always honor an explicit exit: if the user says "đủ rồi", "stop", or "just grill me on X", scope down or wrap up immediately.
 
## Closing: the Decision Log
 
When the branches are resolved (or the user calls it), stop asking and emit a **Decision Log** — the tangible "shared understanding" payoff:
 
```
## Decision Log
- <Decision>: <what was chosen> — <one-line why>
- ...
 
## Still open (if any)
- <Decision>: <why it's deferred / what unblocks it>
 
## Assumptions we're now betting on
- <assumption that, if wrong, forces a rethink>
```
 
This log feeds straight back into whatever the user was building. Keep it tight — it's a reference, not a transcript.
 
## Language
 
Conduct the grilling in the user's language. For a Vietnamese user, use the register they use (e.g. peer-level "Bạn–Tôi" if that's how the conversation has gone). Match how they write, not a default.