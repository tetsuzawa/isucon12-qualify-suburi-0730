CREATE INDEX player_score_tenant_id_competition_id_player_id_index ON player_score (tenant_id, competition_id(128), player_id(128));
