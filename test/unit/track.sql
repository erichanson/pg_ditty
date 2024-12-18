select '------------- track.sql --------------------------------------------------';

/*
 * Tracking and untracking
 */

-- track one row
do $$ begin
    perform ditty.track_untracked_row('io.pgditty.unittest', meta.row_id('pt', 'periodic_table', 'AtomicNumber', '7'));
end $$ language plpgsql;

select ok(
    (select ditty._is_newly_tracked(
        ditty.repository_id('io.pgditty.unittest'),
        meta.row_id('pt', 'periodic_table', 'AtomicNumber', '7'))),
    '_is_newly_tracked() finds row added by track_untracked_row()'
);

select is(
    (select count(*)::integer from ditty._get_tracked_rows_added(ditty.repository_id('io.pgditty.unittest'))),
    (select 1),
    'One tracked row after it is added.'
);


select ok(
    (select not ditty._is_newly_tracked(
        ditty.repository_id('io.pgditty.unittest'),
        meta.row_id('pt', 'periodic_table', 'AtomicNumber', '8'))),
    '_is_newly_tracked() doesn''t finds untracked row'
);


-- track again
select throws_ok(
    $$ select ditty.track_untracked_row('io.pgditty.unittest', meta.row_id('pt', 'periodic_table', 'AtomicNumber', '7')); $$,
    format('Row with row_id %s is already tracked.', meta.row_id('pt', 'periodic_table', 'AtomicNumber', '7')::text)
);


-- track a row in a non-table
do $$ begin
    perform ditty.track_untracked_row('io.pgditty.unittest', meta.row_id('unittest', 'not_a_table', 'a', '1'));
end $$ language plpgsql;

select ok(
    (select ditty._is_newly_tracked(
        ditty.repository_id('io.pgditty.unittest'),
        meta.row_id('unittest', 'not_a_table', 'a', '1'))),
    '_is_newly_tracked() finds non-table row added by track_untracked_row()'
);



-- remove row that is tracked
do $$ begin
    perform ditty.untrack_tracked_row('io.pgditty.unittest', meta.row_id('pt', 'periodic_table', 'AtomicNumber', '7'));
end $$ language plpgsql;

select ok(
    (select not ditty._is_newly_tracked(
        ditty.repository_id('io.pgditty.unittest'),
        meta.row_id('pt', 'periodic_table', 'AtomicNumber', '7'))),
    '_is_newly_tracked() cannot find row after removal by untrack_tracked_row()'
);


-- remove non-table row that is tracked
do $$ begin
    perform ditty.untrack_tracked_row('io.pgditty.unittest', meta.row_id('unittest', 'not_a_table', 'a', '1'));
end $$ language plpgsql;

select ok(
    (select not ditty._is_newly_tracked(
        ditty.repository_id('io.pgditty.unittest'),
        meta.row_id('pt', 'not_a_table', 'a', '1'))),
    '_is_newly_tracked() cannot find non-table row, after removal by untrack_tracked_row()'
);

-- remove row that isn't tracked
select throws_ok(
    $$ select ditty._untrack_tracked_row(ditty.repository_id('io.pgditty.unittest'), meta.row_id('pt', 'periodic_table', 'AtomicNumber', '3'::text)) $$,
    format(
        'Row with row_id %s cannot be removed because it is not tracked by supplied repository.',
        meta.row_id('pt','periodic_table','AtomicNumber','3')
    )
);

-- _get_tracked_rows_added
select is(
    (select count(*)::integer from ditty._get_tracked_rows_added(ditty.repository_id('io.pgditty.unittest'))),
    (select 0),
    'No tracked rows after they are removed'
);


-- _get_tracked_rows
select is(
    (select count(*)::integer from ditty._get_tracked_rows_added(ditty.repository_id('io.pgditty.unittest'))),
    (select 0),
    'Before there is a commit there are no tracked rows.'
);

-- TODO: test get_tracked_rows after commit.

-- clear nontable relation (cleanup)
do $$ begin
    perform ditty._untrack_nontable_relation(meta.relation_id('unittest','not_a_table'));
end $$ language plpgsql;


