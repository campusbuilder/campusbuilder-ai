'use client'

import { createClient } from '@/lib/supabase-browser'
import { useRouter } from 'next/navigation'
import { useState, useEffect } from 'react'

export default function Header({ orgName }: { orgName?: string }) {
  const [userEmail, setUserEmail] = useState<string | null>(null)
  const [showMenu, setShowMenu] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      setUserEmail(user?.email ?? null)
    })
  }, [supabase.auth])

  async function handleSignOut() {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <header className="flex h-14 items-center justify-between border-b border-gray-200 bg-white px-6">
      <div className="text-sm font-medium text-gray-700">
        {orgName || 'CampusBuilder'}
      </div>

      <div className="relative">
        <button
          onClick={() => setShowMenu(!showMenu)}
          className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-100 text-xs font-medium text-blue-700 hover:bg-blue-200"
        >
          {userEmail ? userEmail[0].toUpperCase() : '?'}
        </button>

        {showMenu && (
          <div className="absolute right-0 top-10 z-50 w-48 rounded-md border border-gray-200 bg-white py-1 shadow-lg">
            {userEmail && (
              <div className="border-b border-gray-100 px-3 py-2 text-xs text-gray-500">
                {userEmail}
              </div>
            )}
            <button
              onClick={handleSignOut}
              className="w-full px-3 py-2 text-left text-sm text-gray-700 hover:bg-gray-50"
            >
              Sign out
            </button>
          </div>
        )}
      </div>
    </header>
  )
}
