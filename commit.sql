------------------------------------------------------------------------------
-- COMMIT
------------------------------------------------------------------------------

--
-- commit_ancestry()
--

create type _commit_ancestry as( commit_id uuid, position integer );
create or replace function _commit_ancestry( _commit_id uuid ) returns setof _commit_ancestry as $$
    with recursive parent as (
        select c.id, c.parent_id, 1 as position from commit c where c.id=_commit_id
        union
        select c.id, c.parent_id, p.position + 1 from commit c join parent p on c.id = p.parent_id
    ) select id, position from parent
$$ language sql;


--
-- commit()
--

create function _commit(
    _repository_id uuid,
    message text,
    author_name text,
    author_email text,
    parent_commit_id uuid default null
) returns uuid as $$
    declare
        new_commit_id uuid;
        parent_commit_id uuid;
        first_commit boolean := false;
    begin
        if not delta._repository_exists(_repository_id) then
            raise exception 'Repository with id % does not exist.', _repository_id;
        end if;

        -- if no parent_commit_id is supplied, use head pointer
        if parent_commit_id is null then
            select head_commit_id from delta.repository where id = _repository_id into parent_commit_id;
        end if;

        -- if repository has no head commit and one is not supplied, either this is the first
        -- commit, or there is a problem
        if parent_commit_id is null then
            if delta._repository_has_commits(_repository_id) then
                raise exception 'No parent_commit_id supplied, and repository''s head_commit_id is null.  Please specify a parent commit_id for this commit.';
            else
                raise notice 'First commit!';
                first_commit := true;
            end if;
        end if;

        -- create the commit
        insert into delta.commit (
            repository_id,
            message,
            author_name,
            author_email,
            parent_id
        ) values (
            _repository_id,
            message,
            author_name,
            author_email,
            parent_commit_id
        )
        returning id into new_commit_id;

        -- update head pointer, checkout pointer
        update delta.repository set head_commit_id = new_commit_id, checkout_commit_id = new_commit_id;

        -- commit_row_added
        insert into delta.commit_row_added (commit_id, row_id, position)
        select new_commit_id, row_id, 0 from delta.stage_row_added where repository_id = _repository_id;

        delete from delta.stage_row_added where repository_id = _repository_id;

        -- commit_row_deleted
        insert into delta.commit_row_deleted (commit_id, row_id, position)
        select new_commit_id, row_id, 0 from delta.stage_row_deleted where repository_id = _repository_id;

        delete from delta.stage_row_deleted where repository_id = _repository_id;

    /*
        insert into commit_field gtgt
        insert into commit_row_deleted
        insert into commit_field_changed
        */

        return new_commit_id;
    end;
$$ language plpgsql;


create function commit(
    repository_name text,
    message text,
    author_name text,
    author_email text,
    parent_commit_id uuid default null
)
returns uuid as $$
    select delta._commit(id, message, author_name, author_email, parent_commit_id)
    from delta.repository where name=repository_name;
$$ language sql;