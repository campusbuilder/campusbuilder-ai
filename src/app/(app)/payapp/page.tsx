export default function PayAppPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-xl font-semibold text-gray-900">Pay Applications</h1>
      <div className="rounded-lg border border-dashed border-gray-300 bg-white p-12 text-center">
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-gray-100">
          <svg className="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v12m-3-2.818.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
          </svg>
        </div>
        <h2 className="mt-4 text-sm font-medium text-gray-600">
          Pay App Module — Coming in Phase 2
        </h2>
        <p className="mt-1 text-sm text-gray-400">
          G702/G703 pay applications with full SOV management, change order tracking,
          and sub billing. Database schema is ready.
        </p>
      </div>
    </div>
  )
}
