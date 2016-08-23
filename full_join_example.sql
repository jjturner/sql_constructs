USE [RDB_CUSTOM]
GO

/****** Object:  View [dbo].[v_writeoff_components_by_lifecycle]    Script Date: 8/11/2016 11:09:41 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER view [dbo].[v_writeoff_components_by_lifecycle]
as
with q1 as (
		select ll.lease_number
			 , l.received_date
			 , lm.lifecycle_month
			 , sum(tde.expense_amount) base_writeoff
		  from leases l
   cross apply legit_leases(l.lease_number, default) ll
   outer apply transfer_dates(ll.lease_number) td
   outer apply transfer_distribution_expenses(l.lease_number, l.received_date, eomonth(isnull(td.transfer_date,'19700131'))) tde
   outer apply (select datediff(MM, l.received_date, tde.effective_date) + 1 lifecycle_month) lm
      group by ll.lease_number
			 , l.received_date
			 , lm.lifecycle_month
)
, q2 as (
		select ll.lease_number
			 , l.received_date
			 , lm.lifecycle_month
			 , sum(bda.amount) bad_debt_adj
		  from leases l
   cross apply legit_leases(l.lease_number, default) ll
   outer apply transfer_dates(ll.lease_number) td
   outer apply bad_debt_adjustments(l.lease_number, l.received_date, eomonth(isnull(td.transfer_date,'19700131'))) bda
   outer apply (select datediff(MM, l.received_date, bda.effective_date) + 1 lifecycle_month) lm
      group by ll.lease_number
			 , l.received_date
			 , lm.lifecycle_month
)
, q3 as (
		select ll.lease_number
			 , l.received_date
			 , lm.lifecycle_month
			 , sum(cb.chargeback_amount) cb_amt
			 , sum(cb.chargeback_paid) cb_paid
		  from leases l
   cross apply legit_leases(l.lease_number, default) ll
   outer apply transfer_dates(ll.lease_number) td
   outer apply chargebacks(l.lease_number, l.received_date, eomonth(isnull(td.transfer_date,'19700131'))) cb
   outer apply (select datediff(MM, l.received_date, cb.check_cut_date) + 1 lifecycle_month) lm
      group by ll.lease_number
			 , l.received_date
			 , lm.lifecycle_month
)
, q4 as (
		select ll.lease_number
			 , l.received_date
			 , lm.lifecycle_month
			 , sum(cr.amount) cash_recovery
		  from leases l
   cross apply legit_leases(l.lease_number, default) ll
   outer apply transfer_dates(ll.lease_number) td
   outer apply cash_recovery(l.lease_number, l.received_date, eomonth(isnull(td.transfer_date,'19700131'))) cr
   outer apply (select datediff(MM, l.received_date, cr.effective_date) + 1 lifecycle_month) lm
      group by ll.lease_number
		     , l.received_date
			 , lm.lifecycle_month
)
, agg1 as (
	select coalesce(q1.lease_number, q2.lease_number, q3.lease_number, q4.lease_number) lease_number 
		 , cast(coalesce(q1.received_date,q2.received_date,q3.received_date,q4.received_date) as date) received_date
		 , coalesce(q1.lifecycle_month, q2.lifecycle_month, q3.lifecycle_month, q4.lifecycle_month) lifecycle_month
		 , q1.base_writeoff
		 , q2.bad_debt_adj
		 , q3.cb_amt
		 , q3.cb_paid
		 , q4.cash_recovery
	  from q2 full join q1 on q2.lease_number    = q1.lease_number
						  and q2.lifecycle_month = q1.lifecycle_month
			  full join q3 on q1.lease_number    = q3.lease_number
			              and q1.lifecycle_month = q3.lifecycle_month
						  and q2.lease_number    = q3.lease_number
						  and q2.lifecycle_month = q3.lifecycle_month
			  full join q4 on q1.lease_number    = q4.lease_number
						  and q1.lifecycle_month = q4.lifecycle_month
						  and q2.lease_number    = q4.lease_number
						  and q2.lifecycle_month = q4.lifecycle_month
						  and q3.lease_number    = q4.lease_number
						  and q3.lifecycle_month = q4.lifecycle_month
	 where coalesce(q1.lifecycle_month, q2.lifecycle_month, q3.lifecycle_month, q4.lifecycle_month) is not null
)
    select lease_number
		 , received_date
		 , lifecycle_month
		 , sum(base_writeoff) base_writeoff
		 , sum(bad_debt_adj)  bad_debt_adj
		 , sum(cb_amt)		  cb_amt
		 , sum(cb_paid)		  cb_paid
		 , sum(cash_recovery) cash_recovery
	  from agg1
  group by lease_number
		 , received_date
		 , lifecycle_month
GO


