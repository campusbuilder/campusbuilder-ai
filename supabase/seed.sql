-- ============================================
-- seed.sql — Realistic university construction data
-- Run after migrations with: psql -f supabase/seed.sql
-- ============================================

-- Use deterministic UUIDs so foreign keys work in seed

-- ============================================
-- ORGANIZATIONS
-- ============================================

INSERT INTO organizations (id, name, state, license_number, insurance_expiry, status) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Tideline Construction', 'FL', 'CGC-1521847', '2027-03-15', 'active');

-- ============================================
-- UNIVERSITIES
-- ============================================

INSERT INTO universities (id, name, abbreviation, state, system_name, facilities_dept_name, website) VALUES
  ('b1000000-0000-0000-0000-000000000001', 'Florida Atlantic University', 'FAU', 'FL',
   'State University System of Florida', 'Facilities Planning & Construction',
   'https://www.fau.edu'),
  ('b1000000-0000-0000-0000-000000000002', 'University of Central Florida', 'UCF', 'FL',
   'State University System of Florida', 'Facilities & Safety',
   'https://www.ucf.edu');

-- ============================================
-- CAMPUSES
-- ============================================

INSERT INTO campuses (id, university_id, name, city, state, is_main_campus) VALUES
  -- FAU campuses
  ('c1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001',
   'Boca Raton Campus', 'Boca Raton', 'FL', true),
  ('c1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001',
   'Jupiter Campus', 'Jupiter', 'FL', false),
  ('c1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001',
   'Davie Campus', 'Davie', 'FL', false),
  ('c1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001',
   'Fort Lauderdale Campus', 'Fort Lauderdale', 'FL', false),
  -- UCF campuses
  ('c1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000002',
   'Main Campus', 'Orlando', 'FL', true),
  ('c1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000002',
   'Downtown Campus', 'Orlando', 'FL', false),
  ('c1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000002',
   'Rosen College of Hospitality', 'Orlando', 'FL', false);

-- ============================================
-- CAMPUS ASSIGNMENTS (Tideline → FAU Boca)
-- ============================================

INSERT INTO campus_assignments (id, org_id, campus_id, contract_type, contract_number, contract_start, contract_end, per_project_cap, status) VALUES
  ('d1000000-0000-0000-0000-000000000001',
   'a1000000-0000-0000-0000-000000000001',
   'c1000000-0000-0000-0000-000000000001',
   'continuing_services', 'CSC-2025-FAU-003', '2025-07-01', '2028-06-30',
   4000000, 'active');

-- ============================================
-- FACILITY CONTACTS
-- ============================================

INSERT INTO facility_contacts (id, university_id, campus_id, name, title, email, phone, department, is_primary) VALUES
  -- FAU contacts
  ('e1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001',
   'c1000000-0000-0000-0000-000000000001',
   'Robert Granger', 'Director of Construction', 'rgranger@fau.edu', '561-297-3010',
   'Facilities Planning & Construction', true),
  ('e1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001',
   'c1000000-0000-0000-0000-000000000001',
   'Maria Delgado', 'Senior Project Manager', 'mdelgado@fau.edu', '561-297-3015',
   'Facilities Planning & Construction', false),
  ('e1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001',
   NULL,
   'Jessica Thornton', 'Project Coordinator', 'jthornton@fau.edu', '561-297-3020',
   'Facilities Planning & Construction', false),
  -- UCF contacts
  ('e1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000002',
   'c1000000-0000-0000-0000-000000000005',
   'David Chen', 'Assistant VP of Facilities', 'david.chen@ucf.edu', '407-823-2471',
   'Facilities & Safety', true),
  ('e1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000002',
   'c1000000-0000-0000-0000-000000000005',
   'Karen Mitchell', 'Construction Manager', 'karen.mitchell@ucf.edu', '407-823-2475',
   'Facilities & Safety', false);

-- ============================================
-- PROJECTS (3 under Tideline/FAU Boca)
-- ============================================

-- Project 1: Lump Sum
INSERT INTO projects (
  id, org_id, campus_id, assignment_id, name, project_number, internal_number,
  description, contract_type, contract_amount,
  retainage_pct, retainage_reduction_pct, retainage_reduction_threshold,
  billing_day, funding_source,
  requires_certified_payroll, requires_davis_bacon, minority_participation_goal,
  notice_to_proceed, substantial_completion, status,
  university_pm_contact_id
) VALUES (
  'f1000000-0000-0000-0000-000000000001',
  'a1000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000001',
  'd1000000-0000-0000-0000-000000000001',
  'Science Building 43 — HVAC Replacement',
  'FAU-2026-SB43-HVAC', 'TC-2026-001',
  'Complete replacement of rooftop HVAC units and ductwork for Science Building 43. Includes demolition of existing units, structural modifications for new equipment, and controls integration with campus BAS.',
  'lump_sum', 1180000,
  10, 5, 50,
  25, 'state_appropriation',
  false, false, 0.20,
  '2026-01-15', '2026-09-15', 'active',
  'e1000000-0000-0000-0000-000000000002'
);

-- Project 2: GMP
INSERT INTO projects (
  id, org_id, campus_id, assignment_id, name, project_number, internal_number,
  description, contract_type, contract_amount,
  gmp_amount, gmp_contingency, shared_savings_split_contractor, shared_savings_split_owner,
  retainage_pct, retainage_reduction_pct, retainage_reduction_threshold,
  billing_day, funding_source,
  requires_certified_payroll, requires_davis_bacon, minority_participation_goal,
  notice_to_proceed, substantial_completion, status,
  university_pm_contact_id,
  bot_approval_required, bot_approval_status, bot_approval_date
) VALUES (
  'f1000000-0000-0000-0000-000000000002',
  'a1000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000001',
  'd1000000-0000-0000-0000-000000000001',
  'Student Union West Wing Renovation',
  'FAU-2025-SUWW-REN', 'TC-2025-004',
  'Full interior renovation of the Student Union west wing including new MEP systems, ADA-compliant restrooms, food service area buildout, and complete finishes package. Phased to maintain building occupancy.',
  'gmp', 3800000,
  3800000, 190000, 0.25, 0.75,
  10, 5, 50,
  25, 'auxiliary',
  false, false, 0.15,
  '2025-11-01', '2026-08-01', 'active',
  'e1000000-0000-0000-0000-000000000001',
  true, 'approved', '2025-10-15'
);

-- Project 3: Cost Plus
INSERT INTO projects (
  id, org_id, campus_id, assignment_id, name, project_number, internal_number,
  description, contract_type,
  fee_type, fee_percentage, gc_conditions_amount,
  retainage_pct, billing_day, funding_source, funding_details,
  requires_certified_payroll, requires_davis_bacon,
  notice_to_proceed, status,
  university_pm_contact_id
) VALUES (
  'f1000000-0000-0000-0000-000000000003',
  'a1000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000001',
  'd1000000-0000-0000-0000-000000000001',
  'Parking Garage C — Emergency Structural Repair',
  'FAU-2026-PGC-STR', 'TC-2026-002',
  'Emergency structural repair of Parking Garage C levels 3-4. Post-tensioned cable remediation, concrete spall repair, and waterproofing membrane replacement. Authorized under emergency procurement provisions.',
  'cost_plus',
  'percentage_fee', 0.08, 95000,
  10, 25, 'auxiliary', 'Emergency authorization — auxiliary reserve fund',
  true, false,
  '2026-03-01', 'active',
  'e1000000-0000-0000-0000-000000000002'
);

-- ============================================
-- SUBCONTRACTORS
-- ============================================

INSERT INTO subcontractors (id, org_id, company_name, contact_name, email, phone, trade, license_number, insurance_expiry, workers_comp_expiry, minority_status, prequalified, status) VALUES
  ('70000000-0000-0000-0000-000000000001',
   'a1000000-0000-0000-0000-000000000001',
   'Sunshine Plumbing Corp', 'Carlos Reyes', 'carlos@sunshineplumbing.com', '561-555-0101',
   'Plumbing', 'CFC-1429876', '2027-01-15', '2027-01-15', 'MBE', true, 'active'),
  ('70000000-0000-0000-0000-000000000002',
   'a1000000-0000-0000-0000-000000000001',
   'Gulf Coast Mechanical', 'Tom Harrington', 'tom@gulfcoastmech.com', '561-555-0102',
   'HVAC', 'CMC-1335421', '2026-11-30', '2026-11-30', NULL, true, 'active'),
  ('70000000-0000-0000-0000-000000000003',
   'a1000000-0000-0000-0000-000000000001',
   'Brightline Electrical', 'Ana Santos', 'ana@brightlineelec.com', '561-555-0103',
   'Electrical', 'EC-13004782', '2027-03-01', '2027-03-01', 'SBE', true, 'active'),
  ('70000000-0000-0000-0000-000000000004',
   'a1000000-0000-0000-0000-000000000001',
   'Coastal Concrete', 'Mike Brennan', 'mike@coastalconcrete.net', '561-555-0104',
   'Concrete/Sitework', 'CGC-1498213', '2026-08-15', '2026-08-15', NULL, true, 'active');

-- ============================================
-- PROCUREMENT RULES (Florida)
-- ============================================

INSERT INTO procurement_rules (id, state, rule_type, threshold_amount, percentage, description, statute_reference, effective_date) VALUES
  ('80000000-0000-0000-0000-000000000001', 'FL', 'competitive_solicitation_threshold',
   300000, NULL,
   'Construction projects over $300,000 require competitive solicitation (formal bids or qualifications-based selection)',
   'F.S. 255.0525', '2024-07-01'),
  ('80000000-0000-0000-0000-000000000002', 'FL', 'informal_quote_threshold',
   75000, NULL,
   'Construction projects between $75,000 and $300,000 require written quotes from at least 3 contractors',
   'F.S. 255.0525', '2024-07-01'),
  ('80000000-0000-0000-0000-000000000003', 'FL', 'retainage_cap',
   NULL, 10,
   'Retainage may not exceed 10% until project is 50% complete, then capped at 5%',
   'F.S. 255.078', '2024-07-01'),
  ('80000000-0000-0000-0000-000000000004', 'FL', 'minority_goal',
   NULL, NULL,
   'State universities encouraged to establish minority business enterprise participation goals per project. Typical range 10-20% depending on scope and trade availability.',
   'F.S. 287.09451', '2024-07-01'),
  ('80000000-0000-0000-0000-000000000005', 'FL', 'prevailing_wage',
   NULL, NULL,
   'Florida does not have a state prevailing wage law. Davis-Bacon applies only to federally funded projects.',
   NULL, '2024-07-01');
