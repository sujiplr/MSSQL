1.	First find out and generated the statistics to be cleared for the tables.

select 'drop statistics '+ st.name + '.'+s.name+';' from market.sys.stats s,  market.sys.objects st  
where s.object_id=st.object_id and st.name in('x','y')

The above SQL will generate the stats to be dropped for the tables. So run the sqls generated from above sql for clearing the staistics.

2.	Gathered stats for the tables again.
update statistics dbo.x with fullscan      , all;
