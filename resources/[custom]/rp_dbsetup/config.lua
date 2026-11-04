-- ============================================================
--  rp_dbsetup - settings
--  Scripts we download (like the police computer) come with a
--  .sql file that has to be run on the database once. Instead of
--  a database tool, put the file in this resource's sql/ folder
--  and add a line below. On the next start it runs once, and the
--  table rp_db_migrations remembers that it's done.
--
--  file    = the file name inside sql/
--  restart = a resource to restart right after (so it sees its new tables)
--
--  Never change or reuse a file name that already ran: give an
--  updated file a new name (ps-mdt_3.2.0.sql) and add a new line.
-- ============================================================
return {
    migrations = {
        { file = 'ps_lib_1.0.0_orm.sql' },                  -- small cache table for ps_lib (Nov 3, 2026)
        { file = 'ps-mdt_3.1.4.sql', restart = 'ps-mdt' }, -- Project Sloth police computer (Nov 3, 2026)
    },
}
