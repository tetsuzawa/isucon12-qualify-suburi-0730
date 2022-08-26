CREATE TABLE player_score_tmp AS SELECT player_id, competition_id, MAX(row_num) AS row_num FROM player_score GROUP BY player_id, competition_id;
CREATE TABLE player_score_new AS SELECT player_score.* FROM player_score JOIN player_score_tmp USING(player_id, competition_id, row_num);
DROP TABLE player_score;
DROP TABLE player_score_tmp;
ALTER TABLE player_score_new RENAME TO player_score;
VACUUM;