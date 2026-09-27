-- TrailPath v1.4 Cloud Sync schema template.
-- Apply to a dedicated Supabase project only after reviewing provider,
-- retention and production privacy requirements.

create table if not exists public.trailpath_sync_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null check (
    entity_type in ('route', 'activity', 'preferences')
  ),
  entity_id text not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  payload jsonb,
  primary key (user_id, entity_type, entity_id)
);

alter table public.trailpath_sync_items enable row level security;

revoke all on table public.trailpath_sync_items from anon;
grant select, insert, update, delete
  on table public.trailpath_sync_items
  to authenticated;

drop policy if exists "trailpath_sync_select_own"
  on public.trailpath_sync_items;
create policy "trailpath_sync_select_own"
  on public.trailpath_sync_items
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "trailpath_sync_insert_own"
  on public.trailpath_sync_items;
create policy "trailpath_sync_insert_own"
  on public.trailpath_sync_items
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "trailpath_sync_update_own"
  on public.trailpath_sync_items;
create policy "trailpath_sync_update_own"
  on public.trailpath_sync_items
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "trailpath_sync_delete_own"
  on public.trailpath_sync_items;
create policy "trailpath_sync_delete_own"
  on public.trailpath_sync_items
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create index if not exists trailpath_sync_items_updated_idx
  on public.trailpath_sync_items (user_id, updated_at desc);
