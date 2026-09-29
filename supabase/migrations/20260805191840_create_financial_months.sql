create table if not exists public.financial_months (
  user_id uuid not null references auth.users (id) on delete cascade,
  year smallint not null check (year between 2026 and 2100),
  month smallint not null check (month between 1 and 12),
  entries jsonb not null default '[]'::jsonb
    check (jsonb_typeof(entries) = 'array'),
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, year, month)
);

comment on table public.financial_months is
  'Meses financeiros pessoais sincronizados pelo FinFlow.';

alter table public.financial_months enable row level security;

create or replace function public.set_financial_month_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_financial_month_updated_at
  on public.financial_months;

create trigger set_financial_month_updated_at
before update on public.financial_months
for each row
execute function public.set_financial_month_updated_at();

drop policy if exists "Users can read their own financial months"
  on public.financial_months;
create policy "Users can read their own financial months"
on public.financial_months
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own financial months"
  on public.financial_months;
create policy "Users can insert their own financial months"
on public.financial_months
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own financial months"
  on public.financial_months;
create policy "Users can update their own financial months"
on public.financial_months
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own financial months"
  on public.financial_months;
create policy "Users can delete their own financial months"
on public.financial_months
for delete
to authenticated
using ((select auth.uid()) = user_id);

grant all privileges on table public.financial_months to authenticated;
grant all privileges on table public.financial_months to service_role;

create or replace function public.upsert_financial_month(
  p_year smallint,
  p_month smallint,
  p_entries jsonb,
  p_client_updated_at timestamptz
)
returns setof public.financial_months
language sql
set search_path = ''
as $$
  insert into public.financial_months (
    user_id,
    year,
    month,
    entries,
    client_updated_at
  )
  values (
    (select auth.uid()),
    p_year,
    p_month,
    p_entries,
    p_client_updated_at
  )
  on conflict (user_id, year, month) do update
    set entries = excluded.entries,
        client_updated_at = excluded.client_updated_at
    where public.financial_months.client_updated_at
      <= excluded.client_updated_at
  returning *;
$$;

revoke all on function public.upsert_financial_month(
  smallint,
  smallint,
  jsonb,
  timestamptz
) from public, anon;

grant execute on function public.upsert_financial_month(
  smallint,
  smallint,
  jsonb,
  timestamptz
) to authenticated, service_role;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'financial_months'
  ) then
    alter publication supabase_realtime
      add table public.financial_months;
  end if;
end;
$$;
