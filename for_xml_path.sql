with q as (
	select l.lease_number
		 , rc.criteria_code
	  from leases l
	 cross apply legit_leases(l.lease_number, default) ll
	 cross apply rebooks_core(l.lease_number, default, default) rc
	 where l.received_date > '20050101'
	 
	 union all
	select r.orig_lease collate Latin1_General_CS_AS
		 , r.criteria_code
	  from rebooks r
	 where criteria_code not in ('a','b','c')

	 union all
	select superseded collate Latin1_General_CS_AS
		 , '-'
	  from leases l 
	  join rebooked_leases rl 
	    on l.lease_number collate Latin1_General_CS_AS = rl.superseded
	 cross apply legit_leases(l.lease_number, default) ll
	 cross apply accounts_multi_lease(l.account_number) aml
)
, uniq as (select distinct lease_number, criteria_code from q)
, uniq_leases as (select distinct lease_number from q)
select lease_number
	 , stuff((select ', ' + uniq.criteria_code as [text()]
			    from uniq 
			   where uniq.lease_number = uniq_leases.lease_number
			     for xml path('')
			 ), 1, 1, '') as matched_criteria
from uniq_leases