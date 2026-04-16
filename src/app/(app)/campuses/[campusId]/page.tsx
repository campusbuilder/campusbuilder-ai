import { createClient } from '@/lib/supabase-server'
import { getActiveOrg } from '@/lib/with-org'
import Link from 'next/link'
import { notFound } from 'next/navigation'

export default async function CampusDetailPage({
  params,
}: {
  params: Promise<{ campusId: string }>
}) {
  const { campusId } = await params
  const { orgId } = await getActiveOrg()
  const supabase = await createClient()

  // Get campus with university
  const { data: campus } = await supabase
    .from('campuses')
    .select(`
      id, name, city, state, address, is_main_campus,
      university:universities ( id, name, abbreviation, facilities_dept_name, website )
    `)
    .eq('id', campusId)
    .single()

  if (!campus) notFound()

  // Supabase returns joined relations as arrays; unwrap to single object
  const university = (Array.isArray(campus.university)
    ? campus.university[0]
    : campus.university) as Record<string, unknown> | null

  // Get assignment for this campus
  const { data: assignment } = await supabase
    .from('campus_assignments')
    .select('*')
    .eq('org_id', orgId)
    .eq('campus_id', campusId)
    .single()

  // Get facility contacts
  const { data: contacts } = await supabase
    .from('facility_contacts')
    .select('*')
    .eq('university_id', university?.id as string)
    .or(`campus_id.eq.${campusId},campus_id.is.null`)
    .order('is_primary', { ascending: false })

  // Get projects
  const { data: projects } = await supabase
    .from('projects')
    .select('id, name, contract_type, contract_amount, gmp_amount, status, notice_to_proceed')
    .eq('org_id', orgId)
    .eq('campus_id', campusId)
    .order('created_at', { ascending: false })

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

  return (
    <div className="space-y-6">
      <div>
        <Link
          href="/campuses"
          className="text-sm text-gray-500 hover:text-gray-700"
        >
          &larr; Campuses
        </Link>
        <h1 className="mt-1 text-xl font-semibold text-gray-900">
          {campus.name}
        </h1>
        <p className="text-sm text-gray-500">
          {(university?.name as string) ?? ''} &middot; {campus.city},{' '}
          {campus.state}
        </p>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* University Info */}
        <div className="rounded-lg border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-medium text-gray-700">
            University Info
          </h2>
          <dl className="mt-3 space-y-2 text-sm">
            <div className="flex justify-between">
              <dt className="text-gray-500">Institution</dt>
              <dd className="text-gray-900">{university?.name as string}</dd>
            </div>
            {university?.facilities_dept_name && (
              <div className="flex justify-between">
                <dt className="text-gray-500">Facilities Dept</dt>
                <dd className="text-gray-900">
                  {university.facilities_dept_name as string}
                </dd>
              </div>
            )}
            {assignment && (
              <>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Contract #</dt>
                  <dd className="text-gray-900">
                    {assignment.contract_number ?? '—'}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Per-Project Cap</dt>
                  <dd className="text-gray-900">
                    {assignment.per_project_cap
                      ? `$${Number(assignment.per_project_cap).toLocaleString()}`
                      : '—'}
                  </dd>
                </div>
                <div className="flex justify-between">
                  <dt className="text-gray-500">Contract Period</dt>
                  <dd className="text-gray-900">
                    {assignment.contract_start} — {assignment.contract_end}
                  </dd>
                </div>
              </>
            )}
          </dl>
        </div>

        {/* Facility Contacts */}
        <div className="rounded-lg border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-medium text-gray-700">
            Facility Contacts
          </h2>
          {contacts && contacts.length > 0 ? (
            <ul className="mt-3 space-y-3">
              {contacts.map((c) => (
                <li key={c.id} className="text-sm">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-gray-900">{c.name}</span>
                    {c.is_primary && (
                      <span className="rounded bg-blue-50 px-1.5 py-0.5 text-xs text-blue-600">
                        Primary
                      </span>
                    )}
                  </div>
                  <p className="text-gray-500">{c.title}</p>
                  {c.email && (
                    <p className="text-gray-400">{c.email}</p>
                  )}
                </li>
              ))}
            </ul>
          ) : (
            <p className="mt-3 text-sm text-gray-400">No contacts on file</p>
          )}
        </div>
      </div>

      {/* Projects */}
      <div className="rounded-lg border border-gray-200 bg-white">
        <div className="border-b border-gray-100 px-5 py-3">
          <h2 className="text-sm font-medium text-gray-700">Projects</h2>
        </div>
        {projects && projects.length > 0 ? (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50 text-left">
                <th className="px-4 py-2 font-medium text-gray-600">Name</th>
                <th className="px-4 py-2 font-medium text-gray-600">Type</th>
                <th className="px-4 py-2 font-medium text-gray-600 text-right">
                  Contract Value
                </th>
                <th className="px-4 py-2 font-medium text-gray-600">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {projects.map((p) => (
                <tr key={p.id} className="hover:bg-gray-50">
                  <td className="px-4 py-2">
                    <Link
                      href={`/campuses/${campusId}/projects/${p.id}`}
                      className="text-blue-600 hover:underline"
                    >
                      {p.name}
                    </Link>
                  </td>
                  <td className="px-4 py-2 text-gray-600">
                    {contractTypeLabels[p.contract_type] ?? p.contract_type}
                  </td>
                  <td className="px-4 py-2 text-right text-gray-600">
                    {p.contract_amount
                      ? `$${Number(p.contract_amount).toLocaleString()}`
                      : p.gmp_amount
                        ? `$${Number(p.gmp_amount).toLocaleString()} GMP`
                        : 'Cost Plus'}
                  </td>
                  <td className="px-4 py-2">
                    <span
                      className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${statusColors[p.status] ?? 'bg-gray-100 text-gray-600'}`}
                    >
                      {p.status.replace('_', ' ')}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="px-5 py-4 text-sm text-gray-400">
            No projects on this campus yet.
          </p>
        )}
      </div>
    </div>
  )
}
