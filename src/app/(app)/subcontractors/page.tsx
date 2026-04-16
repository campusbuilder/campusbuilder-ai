import { createClient } from '@/lib/supabase-server'
import { getActiveOrg } from '@/lib/with-org'

export default async function SubcontractorsPage() {
  const { orgId } = await getActiveOrg()
  const supabase = await createClient()

  const { data: subs } = await supabase
    .from('subcontractors')
    .select('*')
    .eq('org_id', orgId)
    .order('company_name')

  const minorityBadge: Record<string, string> = {
    MBE: 'bg-blue-50 text-blue-700',
    WBE: 'bg-purple-50 text-purple-700',
    SBE: 'bg-green-50 text-green-700',
    VBE: 'bg-red-50 text-red-700',
  }

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-semibold text-gray-900">Subcontractors</h1>

      {!subs || subs.length === 0 ? (
        <div className="rounded-lg border border-gray-200 bg-white p-8 text-center text-sm text-gray-500">
          No subcontractors registered yet.
        </div>
      ) : (
        <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50 text-left">
                <th className="px-4 py-3 font-medium text-gray-600">
                  Company
                </th>
                <th className="px-4 py-3 font-medium text-gray-600">Trade</th>
                <th className="px-4 py-3 font-medium text-gray-600">
                  Contact
                </th>
                <th className="px-4 py-3 font-medium text-gray-600">
                  Certifications
                </th>
                <th className="px-4 py-3 font-medium text-gray-600">
                  Prequalified
                </th>
                <th className="px-4 py-3 font-medium text-gray-600">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {subs.map((sub) => (
                <tr key={sub.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-900">
                    {sub.company_name}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {sub.trade ?? '—'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="text-gray-900">{sub.contact_name}</div>
                    {sub.email && (
                      <div className="text-xs text-gray-400">{sub.email}</div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {sub.minority_status &&
                    sub.minority_status !== 'none' ? (
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${minorityBadge[sub.minority_status] ?? 'bg-gray-100 text-gray-600'}`}
                      >
                        {sub.minority_status}
                      </span>
                    ) : (
                      <span className="text-gray-400">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {sub.prequalified ? 'Yes' : 'No'}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                        sub.status === 'active'
                          ? 'bg-green-50 text-green-700'
                          : 'bg-gray-100 text-gray-600'
                      }`}
                    >
                      {sub.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
