revoke all privileges on table public.financial_months from anon;

revoke execute on function public.upsert_financial_month(
  smallint,
  smallint,
  jsonb,
  timestamptz
) from anon;

grant execute on function public.upsert_financial_month(
  smallint,
  smallint,
  jsonb,
  timestamptz
) to authenticated, service_role;
