-- using 
-- mm(mnth) as (
-- 	select mnth from (values('01'), ('02'), ('03'), ('04'), ('05'), ('06'), ('07'), ('08'), ('09'), ('10'), ('11'), ('12') )
-- )
-- , yyyy(yr) as (
-- 	select yr from (values('2005'), ('2006'), ('2007'), ('2008'), ('2009'), ('2010'), ('2011'), ('2012'), ('2013'), ('2014'), ('2015'), ('2016'))
-- )
-- select mnth ym_tag
-- from mm;

-- select a from (values (1),(2),(3)) as test(a);

-- insert into ##month_series (ym_tag)
select cast(concat(yr,mnth) as int) ym_tag
-- into ##month_series
from (values('01'), ('02'), ('03'), ('04'), ('05'), ('06'), ('07'), ('08'), ('09'), ('10'), ('11'), ('12') ) as mm(mnth),
(values('2005'), ('2006'), ('2007'), ('2008'), ('2009'), ('2010'), ('2011'), ('2012'), ('2013'), ('2014'), ('2015'), ('2016')) as yyyy(yr)