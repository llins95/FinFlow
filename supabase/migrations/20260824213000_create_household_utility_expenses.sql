create table if not exists public.household_utility_expenses (
  user_id uuid not null references auth.users (id) on delete cascade,
  year smallint not null check (year between 2000 and 2100),
  month smallint not null check (month between 1 and 12),
  water_in_cents integer not null default 0 check (water_in_cents >= 0),
  electricity_in_cents integer not null default 0
    check (electricity_in_cents >= 0),
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, year, month)
);

comment on table public.household_utility_expenses is
  'Controle residencial de agua e luz, isolado dos calculos financeiros do FinFlow.';

alter table public.household_utility_expenses enable row level security;

create or replace function public.set_household_utility_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_household_utility_updated_at
  on public.household_utility_expenses;

create trigger set_household_utility_updated_at
before update on public.household_utility_expenses
for each row
execute function public.set_household_utility_updated_at();

drop policy if exists "Users can read their own household utilities"
  on public.household_utility_expenses;
create policy "Users can read their own household utilities"
on public.household_utility_expenses
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own household utilities"
  on public.household_utility_expenses;
create policy "Users can insert their own household utilities"
on public.household_utility_expenses
for insert
to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own household utilities"
  on public.household_utility_expenses;
create policy "Users can update their own household utilities"
on public.household_utility_expenses
for update
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own household utilities"
  on public.household_utility_expenses;
create policy "Users can delete their own household utilities"
on public.household_utility_expenses
for delete
to authenticated
using ((select auth.uid()) = user_id);

grant all privileges on table public.household_utility_expenses to authenticated;
grant all privileges on table public.household_utility_expenses to service_role;

create or replace function public.upsert_household_utility_expense(
  p_year smallint,
  p_month smallint,
  p_water_in_cents integer,
  p_electricity_in_cents integer,
  p_client_updated_at timestamptz
)
returns setof public.household_utility_expenses
language sql
set search_path = ''
as $$
  insert into public.household_utility_expenses (
    user_id,
    year,
    month,
    water_in_cents,
    electricity_in_cents,
    client_updated_at
  )
  values (
    (select auth.uid()),
    p_year,
    p_month,
    p_water_in_cents,
    p_electricity_in_cents,
    p_client_updated_at
  )
  on conflict (user_id, year, month) do update
    set water_in_cents = excluded.water_in_cents,
        electricity_in_cents = excluded.electricity_in_cents,
        client_updated_at = excluded.client_updated_at
    where public.household_utility_expenses.client_updated_at
      <= excluded.client_updated_at
  returning *;
$$;

revoke all on function public.upsert_household_utility_expense(
  smallint,
  smallint,
  integer,
  integer,
  timestamptz
) from public, anon;

grant execute on function public.upsert_household_utility_expense(
  smallint,
  smallint,
  integer,
  integer,
  timestamptz
) to authenticated, service_role;

create or replace function public.reset_finflow_data(
  p_entries jsonb,
  p_client_updated_at timestamptz
)
returns setof public.financial_months
language plpgsql
set search_path = ''
as $$
begin
  delete from public.household_utility_expenses
  where user_id = (select auth.uid());

  delete from public.financial_months
  where user_id = (select auth.uid());

  return query
  insert into public.financial_months (
    user_id,
    year,
    month,
    entries,
    client_updated_at
  )
  values (
    (select auth.uid()),
    2100,
    12,
    p_entries,
    p_client_updated_at
  )
  returning *;
end;
$$;

revoke all on function public.reset_finflow_data(
  jsonb,
  timestamptz
) from public, anon;

grant execute on function public.reset_finflow_data(
  jsonb,
  timestamptz
) to authenticated, service_role;
