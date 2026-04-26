# Metrics Dashboard Spec — How We Prove the ROI

**Goal:** Capture data from Day 1 of CampusBuilder usage so that 12 months from now we can publish a verifiable, attributable case study with specific numbers — not vague claims.

**Operating principle:** If we can't measure it, we can't claim it. Every metric needs (1) a baseline captured BEFORE the platform changes anything, and (2) a comparable ongoing measurement.

**Why this matters:** That single sentence — *"Tideline Construction reduced pay-app admin time from 70 to 2 hours/month, increased win rate by 10 points, expanded margin by 10%, and tightened estimate-vs-actual variance by 50% using CampusBuilder.ai"* — is the most valuable marketing asset CampusBuilder will ever have. We are engineering Day 1 of the platform to make that sentence true and provable.

---

## The five metrics we're committing to

### 1. Pay app hours per month
**The hero metric. Easy to measure. Defines the value prop.**

- **Baseline source (Week 1):** Self-reported time log from Jeff/admin staff for one full pay-app cycle on each active project. Captured via simple in-app form: date, project, task, minutes. Sum to baseline hours per cycle × cycles/month → baseline hours/month.
- **Ongoing source:** Auto-captured from CampusBuilder activity timestamps on `payapp_applications`. First user touch on a pay app → submission timestamp = elapsed working time. Manual override available for offline work (e.g., reviewing on paper).
- **Capture method:** Hybrid — auto-tracked with manual override.
- **Schema addition:**
  ```sql
  CREATE TABLE payapp_time_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id uuid REFERENCES payapp_applications,
    user_id uuid REFERENCES profiles,
    action text,                           -- 'opened', 'edited_line', 'reviewed_sub', 'submitted', etc.
    started_at timestamptz NOT NULL,
    ended_at timestamptz,
    minutes int GENERATED ALWAYS AS (
      EXTRACT(EPOCH FROM (ended_at - started_at)) / 60
    ) STORED,
    source text NOT NULL DEFAULT 'auto'    -- 'auto' or 'manual'
  );
  ```
- **Reporting cadence:** Monthly. Hero number on the dashboard.
- **Risk to attribution:** Low. The system literally watches pay-app work happen.

---

### 2. Win rate on solicited work
**The growth metric. The hardest to attribute cleanly. Requires Tideline to actually use the pipeline tracker.**

- **Baseline source (Week 2):** Manual import of last 12 months of Tideline solicitations. For each: project name, university, scope, bid amount, won/lost/no-bid, date submitted, date decided, lost-to-competitor (if known), lost-reason notes.
- **Ongoing source:** CampusBuilder pipeline tracker (separate module to build). Every CSC task order, hard bid, RFP response is logged here as it happens. Outcome captured when known.
- **Capture method:** Manual entry by Tideline, but the system makes entry low-friction (3 fields to log a new opportunity, 1 field to mark outcome).
- **Schema addition:**
  ```sql
  CREATE TABLE solicitations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id uuid NOT NULL REFERENCES organizations,
    campus_id uuid REFERENCES campuses,
    scope text NOT NULL,
    bid_amount numeric,
    status text NOT NULL DEFAULT 'open'    -- 'open', 'won', 'lost', 'no_bid', 'declined_by_owner'
      CHECK (status IN ('open','won','lost','no_bid','declined_by_owner')),
    submitted_at date,
    decided_at date,
    lost_to_competitor text,
    lost_reason text,
    notes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
  );
  ```
- **Reporting cadence:** Quarterly rolling 12-month win rate.
- **Risk to attribution:** Medium-high. Win rate moves for many reasons. We must be honest in the case study and isolate the Pay-App-Pro-related effect (e.g., "wins where Tideline's reputation for clean billing was cited as a factor").

---

### 3. Overhead as percentage of revenue
**The slowest-moving metric. Requires Tideline financial cooperation. Hardest to attribute solely to CampusBuilder.**

- **Baseline source (Week 4):** Manual entry — Tideline's most recent 12-month P&L summary. Total revenue, total overhead (G&A + indirect labor + facilities, NOT direct project cost), overhead %.
- **Ongoing source:** Quarterly manual entry by Jeff or his bookkeeper. Phase-2 option: QuickBooks API integration.
- **Capture method:** Manual quarterly form. Optional QB integration later.
- **Schema addition:**
  ```sql
  CREATE TABLE org_financials (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id uuid NOT NULL REFERENCES organizations,
    period_start date NOT NULL,
    period_end date NOT NULL,
    total_revenue numeric NOT NULL,
    total_overhead numeric NOT NULL,
    overhead_pct float8 GENERATED ALWAYS AS (total_overhead / NULLIF(total_revenue,0)) STORED,
    source text DEFAULT 'manual',          -- 'manual' or 'qb_api'
    notes text,
    entered_by uuid REFERENCES profiles,
    entered_at timestamptz DEFAULT now(),
    UNIQUE (org_id, period_start, period_end)
  );
  ```
- **Reporting cadence:** Quarterly.
- **Risk to attribution:** High. Overhead drops for many reasons (someone left, a lease renegotiated, a process changed). We need to attribute specifically to admin-hour reduction. Track headcount and roles alongside.

---

### 4. Margin per project
**The compounding metric. Tells the long-term story.**

- **Baseline source (Week 4):** Manual entry — last 12 months of completed Tideline projects with final revenue, final cost, gross margin %. Roll up to weighted-average margin.
- **Ongoing source:** Auto-captured from CampusBuilder project closeout flow. When a project status moves to `complete`, the system prompts for final cost. Final revenue is already known from approved pay-app + CO totals. Margin computed automatically.
- **Capture method:** Hybrid — system has the revenue side from existing data; final cost requires one closeout-time input.
- **Schema additions to `projects` table:**
  ```sql
  ALTER TABLE projects ADD COLUMN final_cost numeric;
  ALTER TABLE projects ADD COLUMN final_revenue numeric;        -- redundant with pay-app sum but locked at closeout
  ALTER TABLE projects ADD COLUMN gross_margin_pct float8
    GENERATED ALWAYS AS ((final_revenue - final_cost) / NULLIF(final_revenue,0)) STORED;
  ALTER TABLE projects ADD COLUMN closeout_completed_at timestamptz;
  ALTER TABLE projects ADD COLUMN closeout_completed_by uuid REFERENCES profiles;
  ```
- **Reporting cadence:** Quarterly weighted-average margin on projects completed in the period.
- **Risk to attribution:** Medium. Margin improves from many factors. Track which CampusBuilder features (CO discipline, sub billing tightness, retainage auto-reduction enforcement) likely contributed.

---

### 5. Estimate-vs-actual variance
**The predictability metric. The one that buys Tideline the right to bid tighter and win more.**

- **Baseline source (Week 4):** From the same backfill as #4 — for each completed project, capture `estimate_at_ntp` (the original estimate locked at notice-to-proceed) and `final_cost`. Variance = (final_cost − estimate_at_ntp) / estimate_at_ntp. Take absolute value for averaging.
- **Ongoing source:** Auto-captured. When a project moves to `active` status, the system snapshots the estimate. At closeout, final cost is captured (#4). Variance computed.
- **Capture method:** Auto-snapshot at NTP, auto-compute at closeout.
- **Schema additions to `projects` table:**
  ```sql
  ALTER TABLE projects ADD COLUMN estimate_at_ntp numeric;
  ALTER TABLE projects ADD COLUMN estimate_at_ntp_locked_at timestamptz;
  ALTER TABLE projects ADD COLUMN variance_pct float8
    GENERATED ALWAYS AS ((final_cost - estimate_at_ntp) / NULLIF(estimate_at_ntp,0)) STORED;
  ALTER TABLE projects ADD COLUMN variance_abs_pct float8
    GENERATED ALWAYS AS (ABS((final_cost - estimate_at_ntp) / NULLIF(estimate_at_ntp,0))) STORED;
  ```
- **Reporting cadence:** Quarterly weighted-average absolute variance. Lower is better.
- **Risk to attribution:** Medium-low. Variance is largely controlled by GC discipline (estimating, CO management, scope control), all of which CampusBuilder enables.

---

## Baseline data collection plan — first 4 weeks

| Week | Task | Owner | Hours |
|---|---|---|---|
| 1 | Stand up baseline data entry forms in CampusBuilder | Builder | 4-6 |
| 1-2 | Capture time log for one full pay-app cycle (parallel — old way + new way both tracked) | Jeff/admin | 2-3 |
| 2-3 | Backfill 12 months of solicitations (project, university, bid, outcome, date) | Jeff/admin | 4-6 |
| 4 | Backfill 12 months of project P&L (revenue, cost, margin, original estimate, final cost) | Jeff or bookkeeper | 4-8 |

**Total Tideline time investment for baselining: 10-17 hours one-time.** Then mostly automated.

---

## Reporting cadence

- **Weekly internal:** hours captured, pay-app cycle metrics. Builder-side only, sanity check.
- **Monthly:** hours/month vs. baseline + trend chart. Shared with Jeff.
- **Quarterly:** full 5-metric scorecard with attribution notes. Shared with Jeff. Becomes the basis of board-style review.
- **12-month milestone:** case study published. Specific numbers. Tideline is named (with permission). Becomes Pay App Pro's go-to-market asset.

---

## Dashboard UI — what to build

A Tideline-only `/metrics` page in CampusBuilder (Phase 1.5 build, after Pay App Pro core ships):

```
┌─────────────────────────────────────────────────────────────┐
│  Tideline Operational Scorecard          Q3 2026 (current) │
├─────────────────────────────────────────────────────────────┤
│  ⏱  Pay App Hours/Mo     8.5    ↓ from 70    -88%           │
│  🏆 Win Rate (12mo)      52%    ↑ from 47%   +5pts          │
│  🏢 Overhead %           9.8%   ↓ from 12.1% -19%           │
│  💰 Avg Project Margin   8.4%   ↑ from 7.2%  +17%           │
│  🎯 Est-vs-Actual Var.   3.1%   ↓ from 6.4%  -52%           │
└─────────────────────────────────────────────────────────────┘

[ Time-series chart: hours/mo ─────────────────  ]
[ Time-series chart: win rate     ─────────  ]
[ ... ]

[ Export quarterly PDF ]   [ View baseline data ]
```

Implementation order: build the data capture first (Week 1 of Pay App Pro). Build the dashboard UI second (Phase 1.5, ~Month 4). Backfill analytics retroactively from captured data — don't build the UI before there's data to populate it.

---

## What this enables — the long game

After 12 months of clean data we can publish:

> **"Tideline Construction reduced pay-app admin time from 70 to 2 hours/month, increased project win rate by 10 percentage points, expanded gross margin from 7.2% to 8.0%, and tightened estimate-vs-actual variance by 50% — all using CampusBuilder.ai."**

That sentence is worth more than every feature page on the marketing site combined. Every dollar spent making it provable is a dollar invested in CampusBuilder's GTM. We are engineering Day 1 of the platform to make that sentence true *and* defensible *and* attributable.

---

## Schema deltas summary

New tables needed for metrics:
- `payapp_time_log`
- `solicitations`
- `org_financials`

New columns on existing `projects` table:
- `final_cost`, `final_revenue`, `gross_margin_pct` (generated)
- `closeout_completed_at`, `closeout_completed_by`
- `estimate_at_ntp`, `estimate_at_ntp_locked_at`
- `variance_pct`, `variance_abs_pct` (both generated)

These should land in a new migration `003_metrics_capture.sql` before Pay App Pro UI work begins. The data capture has to be live the day Tideline starts using the system — backfilling baselines is acceptable, but we cannot lose Day-1 data because the schema wasn't ready.

---

*Prepared as Phase 1 measurement plan for CampusBuilder.ai*
*Owner: builder side. Reviewer: Jeff (sanity check on what's realistic to capture from Tideline's side).*
