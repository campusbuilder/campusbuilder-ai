import { createClient } from './supabase-server'
import { redirect } from 'next/navigation'
import { cookies } from 'next/headers'

const ACTIVE_ORG_COOKIE = 'cb_active_org'

/**
 * Get the current user's active org ID.
 * Redirects to login if not authenticated.
 * Returns the org_id from cookie, or falls back to the user's first org.
 */
export async function getActiveOrg(): Promise<{
  orgId: string
  userId: string
}> {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  const cookieStore = await cookies()
  const storedOrgId = cookieStore.get(ACTIVE_ORG_COOKIE)?.value

  if (storedOrgId) {
    // Verify the user still belongs to this org
    const { data: membership } = await supabase
      .from('org_members')
      .select('org_id')
      .eq('org_id', storedOrgId)
      .eq('user_id', user.id)
      .single()

    if (membership) {
      return { orgId: membership.org_id, userId: user.id }
    }
  }

  // Fallback: get the user's first org
  const { data: firstMembership } = await supabase
    .from('org_members')
    .select('org_id')
    .eq('user_id', user.id)
    .order('invited_at', { ascending: true })
    .limit(1)
    .single()

  if (!firstMembership) {
    // User has no org — this shouldn't happen after signup flow
    redirect('/login')
  }

  return { orgId: firstMembership.org_id, userId: user.id }
}

export async function setActiveOrg(orgId: string) {
  const cookieStore = await cookies()
  cookieStore.set(ACTIVE_ORG_COOKIE, orgId, {
    path: '/',
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 60 * 60 * 24 * 365, // 1 year
  })
}
