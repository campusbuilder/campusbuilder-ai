// Database type placeholder — will be generated from Supabase CLI later.
// For now, define the core types manually to get type safety.

export type Database = {
  public: {
    Tables: {
      organizations: {
        Row: Organization
        Insert: Omit<Organization, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<Organization, 'id'>>
      }
      profiles: {
        Row: Profile
        Insert: Omit<Profile, 'created_at'>
        Update: Partial<Omit<Profile, 'id'>>
      }
      org_members: {
        Row: OrgMember
        Insert: Omit<OrgMember, 'id' | 'invited_at'>
        Update: Partial<Omit<OrgMember, 'id'>>
      }
      universities: {
        Row: University
        Insert: Omit<University, 'id' | 'created_at'>
        Update: Partial<Omit<University, 'id'>>
      }
      campuses: {
        Row: Campus
        Insert: Omit<Campus, 'id' | 'created_at'>
        Update: Partial<Omit<Campus, 'id'>>
      }
      campus_assignments: {
        Row: CampusAssignment
        Insert: Omit<CampusAssignment, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<CampusAssignment, 'id'>>
      }
      facility_contacts: {
        Row: FacilityContact
        Insert: Omit<FacilityContact, 'id' | 'created_at'>
        Update: Partial<Omit<FacilityContact, 'id'>>
      }
      projects: {
        Row: Project
        Insert: Omit<Project, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<Project, 'id'>>
      }
      subcontractors: {
        Row: Subcontractor
        Insert: Omit<Subcontractor, 'id' | 'created_at' | 'updated_at'>
        Update: Partial<Omit<Subcontractor, 'id'>>
      }
      procurement_rules: {
        Row: ProcurementRule
        Insert: Omit<ProcurementRule, 'id' | 'created_at'>
        Update: Partial<Omit<ProcurementRule, 'id'>>
      }
      activity_log: {
        Row: ActivityLog
        Insert: Omit<ActivityLog, 'id' | 'created_at'>
        Update: Partial<Omit<ActivityLog, 'id'>>
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
  }
}

// ============================================
// Core Types
// ============================================

export interface Organization {
  id: string
  name: string
  state: string | null
  license_number: string | null
  insurance_expiry: string | null
  status: 'active' | 'suspended' | 'inactive'
  created_at: string
  updated_at: string
}

export interface Profile {
  id: string
  full_name: string | null
  email: string | null
  phone: string | null
  role: 'owner' | 'admin' | 'pm' | 'superintendent' | 'member'
  created_at: string
}

export interface OrgMember {
  id: string
  org_id: string
  user_id: string
  role: 'owner' | 'admin' | 'pm' | 'superintendent' | 'field'
  invited_at: string
  accepted_at: string | null
}

export interface University {
  id: string
  name: string
  abbreviation: string | null
  state: string | null
  system_name: string | null
  facilities_dept_name: string | null
  website: string | null
  created_at: string
}

export interface Campus {
  id: string
  university_id: string
  name: string
  city: string | null
  state: string | null
  address: string | null
  is_main_campus: boolean
  created_at: string
}

export interface CampusAssignment {
  id: string
  org_id: string
  campus_id: string
  contract_type: 'continuing_services' | 'hard_bid' | 'design_build' | 'cmar'
  contract_number: string | null
  contract_start: string | null
  contract_end: string | null
  per_project_cap: number | null
  status: 'active' | 'expired' | 'pending'
  created_at: string
  updated_at: string
}

export interface FacilityContact {
  id: string
  university_id: string
  campus_id: string | null
  name: string
  title: string | null
  email: string | null
  phone: string | null
  department: string | null
  is_primary: boolean
  notes: string | null
  created_at: string
}

export interface Project {
  id: string
  org_id: string
  campus_id: string
  assignment_id: string
  name: string
  project_number: string | null
  internal_number: string | null
  description: string | null
  contract_type: 'lump_sum' | 'gmp' | 'cost_plus'
  contract_amount: number | null
  gmp_amount: number | null
  gmp_contingency: number | null
  shared_savings_split_contractor: number | null
  shared_savings_split_owner: number | null
  fee_type: 'fixed_fee' | 'percentage_fee' | null
  fee_amount: number | null
  fee_percentage: number | null
  gc_conditions_amount: number | null
  retainage_pct: number
  retainage_reduction_pct: number | null
  retainage_reduction_threshold: number | null
  billing_day: number | null
  funding_source: 'state_appropriation' | 'auxiliary' | 'donor' | 'federal_grant' | 'mixed' | null
  funding_details: string | null
  requires_certified_payroll: boolean
  requires_davis_bacon: boolean
  minority_participation_goal: number | null
  notice_to_proceed: string | null
  substantial_completion: string | null
  final_completion: string | null
  status: 'pre_construction' | 'active' | 'punch_list' | 'closeout' | 'complete' | 'warranty'
  project_manager_id: string | null
  superintendent_id: string | null
  university_pm_contact_id: string | null
  bot_approval_required: boolean
  bot_approval_status: 'pending' | 'approved' | 'deferred' | null
  bot_approval_date: string | null
  created_at: string
  updated_at: string
}

export interface Subcontractor {
  id: string
  org_id: string
  company_name: string
  contact_name: string | null
  email: string | null
  phone: string | null
  trade: string | null
  license_number: string | null
  insurance_expiry: string | null
  workers_comp_expiry: string | null
  minority_status: 'MBE' | 'WBE' | 'SBE' | 'VBE' | 'none' | null
  prequalified: boolean
  status: 'active' | 'inactive'
  created_at: string
  updated_at: string
}

export interface ProcurementRule {
  id: string
  state: string
  rule_type: string
  threshold_amount: number | null
  percentage: number | null
  description: string | null
  statute_reference: string | null
  effective_date: string | null
  created_at: string
}

export interface ActivityLog {
  id: string
  org_id: string
  user_id: string | null
  project_id: string | null
  action: string
  entity_type: string | null
  entity_id: string | null
  details: Record<string, unknown> | null
  created_at: string
}

// ============================================
// Joined / View Types (for queries with joins)
// ============================================

export interface CampusWithUniversity extends Campus {
  university: University
}

export interface CampusAssignmentWithDetails extends CampusAssignment {
  campus: CampusWithUniversity
}

export interface ProjectWithCampus extends Project {
  campus: CampusWithUniversity
}
