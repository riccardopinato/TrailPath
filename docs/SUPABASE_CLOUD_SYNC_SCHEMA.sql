-- TrailPath v1.4 Cloud Sync schema template.
-- Apply to a dedicated Supabase project only after reviewing provider,
-- retention and production privacy requirements.

create table if not exists public.trailpath_sync_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_type text not null check (
    entity_type in ('route', 'activity', 'preferences', 'collection')
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


-- Account deletion endpoint used by the in-app deletion flow.
-- SECURITY DEFINER is required because authenticated clients cannot delete
-- auth.users directly. The function accepts no user-supplied identifier and
-- derives the target exclusively from auth.uid(), preventing cross-account
-- deletion. trailpath_sync_items is removed by ON DELETE CASCADE.
create or replace function public.delete_my_trailpath_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then
    raise exception 'authentication required';
  end if;

  delete from auth.users
  where id = current_user_id;
end;
$$;

revoke all on function public.delete_my_trailpath_account() from public;
revoke all on function public.delete_my_trailpath_account() from anon;
grant execute on function public.delete_my_trailpath_account() to authenticated;
