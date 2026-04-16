-- ============================================
-- 001_foundation.sql
-- Core tables for CampusBuilder.ai
-- ============================================

-- ============================================
-- ORGANIZATIONS (the GC firms using the platform)
-- ============================================

CREATE TABLE organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  state text,
  license_number text,
  insurance_expiry date,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'suspended', 'inactive')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================
-- PROFILES (extends Supabase auth.users)
-- ============================================

CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name text,
  email text,
  phone text,
  role text NOT NULL DEFAULT 'member'
    CHECK (role IN ('owner', 'admin', 'pm', 'superintendent', 'member')),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================
-- ORG MEMBERS (join table)
-- ============================================

CREATE TABLE org_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member'
    CHECK (role IN ('owner', 'admin', 'pm', 'superintendent', 'field')),
  invited_at timestamptz NOT NULL DEFAULT now(),
  accepted_at timestamptz,
  UNIQUE (org_id, user_id)
);

CREATE INDEX idx_org_members_org ON org_members (org_id);
CREATE INDEX idx_org_members_user ON org_members (user_id);

-- ============================================
-- UNIVERSITIES
-- ============================================

CREATE TABLE universities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  abbreviation text,
  state text,
  system_name text,
  facilities_dept_name text,
  website text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================
-- CAMPUSES
-- ============================================

CREATE TABLE campuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL REFERENCES universities ON DELETE CASCADE,
  name text NOT NULL,
  city text,
  state text,
  address text,
  is_main_campus boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_campuses_university ON campuses (university_id);

-- ============================================
-- CAMPUS ASSIGNMENTS
-- ============================================

CREATE TABLE campus_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  campus_id uuid NOT NULL REFERENCES campuses ON DELETE CASCADE,
  contract_type text
    CHECK (contract_type IN ('continuing_services', 'hard_bid', 'design_build', 'cmar')),
  contract_number text,
  contract_start date,
  contract_end date,
  per_project_cap numeric,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'expired', 'pending')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, campus_id, contract_number)
);

CREATE INDEX idx_campus_assignments_org ON campus_assignments (org_id, status);
CREATE INDEX idx_campus_assignments_campus ON campus_assignments (campus_id);

-- ============================================
-- FACILITY CONTACTS
-- ============================================

CREATE TABLE facility_contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL REFERENCES universities ON DELETE CASCADE,
  campus_id uuid REFERENCES campuses ON DELETE SET NULL,
  name text NOT NULL,
  title text,
  email text,
  phone text,
  department text,
  is_primary boolean NOT NULL DEFAULT false,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_facility_contacts_university ON facility_contacts (university_id);
CREATE INDEX idx_facility_contacts_campus ON facility_contacts (campus_id);

-- ============================================
-- PROJECTS
-- ============================================

CREATE TABLE projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  campus_id uuid NOT NULL REFERENCES campuses ON DELETE CASCADE,
  assignment_id uuid NOT NULL REFERENCES campus_assignments ON DELETE CASCADE,
  -- Identity
  name text NOT NULL,
  project_number text,
  internal_number text,
  description text,
  -- Contract details
  contract_type text NOT NULL
    CHECK (contract_type IN ('lump_sum', 'gmp', 'cost_plus')),
  contract_amount numeric,
  -- GMP-specific
  gmp_amount numeric,
  gmp_contingency numeric,
  shared_savings_split_contractor float8,
  shared_savings_split_owner float8,
  -- Cost Plus-specific
  fee_type text CHECK (fee_type IN ('fixed_fee', 'percentage_fee')),
  fee_amount numeric,
  fee_percentage float8,
  gc_conditions_amount numeric,
  -- Billing
  retainage_pct float8 NOT NULL DEFAULT 10,
  retainage_reduction_pct float8,
  retainage_reduction_threshold float8,
  billing_day int,
  -- Funding
  funding_source text
    CHECK (funding_source IN ('state_appropriation', 'auxiliary', 'donor', 'federal_grant', 'mixed')),
  funding_details text,
  -- Compliance
  requires_certified_payroll boolean NOT NULL DEFAULT false,
  requires_davis_bacon boolean NOT NULL DEFAULT false,
  minority_participation_goal float8,
  -- Dates
  notice_to_proceed date,
  substantial_completion date,
  final_completion date,
  -- Status
  status text NOT NULL DEFAULT 'pre_construction'
    CHECK (status IN ('pre_construction', 'active', 'punch_list', 'closeout', 'complete', 'warranty')),
  -- Team
  project_manager_id uuid REFERENCES profiles ON DELETE SET NULL,
  superintendent_id uuid REFERENCES profiles ON DELETE SET NULL,
  -- University side
  university_pm_contact_id uuid REFERENCES facility_contacts ON DELETE SET NULL,
  -- BOT approval
  bot_approval_required boolean NOT NULL DEFAULT false,
  bot_approval_status text CHECK (bot_approval_status IN ('pending', 'approved', 'deferred')),
  bot_approval_date date,
  -- Metadata
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_projects_org_campus_status ON projects (org_id, campus_id, status);
CREATE INDEX idx_projects_org_status ON projects (org_id, status);
CREATE INDEX idx_projects_assignment ON projects (assignment_id);

-- ============================================
-- SUBCONTRACTORS
-- ============================================

CREATE TABLE subcontractors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  company_name text NOT NULL,
  contact_name text,
  email text,
  phone text,
  trade text,
  license_number text,
  insurance_expiry date,
  workers_comp_expiry date,
  minority_status text CHECK (minority_status IN ('MBE', 'WBE', 'SBE', 'VBE', 'none')),
  prequalified boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_subcontractors_org ON subcontractors (org_id);

-- ============================================
-- PROCUREMENT RULES (state-level reference data)
-- ============================================

CREATE TABLE procurement_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  state text NOT NULL,
  rule_type text,
  threshold_amount numeric,
  percentage float8,
  description text,
  statute_reference text,
  effective_date date,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_procurement_rules_state ON procurement_rules (state);

-- ============================================
-- ACTIVITY LOG
-- ============================================

CREATE TABLE activity_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES organizations ON DELETE CASCADE,
  user_id uuid REFERENCES profiles ON DELETE SET NULL,
  project_id uuid REFERENCES projects ON DELETE SET NULL,
  action text NOT NULL,
  entity_type text,
  entity_id uuid,
  details jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_activity_log_org_created ON activity_log (org_id, created_at DESC);
CREATE INDEX idx_activity_log_project ON activity_log (project_id);

-- ============================================
-- AUTO-UPDATE updated_at TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_campus_assignments_updated_at
  BEFORE UPDATE ON campus_assignments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_subcontractors_updated_at
  BEFORE UPDATE ON subcontractors
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- ============================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE universities ENABLE ROW LEVEL SECURITY;
ALTER TABLE campuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE campus_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE facility_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcontractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE procurement_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- Helper: check if current user belongs to an org
CREATE OR REPLACE FUNCTION user_orgs()
RETURNS SETOF uuid AS $$
  SELECT org_id FROM org_members WHERE user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Organizations: see only your own orgs
CREATE POLICY "Users see their orgs"
  ON organizations FOR SELECT
  USING (id IN (SELECT user_orgs()));

CREATE POLICY "Org owners can update"
  ON organizations FOR UPDATE
  USING (id IN (
    SELECT org_id FROM org_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));

-- Profiles: users can see profiles within their orgs
CREATE POLICY "Users see org member profiles"
  ON profiles FOR SELECT
  USING (
    id = auth.uid()
    OR id IN (
      SELECT om.user_id FROM org_members om
      WHERE om.org_id IN (SELECT user_orgs())
    )
  );

CREATE POLICY "Users update own profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid());

-- Org members: see members of your orgs
CREATE POLICY "Users see own org members"
  ON org_members FOR SELECT
  USING (org_id IN (SELECT user_orgs()));

CREATE POLICY "Admins manage org members"
  ON org_members FOR ALL
  USING (org_id IN (
    SELECT org_id FROM org_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));

-- Universities & Campuses: readable by all authenticated users (shared reference data)
CREATE POLICY "Authenticated users read universities"
  ON universities FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users read campuses"
  ON campuses FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Campus assignments: scoped by org
CREATE POLICY "Users see their campus assignments"
  ON campus_assignments FOR SELECT
  USING (org_id IN (SELECT user_orgs()));

CREATE POLICY "Admins manage campus assignments"
  ON campus_assignments FOR ALL
  USING (org_id IN (
    SELECT org_id FROM org_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));

-- Facility contacts: readable by authenticated users (shared reference data)
CREATE POLICY "Authenticated users read facility contacts"
  ON facility_contacts FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Projects: scoped by org
CREATE POLICY "Users see their projects"
  ON projects FOR SELECT
  USING (org_id IN (SELECT user_orgs()));

CREATE POLICY "Members manage projects"
  ON projects FOR ALL
  USING (org_id IN (SELECT user_orgs()));

-- Subcontractors: scoped by org
CREATE POLICY "Users see their subs"
  ON subcontractors FOR SELECT
  USING (org_id IN (SELECT user_orgs()));

CREATE POLICY "Members manage subs"
  ON subcontractors FOR ALL
  USING (org_id IN (SELECT user_orgs()));

-- Procurement rules: readable by all authenticated users
CREATE POLICY "Authenticated users read procurement rules"
  ON procurement_rules FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Activity log: scoped by org
CREATE POLICY "Users see their activity"
  ON activity_log FOR SELECT
  USING (org_id IN (SELECT user_orgs()));

CREATE POLICY "Members write activity"
  ON activity_log FOR INSERT
  WITH CHECK (org_id IN (SELECT user_orgs()));
