import { createClient } from '@/lib/supabase-server'
import { getActiveOrg } from '@/lib/with-org'
import Link from 'next/link'

export default async function CampusesPage() {
  const { orgId } = await getActiveOrg()
  const supabase = await createClient()

  // Get campus assignments with campus and university details
  const { data: assignments } = await supabase
    .from('campus_assignments')
    .select(`
      id, contract_type, status, per_project_cap,
      campus:campuses (
        id, name, city, state,
        university:universities ( name, abbreviation )
      )
    `)
    .eq('org_id', orgId)
    .order('created_at', { ascending: false })

  // Get project counts per campus
  const { data: projectCounts } = await supabase
    .from('projects')
    .select('campus_id')
    .eq('org_id', orgId)
    .in('status', ['pre_construction', 'active', 'punch_list', 'closeout'])

  const countMap = new Map<string, number>()
  projectCounts?.forEach((p) => {
    countMap.set(p.campus_id, (countMap.get(p.campus_id) ?? 0) + 1)
  })

  const contractTypeLabels: Record<string, string> = {
    continuing_services: 'Continuing Services',
    hard_bid: 'Hard Bid',
    design_build: 'Design-Build',
    cmar: 'CMAR',
  }

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-semibold text-gray-900">Campuses</h1>

      {!assignments || assignments.length === 0 ? (
        <div className="rounded-lg border border-gray-200 bg-white p-8 text-center text-sm text-gray-500">
          No campus assignments yet. Contact support to set up your first campus
          contract.
        </div>
      ) : (
        <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50 text-left">
                <th className="px-4 py-3 font-medium text-gray-600">
                  University
                </th>
                <th className="px-4 py-3 font-medium text-gray-600">Campus</th>
                <th className="px-4 py-3 font-medium text-gray-600">
                  Contract Type
                </th>
                <th className="px-4 py-3 font-medium text-gray-600 text-right">
                  Project Cap
                </th>
                <th className="px-4 py-3 font-medium text-gray-600 text-right">
                  Projects
                </th>
                <th className="px-4 py-3 font-medium text-gray-600">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {assignments.map((a: any) => {
                const campus = Array.isArray(a.campus) ? a.campus[0] : a.campus
                const university = campus?.university
                  ? (Array.isArray(campus.university) ? campus.university[0] : campus.university)
                  : null
                const campusId = campus?.id as string
                return (
                  <tr key={a.id as string} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-900">
                      {(university?.name as string) ?? '—'}
                      {university?.abbreviation && (
                        <span className="ml-1 text-gray-400">
                          ({university.abbreviation as string})
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <Link
                        href={`/campuses/${campusId}`}
                        className="text-blue-600 hover:underline"
                      >
                        {(campus?.name as string) ?? '—'}
                      </Link>
                    </td>
                    <td className="px-4 py-3 text-gray-600">
                      {contractTypeLabels[a.contract_type as string] ??
                        (a.contract_type as string)}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-600">
                      {a.per_project_cap
                        ? `$${Number(a.per_project_cap).toLocaleString()}`
                        : '—'}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-600">
                      {countMap.get(campusId) ?? 0}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                          a.status === 'active'
                            ? 'bg-green-50 text-green-700'
                            : a.status === 'pending'
                              ? 'bg-yellow-50 text-yellow-700'
                              : 'bg-gray-100 text-gray-600'
                        }`}
                      >
                        {a.status as string}
                      </span>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
