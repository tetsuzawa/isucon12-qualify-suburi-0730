CREATE TABLE visit_history_2 AS
SELECT tenant_id, player_id, competition_id, MIN(created_at) AS created_at FROM visit_history GROUP BY tenant_id, player_id, competition_id;
ALTER TABLE visit_history RENAME TO visit_history_old;
ALTER TABLE visit_history_2 RENAME TO visit_history;
CREATE UNIQUE INDEX visit_history_idx ON visit_history(tenant_id, player_id, competition_id);