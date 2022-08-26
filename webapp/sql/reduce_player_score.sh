for i in `seq 1 100`; do
  echo ${i}
  sqlite3 /home/isucon/initial_data/${i}.db < /home/isucon/webapp/sql/tenant/11_reduce_player_score.sql
done