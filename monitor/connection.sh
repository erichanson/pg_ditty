psql -c "select state, last_query, now() - query_start as running_time from meta.connection where database_name='ditty' and last_query not like '%pg_stat_user_functions%' and last_query not like '%running_time from meta.connection%' and last_query not like '%pg_stat_statement%'" ditty