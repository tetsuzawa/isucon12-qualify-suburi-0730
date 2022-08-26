ALTER TABLE visit_history
    DROP INDEX tenant_id_idx,
    ADD INDEX tenant_id_idx (tenant_id, competition_id, player_id, created_at);
