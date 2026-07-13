# ADHD Research — Sourced from Repos

Source URLs reviewed 2026-06-20:
- `ayghri/i-have-adhd` — Claude Code skill for ADHD-friendly output
- `mrseth01/awesome-adhd` — Curated ADHD resources (283★)
- `XargsUK/awesome-adhd` — ADHD apps & tools list (365★)
- `uditakhourii/adhd` — Tree-of-thought AI agent skill (not ADHD-specific)

## Communication Style (from i-have-adhd)

The core principle: **action-first, no fluff, answer now context later.**

### Formatting Rules
- Lead with the actionable thing. Not the setup.
- Numbered steps for multi-part answers.
- NO: "Hope this helps!", "Let me know if you need anything else!", "Let's dive in!", "Great question!", "I understand you're asking about..."
- NO conversational preambles. Skip the warm-up.
- If the answer can fit in one line, one line is the complete answer.
- The confirmation IS the response. Nothing after.

### Before/After Table

| Before (fluff) | After (good) |
|----------------|--------------|
| "Great, I've captured everything! Let me organize it into categories..." | **Dump captured.** 5 items (1 task → tracking, 2 ideas, 1 reminder, 1 random). |
| "No problem at all! Here's what I found..." | **Dump captured.** 3 items. All random. |
| "Hope this helps! Let me know if you want to..." | (nothing — skill is done) |

## Expert Framing (from mrseth01/awesome-adhd)

### Russell Barkley: "It's a performance disorder"
> "You can know stuff, but you can't do stuff. It's a performance disorder."

ADHD is an **Executive Function Disorder** — the gap between knowing and doing isn't motivation, it's a switching-cost problem. The ADHD brain pays a higher toll to transition from "thinking about X" to "doing X."

### Other Experts Noted
- **Dr. Daniel Amen** — 7 types of ADHD via SPECT scans, natural treatments
- **Dr. Hallowell** — "Driven to Distraction" author
- **Dr. Michael Manos** — Nuances of ADHD

### Definition (from ADDitude.mag)
> "A misunderstood neurological disorder that impacts the parts of the brain that help us plan, focus on, and execute tasks."

## Tool Categories (from XargsUK/awesome-adhd)

### Time Management
- ActivityWatch (free, multi-platform time tracker)
- Pomodoro timers (TomatoTimer, Focus Keeper, Pomotroid)
- Bullet Journal app (method-based)

### Block Distractions
- Opal, Freedom, RescueTime (freemium blockers)
- Forest (gamified focus), SelfControl (macOS), Cold Turkey (Win/Mac)
- Go F*cking Work (profanity-motivated Chrome ext)

### Visual Calendars
- Structured — visual calendar + to-do
- PiCal — visual ADHD day planner
- Tiimo — schedule, focus & to-do
- TimeBloc — time block scheduler

### Sounds for Focus
- Brown/pink/white noise apps
- Brain.fm — brainwave music
- Endel — adaptive focus/sleep/relax soundscapes
- Focus@will — scientifically optimized music
- Rainy Mood, myNoise, SomaFM — ambient/noise
- Blanket (Linux) — background noise

### Task Management
- Super Productivity — timeboxing + tasks (free, cross-platform)
- Due — persistent reminders (paid, Apple ecosystem)
- Remember The Milk — online to-do (freemium)

### Motivation & Gamification
- Habitica — RPG-ify tasks
- TickTick — habit tracker + to-do + Pomodoro
- Streaks — habit tracking by streak count

### Note Taking (Quick Capture)
- Google Keep — quick capture
- Standard Notes — encrypted notes
- Obsidian — local markdown wiki (already in use)

### Habit Tracking
- Loop Habit Tracker — open source, no frills
- HabitBull — streak + stats
- Streaks — Apple Watch native

## Body Doubling (implicit from app lists + ADHD strategy)

Body doubling = having another person present while you work. Reduces activation energy for task initiation and sustains focus. Virtual body doubling (AI as silent presence) is a viable substitute.

### How to Body Double (as an AI)
1. State the offer: "I'll stay present and quiet. I'm just here so it's not empty."
2. Go silent unless user speaks first
3. If asked a question, answer minimally then return to silence
4. No proactive check-ins, no "how's it going?", no progress monitoring
5. End with: "Done. Good work." — no analysis, no follow-up
6. If user wants to continue, offer to stay silent again

## Environment Tools Summary

| Tool | When to Offer | Implementation |
|------|---------------|----------------|
| Brown/pink noise | After distraction, signal re-entry | Suggest via text (no tool needed) |
| Pomodoro timer (25min) | Task feels too long, "I'll do it forever" | Suggest setting one |
| Website blocker | Easy to tab-away-from work | Suggest external tool (Freedom, SelfControl) |
| Tab cleanup | Visual clutter paralysis | "Close 3 tabs you don't need" |
| Notification mute | Recent distraction from ping | "Mute everything for 25 min" |

## Applicability to Skills

This research was applied to four ADHD productivity skills:
- **brain-dump** → i-have-adhd response style, high-speed capture, process raw dumps
- **start-small** → Barkley framing (performance disorder), Pattern 5 (body double), environment prep as first step
- **quick-win** → Source 7 (environment reset: focus sounds, Pomodoro, blockers, tab cleanup), body-double extension
- **redirect** → Environment re-anchor, focus-sound companion offer
