import { createClient } from '@/lib/supabase-server'
import { getActiveOrg } from '@/lib/with-org'
import Link from 'next/link'

export default async function DashboardPage() {
  const { orgId } = await getActiveOrg()
  const supabase = await createClient()

  // Fetch counts
  const [assignmentsRes, projectsRes] = await Promise.all([
    supabase
      .from('campus_assignments')
      .select('id', { count: 'exact', head: true })
      .eq('org_id', orgId)
      .eq('status', 'active'),
    supabase
      .from('projects')
      .select('id', { count: 'exact', head: true })
      .eq('org_id', orgId)
      .in('status', ['pre_construction', 'active', 'punch_list']),
  ])

  const activeCampuses = assignmentsRes.count ?? 0
  const activeProjects = projectsRes.count ?? 0

  // Get upcoming billing dates
  const { data: upcomingBilling } = await supabase
    .from('projects')
    .select('id, name, billing_day')
    .eq('org_id', orgId)
    .eq('status', 'active')
    .not('billing_day', 'is', null)
    .order('billing_day')
    .limit(5)

  const cards = [
    {
      label: 'Active Campuses',
      value: activeCampuses,
      href: '/campuses',
    },
    {
      label: 'Active Projects',
      value: activeProjects,
      href: '/campuses',
    },
    {
      label: 'Open Pay Applications',
      value: '0',
      subtitle: 'Pay App module coming soon',
      href: '/payapp',
    },
  ]

  return (
    <div className="space-y-6">
      <h1 className="text-xl font-semibold text-gray-900">Dashboard</h1>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {cards.map((card) => (
          <Link
            key={card.label}
            href={card.href}
            className="rounded-lg border border-gray-200 bg-white p-5 transition-shadow hover:shadow-sm"
          >
            <p className="text-sm text-gray-500">{card.label}</p>
            <p className="mt-1 text-2xl font-semibold text-gray-900">
              {card.value}
            </p>
            {card.subtitle && (
              <p className="mt-1 text-xs text-gray-400">{card.subtitle}</p>
            )}
          </Link>
        ))}
      </div>

      {upcomingBilling && upcomingBilling.length > 0 && (
        <div className="rounded-lg border border-gray-200 bg-white p-5">
          <h2 className="text-sm font-medium text-gray-700">
            Upcoming Billing Dates
          </h2>
          <ul className="mt-3 space-y-2">
            {upcomingBilling.map((project) => (
              <li
                key={project.id}
                className="flex items-center justify-between text-sm"
              >
                <span className="text-gray-600">{project.name}</span>
                <span className="text-gray-400">
                  Day {project.billing_day} of each month
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}
