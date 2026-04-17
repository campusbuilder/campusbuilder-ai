-- ============================================
-- 002_payapp_schema.sql
-- Pay Application tables (G702/G703)
-- Schema only — UI built in Session 02
-- ============================================

-- ============================================
-- SCHEDULE OF VALUES (the G703 structure)
-- ============================================

CREATE TABLE payapp_sov (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  project_id uuid NOT NULL REFERENCES projects ON DELETE CASCADE,
  original_contract_sum numeric NOT NULL,
  approved_change_orders numeric NOT NULL DEFAULT 0,
  contract_sum_to_date numeric GENERATED ALWAYS AS (original_contract_sum + approved_change_orders) STORED,
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_payapp_sov_project ON payapp_sov (project_id);

-- G703 line items (Columns A through I)
CREATE TABLE payapp_sov_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sov_id uuid NOT NULL REFERENCES payapp_sov ON DELETE CASCADE,
  item_number text NOT NULL,
  description text NOT NULL,
  scheduled_value numeric NOT NULL,
  is_fee_line boolean NOT NULL DEFAULT false,
  is_contingency_line boolean NOT NULL DEFAULT false,
  sort_order int NOT NULL
);

CREATE INDEX idx_payapp_sov_items_sov ON payapp_sov_items (sov_id, sort_order);

-- ============================================
-- CHANGE ORDERS
-- ============================================

CREATE TABLE payapp_change_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  project_id uuid NOT NULL REFERENCES projects ON DELETE CASCADE,
  sov_id uuid NOT NULL REFERENCES payapp_sov ON DELETE CASCADE,
  co_number int NOT NULL,
  description text NOT NULL,
  additions numeric NOT NULL DEFAULT 0,
  deductions numeric NOT NULL DEFAULT 0,
  net_amount numeric GENERATED ALWAYS AS (additions - deductions) STORED,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  date_submitted date,
  date_approved date,
  funding_source text,
  requires_bot_approval boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (project_id, co_number)
);

CREATE INDEX idx_payapp_co_project ON payapp_change_orders (project_id);
CREATE INDEX idx_payapp_co_sov ON payapp_change_orders (sov_id);

-- ============================================
-- PAY APPLICATIONS (monthly billing — the G702)
-- ============================================

CREATE TABLE payapp_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  project_id uuid NOT NULL REFERENCES projects ON DELETE CASCADE,
  sov_id uuid NOT NULL REFERENCES payapp_sov ON DELETE CASCADE,
  application_number int NOT NULL,
  period_from date,
  period_to date NOT NULL,
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'paid')),
  -- G702 Lines 1-9 (Lump Sum & GMP)
  original_contract_sum numeric,
  net_change_orders numeric,
  contract_sum_to_date numeric,
  total_completed_and_stored numeric,
  retainage numeric,
  total_earned_less_retainage numeric,
  less_previous_certificates numeric,
  current_payment_due numeric,
  balance_to_finish_plus_retainage numeric,
  -- GMP-specific
  gmp_contingency_used_this_period numeric,
  gmp_contingency_remaining numeric,
  cost_of_work_this_period numeric,
  fee_earned_this_period numeric,
  -- Cost Plus-specific
  cost_backup jsonb,
  total_cost_of_work numeric,
  gc_conditions_billed numeric,
  fee_calculated numeric,
  total_billing numeric,
  -- Workflow
  submitted_at timestamptz,
  submitted_by uuid REFERENCES profiles ON DELETE SET NULL,
  reviewed_by text,
  approved_at timestamptz,
  paid_at timestamptz,
  paid_amount numeric,
  payment_check_number text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (project_id, application_number)
);

CREATE INDEX idx_payapp_applications_project_num ON payapp_applications (project_id, application_number);
CREATE INDEX idx_payapp_applications_project_status ON payapp_applications (project_id, status);

-- G703 per-period entries
CREATE TABLE payapp_application_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES payapp_applications ON DELETE CASCADE,
  sov_item_id uuid NOT NULL REFERENCES payapp_sov_items ON DELETE CASCADE,
  work_completed_previous numeric NOT NULL DEFAULT 0,
  work_completed_this_period numeric NOT NULL DEFAULT 0,
  materials_stored numeric NOT NULL DEFAULT 0,
  total_completed_to_date numeric GENERATED ALWAYS AS (
    work_completed_previous + work_completed_this_period + materials_stored
  ) STORED,
  pct_complete float8,
  balance_to_finish numeric,
  retainage numeric,
  UNIQUE (application_id, sov_item_id)
);

CREATE INDEX idx_payapp_app_items_application ON payapp_application_items (application_id);
CREATE INDEX idx_payapp_app_items_sov_item ON payapp_application_items (sov_item_id);

-- ============================================
-- SUB CONTRACTS & SUB BILLING
-- ============================================

CREATE TABLE payapp_sub_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  project_id uuid NOT NULL REFERENCES projects ON DELETE CASCADE,
  subcontractor_id uuid NOT NULL REFERENCES subcontractors ON DELETE CASCADE,
  trade text NOT NULL,
  contract_amount numeric NOT NULL,
  retainage_pct float8 NOT NULL DEFAULT 10,
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'executed', 'complete', 'terminated')),
  executed_date date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_payapp_sub_contracts_project ON payapp_sub_contracts (project_id);
CREATE INDEX idx_payapp_sub_contracts_sub ON payapp_sub_contracts (subcontractor_id);

CREATE TABLE payapp_sub_sov_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sub_contract_id uuid NOT NULL REFERENCES payapp_sub_contracts ON DELETE CASCADE,
  item_number text NOT NULL,
  description text NOT NULL,
  scheduled_value numeric NOT NULL,
  sort_order int
);

CREATE INDEX idx_payapp_sub_sov_items_contract ON payapp_sub_sov_items (sub_contract_id);

CREATE TABLE payapp_sub_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sub_contract_id uuid NOT NULL REFERENCES payapp_sub_contracts ON DELETE CASCADE,
  application_number int NOT NULL,
  period_to date NOT NULL,
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'submitted', 'approved', 'rejected', 'paid')),
  current_payment_due numeric,
  submitted_at timestamptz,
  approved_at timestamptz,
  paid_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sub_contract_id, application_number)
);

CREATE INDEX idx_payapp_sub_apps_contract ON payapp_sub_applications (sub_contract_id);

CREATE TABLE payapp_sub_app_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sub_application_id uuid NOT NULL REFERENCES payapp_sub_applications ON DELETE CASCADE,
  sub_sov_item_id uuid NOT NULL REFERENCES payapp_sub_sov_items ON DELETE CASCADE,
  work_completed_previous numeric NOT NULL DEFAULT 0,
  work_completed_this_period numeric NOT NULL DEFAULT 0,
  materials_stored numeric NOT NULL DEFAULT 0,
  total_completed_to_date numeric GENERATED ALWAYS AS (
    work_completed_previous + work_completed_this_period + materials_stored
  ) STORED,
  pct_complete float8,
  balance_to_finish numeric,
  UNIQUE (sub_application_id, sub_sov_item_id)
);

CREATE INDEX idx_payapp_sub_app_items_app ON payapp_sub_app_items (sub_application_id);

-- ============================================
-- PAY APP FUND SPLITS (for mixed-funding projects)
-- ============================================
-- When project.funding_source = 'mixed', each pay app must break down
-- current_payment_due by fund source. One row per funding contribution
-- to a specific pay application.

CREATE TABLE payapp_application_fund_splits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES payapp_applications ON DELETE CASCADE,
  fund_name text NOT NULL,            -- e.g. "State appropriation 2025-A", "Harbor Foundation donor fund"
  fund_type text,                     -- matches funding_source enum values: state_appropriation, auxiliary, donor, federal_grant
  amount numeric NOT NULL,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_payapp_fund_splits_application ON payapp_application_fund_splits (application_id);

-- ============================================
-- updated_at TRIGGERS for pay app tables
-- ============================================

CREATE TRIGGER trg_payapp_sov_updated_at
  BEFORE UPDATE ON payapp_sov
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_payapp_applications_updated_at
  BEFORE UPDATE ON payapp_applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_payapp_sub_contracts_updated_at
  BEFORE UPDATE ON payapp_sub_contracts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- ROW LEVEL SECURITY for pay app tables
-- ============================================

ALTER TABLE payapp_sov ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_sov_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_change_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_application_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_application_fund_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_sub_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_sub_sov_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_sub_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payapp_sub_app_items ENABLE ROW LEVEL SECURITY;

-- SOV: scoped by org
CREATE POLICY "Users see their SOVs"
  ON payapp_sov FOR SELECT
  USING (org_id IN (SELECT user_orgs()));
CREATE POLICY "Members manage SOVs"
  ON payapp_sov FOR ALL
  USING (org_id IN (SELECT user_orgs()));

-- SOV items: through SOV
CREATE POLICY "Users see their SOV items"
  ON payapp_sov_items FOR SELECT
  USING (sov_id IN (SELECT id FROM payapp_sov WHERE org_id IN (SELECT user_orgs())));
CREATE POLICY "Members manage SOV items"
  ON payapp_sov_items FOR ALL
  USING (sov_id IN (SELECT id FROM payapp_sov WHERE org_id IN (SELECT user_orgs())));

-- Change orders: scoped by org
CREATE POLICY "Users see their COs"
  ON payapp_change_orders FOR SELECT
  USING (org_id IN (SELECT user_orgs()));
CREATE POLICY "Members manage COs"
  ON payapp_change_orders FOR ALL
  USING (org_id IN (SELECT user_orgs()));

-- Pay applications: scoped by org
CREATE POLICY "Users see their pay apps"
  ON payapp_applications FOR SELECT
  USING (org_id IN (SELECT user_orgs()));
CREATE POLICY "Members manage pay apps"
  ON payapp_applications FOR ALL
  USING (org_id IN (SELECT user_orgs()));

-- Pay app items: through application
CREATE POLICY "Users see their pay app items"
  ON payapp_application_items FOR SELECT
  USING (application_id IN (
    SELECT id FROM payapp_applications WHERE org_id IN (SELECT user_orgs())
  ));
CREATE POLICY "Members manage pay app items"
  ON payapp_application_items FOR ALL
  USING (application_id IN (
    SELECT id FROM payapp_applications WHERE org_id IN (SELECT user_orgs())
  ));

-- Fund splits: through application
CREATE POLICY "Users see their fund splits"
  ON payapp_application_fund_splits FOR SELECT
  USING (application_id IN (
    SELECT id FROM payapp_applications WHERE org_id IN (SELECT user_orgs())
  ));
CREATE POLICY "Members manage fund splits"
  ON payapp_application_fund_splits FOR ALL
  USING (application_id IN (
    SELECT id FROM payapp_applications WHERE org_id IN (SELECT user_orgs())
  ));

-- Sub contracts: scoped by org
CREATE POLICY "Users see their sub contracts"
  ON payapp_sub_contracts FOR SELECT
  USING (org_id IN (SELECT user_orgs()));
CREATE POLICY "Members manage sub contracts"
  ON payapp_sub_contracts FOR ALL
  USING (org_id IN (SELECT user_orgs()));

-- Sub SOV items: through sub contract
CREATE POLICY "Users see their sub SOV items"
  ON payapp_sub_sov_items FOR SELECT
  USING (sub_contract_id IN (
    SELECT id FROM payapp_sub_contracts WHERE org_id IN (SELECT user_orgs())
  ));
CREATE POLICY "Members manage sub SOV items"
  ON payapp_sub_sov_items FOR ALL
  USING (sub_contract_id IN (
    SELECT id FROM payapp_sub_contracts WHERE org_id IN (SELECT user_orgs())
  ));

-- Sub applications: through sub contract
CREATE POLICY "Users see their sub apps"
  ON payapp_sub_applications FOR SELECT
  USING (sub_contract_id IN (
    SELECT id FROM payapp_sub_contracts WHERE org_id IN (SELECT user_orgs())
  ));
CREATE POLICY "Members manage sub apps"
  ON payapp_sub_applications FOR ALL
  USING (sub_contract_id IN (
    SELECT id FROM payapp_sub_contracts WHERE org_id IN (SELECT user_orgs())
  ));

-- Sub app items: through sub application
CREATE POLICY "Users see their sub app items"
  ON payapp_sub_app_items FOR SELECT
  USING (sub_application_id IN (
    SELECT id FROM payapp_sub_applications WHERE sub_contract_id IN (
      SELECT id FROM payapp_sub_contracts WHERE org_id IN (SELECT user_orgs())
    )
  ));
CREATE POLICY "Members manage sub app items"
  ON payapp_sub_app_items FOR ALL
  USING (sub_application_id IN (
    SELECT id FROM payapp_sub_applications WHERE sub_contract_id IN (
      SELECT id FROM payapp_sub_contracts WHERE org_id IN (SELECT user_orgs())
    )
  ));
