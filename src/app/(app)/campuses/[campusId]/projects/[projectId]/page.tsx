import { createClient } from '@/lib/supabase-server'
import { getActiveOrg } from '@/lib/with-org'
import Link from 'next/link'
import { notFound } from 'next/navigation'

export default async function ProjectDetailPage({
  params,
}: {
  params: Promise<{ campusId: string; projectId: string }>
}) {
  const { campusId, projectId } = await params
  const { orgId } = await getActiveOrg()
  const supabase = await createClient()

  const { data: project } = await supabase
    .from('projects')
    .select('*')
    .eq('id', projectId)
    .eq('org_id', orgId)
    .single()

  if (!project) notFound()

  // Get campus info
  const { data: campus } = await supabase
    .from('campuses')
    .select('name, university:universities ( name, abbreviation )')
    .eq('id', campusId)
    .single()

  const university = (Array.isArray(campus?.university)
    ? campus.university[0]
    : campus?.university) as Record<string, unknown> | null

  // Get team members
  const teamIds = [project.project_manager_id, project.superintendent_id].filter(
    Boolean
  )
  const { data: teamMembers } = teamIds.length
    ? await supabase
        .from('profiles')
        .select('id, full_name, role')
        .in('id', teamIds)
    : { data: [] }

  // Get university PM contact
  let universityPm = null
  if (project.university_pm_contact_id) {
    const { data } = await supabase
      .from('facility_contacts')
      .select('name, title, email')
      .eq('id', project.university_pm_contact_id)
      .single()
    universityPm = data
  }

  const contractTypeLabels: Record<string, string> = {
    lump_sum: 'Lump Sum',
    gmp: 'GMP',
    cost_plus: 'Cost Plus',
  }

  const statusColors: Record<string, string> = {
    pre_construction: 'bg-yellow-50 text-yellow-700',
    active: 'bg-green-50 text-green-700',
    punch_list: 'bg-orange-50 text-orange-700',
    closeout: 'bg-blue-50 text-blue-700',
    complete: 'bg-gray-100 text-gray-600',
    warranty: 'bg-purple-50 text-purple-700',
  }

  const fundingLabels: Record<string, string> = {
    state_appropriation: 'State Appropriation',
    auxiliary: 'Auxiliary Funds',
    donor: 'Donor Funds',
    federal_grant: 'Federal Grant',
    mixed: 'Mixed Sources',
  }

  function formatCurrency(val: number | null | undefined): string {
    if (val == null) return '—'
    return `$${Number(val).toLocaleString()}`
  }

  function formatPct(val: number | null | undefined): string {
    if (val == null) return '—'
    return `${(Number(val) * 100).toFixed(0)}%`
  }

  return (
    <div className="space-y-6">
      <div>
        <Link
          href={`/campuses/${campusId}`}
          className="text-sm text-gray-500 hover:text-gray-700"
        >
          &larr; {campus?.name ?? 'Campus'}
        </Link>
        <h1 className="mt-1 text-xl font-semibold text-gray-900">
          {project.name}
        </h1>
        <p className="text-sm text-gray-500">
          {(university?.abbreviation as string) ?? ''} &middot;{' '}
          {project.project_number ?? project.internal_number ?? ''}
        </p>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Contract Details */}
        <div className="rounded-lg border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-medium text-gray-700">
            Contract Details
          </h2>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-gray-500">Contract Type</dt>
              <dd className="text-gray-900">
                {contractTypeLabels[project.contract_type]}
              </dd>
            </div>

            {project.contract_type === 'lump_sum' && (
              <div className="flex justify-between">
                <dt className="text-gray-500">Contract Amount</dt>
                <dd className="font-medium text-gray-900">
                  {formatCurrency(project.contract_amount)}
                </dd>
              </div>
            )}

            {project.contract_type === 'gmp' && (
              <>
                <div className="flex justify-between">
                  <dt className="text-gray-500">GMP Amount</dt>
                  <dd className="font-medium text-gray-900">
                    {formatCurrency(project.gmp_amount)}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Contingency</dt>
                  <dd className="text-gray-900">
                    {formatCurrency(project.gmp_contingency)}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Shared Savings</dt>
                  <dd className="text-gray-900">
                    {project.shared_savings_split_owner != null
                      ? `${(Number(project.shared_savings_split_owner) * 100).toFixed(0)}% Owner / ${(Number(project.shared_savings_split_contractor) * 100).toFixed(0)}% Contractor`
                      : '—'}
                  </dd>
                </div>
              </>
            )}

            {project.contract_type === 'cost_plus' && (
              <>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Fee</dt>
                  <dd className="text-gray-900">
                    {project.fee_percentage != null
                      ? `${(Number(project.fee_percentage) * 100).toFixed(0)}% of cost`
                      : project.fee_amount
                        ? formatCurrency(project.fee_amount)
                        : '—'}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-500">GC Conditions</dt>
                  <dd className="text-gray-900">
                    {formatCurrency(project.gc_conditions_amount)}
                  </dd>
                </div>
              </>
            )}

            <div className="flex justify-between">
              <dt className="text-gray-500">Retainage</dt>
              <dd className="text-gray-900">
                {project.retainage_pct}%
                {project.retainage_reduction_pct != null &&
                  ` → ${project.retainage_reduction_pct}% after ${project.retainage_reduction_threshold}%`}
              </dd>
            </div>

            <div className="flex justify-between">
              <dt className="text-gray-500">Funding</dt>
              <dd className="text-gray-900">
                {project.funding_source
                  ? fundingLabels[project.funding_source] ?? project.funding_source
                  : '—'}
              </dd>
            </div>

            <div className="flex justify-between">
              <dt className="text-gray-500">Status</dt>
              <dd>
                <span
                  className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${statusColors[project.status] ?? 'bg-gray-100 text-gray-600'}`}
                >
                  {project.status.replace('_', ' ')}
                </span>
              </dd>
            </div>
          </dl>
        </div>

        {/* Dates & Compliance */}
        <div className="rounded-lg border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-medium text-gray-700">
            Dates & Compliance
          </h2>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-gray-500">NTP</dt>
              <dd className="text-gray-900">
                {project.notice_to_proceed ?? '—'}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-gray-500">Substantial Completion</dt>
              <dd className="text-gray-900">
                {project.substantial_completion ?? '—'}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-gray-500">Billing Day</dt>
              <dd className="text-gray-900">
                {project.billing_day ? `Day ${project.billing_day}` : '—'}
              </dd>
            </div>

            <div className="mt-3 border-t border-gray-100 pt-3">
              <div className="flex justify-between">
                <dt className="text-gray-500">Certified Payroll</dt>
                <dd className="text-gray-900">
                  {project.requires_certified_payroll ? 'Required' : 'No'}
                </dd>
              </div>
            </div>
            <div className="flex justify-between">
              <dt className="text-gray-500">Davis-Bacon</dt>
              <dd className="text-gray-900">
                {project.requires_davis_bacon ? 'Required' : 'No'}
              </dd>
            </div>
            {project.minority_participation_goal != null && (
              <div className="flex justify-between">
                <dt className="text-gray-500">MBE Goal</dt>
                <dd className="text-gray-900">
                  {formatPct(project.minority_participation_goal)}
                </dd>
              </div>
            )}
            {project.bot_approval_required && (
              <div className="flex justify-between">
                <dt className="text-gray-500">BOT Approval</dt>
                <dd className="text-gray-900">
                  {project.bot_approval_status ?? 'Required'}{' '}
                  {project.bot_approval_date && `(${project.bot_approval_date})`}
                </dd>
              </div>
            )}
          </dl>
        </div>

        {/* Team */}
        <div className="rounded-lg border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-medium text-gray-700">Team</h2>
          <dl className="mt-3 space-y-2 text-sm">
            {teamMembers?.map((m) => (
              <div key={m.id} className="flex justify-between">
                <dt className="text-gray-500 capitalize">{m.role}</dt>
                <dd className="text-gray-900">{m.full_name ?? '—'}</dd>
              </div>
            ))}
            {universityPm && (
              <div className="flex justify-between">
                <dt className="text-gray-500">University PM</dt>
                <dd className="text-gray-900">
                  {universityPm.name}{' '}
                  <span className="text-gray-400">
                    ({universityPm.title})
                  </span>
                </dd>
              </div>
            )}
            {(!teamMembers || teamMembers.length === 0) && !universityPm && (
              <p className="text-gray-400">No team assigned</p>
            )}
          </dl>
        </div>

        {/* Description */}
        {project.description && (
          <div className="rounded-lg border border-gray-200 bg-white p-5">
            <h2 className="text-sm font-medium text-gray-700">Description</h2>
            <p className="mt-2 text-sm leading-relaxed text-gray-600">
              {project.description}
            </p>
          </div>
        )}
      </div>

      {/* Placeholder sections */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <div className="rounded-lg border border-dashed border-gray-300 bg-white p-8 text-center">
          <p className="text-sm font-medium text-gray-400">Schedule of Values</p>
          <p className="mt-1 text-xs text-gray-300">Coming in Phase 2</p>
        </div>
        <div className="rounded-lg border border-dashed border-gray-300 bg-white p-8 text-center">
          <p className="text-sm font-medium text-gray-400">Pay Applications</p>
          <p className="mt-1 text-xs text-gray-300">Coming in Phase 2</p>
        </div>
      </div>
    </div>
  )
}
