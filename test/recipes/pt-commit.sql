\i ../data/periodic_table.sql

select create_repository('pt');
update pt.periodic_table set "Discoverer" = 'This is a really long piece of text that is way longer than a hash, yo.' where "AtomicNumber" = 1;
select track_untracked_row('pt','pt','periodic_table','AtomicNumber', "AtomicNumber"::text) from pt.periodic_table where "AtomicNumber" < 3;
select stage_tracked_rows('pt');
select commit('pt', 'first 3 elements', 'Eric Hanson', 'eric@aquameta.com');
select status();
