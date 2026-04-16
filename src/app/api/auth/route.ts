import { createAdminClient } from '@/lib/supabase-server'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const body = await request.json()

  if (body.action === 'setup_org') {
    const { org_name, user_id } = body

    if (!org_name || !user_id) {
      return NextResponse.json(
        { error: 'org_name and user_id are required' },
        { status: 400 }
      )
    }

    const supabase = createAdminClient()

    // Create organization
    const { data: org, error: orgError } = await supabase
      .from('organizations')
      .insert({ name: org_name })
      .select('id')
      .single()

    if (orgError) {
      return NextResponse.json(
        { error: orgError.message },
        { status: 500 }
      )
    }

    // Create org membership (owner)
    const { error: memberError } = await supabase
      .from('org_members')
      .insert({
        org_id: org.id,
        user_id,
        role: 'owner',
        accepted_at: new Date().toISOString(),
      })

    if (memberError) {
      return NextResponse.json(
        { error: memberError.message },
        { status: 500 }
      )
    }

    // Update profile role to owner
    const { error: profileError } = await supabase
      .from('profiles')
      .update({ role: 'owner' })
      .eq('id', user_id)

    if (profileError) {
      return NextResponse.json(
        { error: profileError.message },
        { status: 500 }
      )
    }

    return NextResponse.json({ org_id: org.id })
  }

  return NextResponse.json({ error: 'Unknown action' }, { status: 400 })
}
