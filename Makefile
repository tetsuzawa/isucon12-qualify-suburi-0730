include env.sh
include taki.env

APP_NAME := isuports
APP_LOG := /var/log/app/app.log

MYSQL := mysql -h$(MYSQL_HOST) -P$(MYSQL_PORT) -u$(MYSQL_USER) -p$(MYSQL_PASS) $(MYSQL_DBNAME)
MYSQL_SLOW_LOG := /var/log/mysql/mysqld-slow.log
MYSQL_ERROR_LOG := /var/log/mysql/error.log

NGINX_ACCESS_LOG := /var/log/nginx/access_log.ltsv
NGINX_ERROR_LOG := /var/log/nginx/error.log

SLACKCAT := slackcat
SLACKCAT_OAUTH := slackcat-oauth
COMMIT_HASH := $(shell git rev-parse --short HEAD)
HOSTNAME := $(shell hostname)



all-a:
	make log_rotate-a
	git pull
	make build-app
	make restart-a
	make slow-on
	make fgprof &
	sudo dstat -tams --top-cpu 1 100 & | slackcat-oauth -n dstat
	echo -e "=============================================================================================\n=============================================================================================\n=============================================================================================\n" | slackcat
	make git-log-slackcat

all-b:
	make log_rotate-b
	git pull
	make build-app
	make restart-b
	make slow-on
	make fgprof &
	sudo dstat -tams --top-cpu 1 100 & | slackcat-oauth -n dstat
	echo -e "=============================================================================================\n=============================================================================================\n=============================================================================================\n" | slackcat
	make git-log-slackcat

all-c:
	make log_rotate-c
	git pull
	make build-app
	make restart-c
	make slow-on
	make fgprof &
	sudo dstat -tams --top-cpu 1 100 & | slackcat-oauth -n dstat
	echo -e "=============================================================================================\n=============================================================================================\n=============================================================================================\n" | slackcat
	make git-log-slackcat

.PHONY: local* bench* analyze*



build-app:
	$(MAKE) -C webapp/go $(APP_NAME)

bench-a: build-app restart-a git-log-slackcat
	echo "a OK ベンチ実行して" | $(SLACKCAT)

bench-b: restart-b slow-off git-log-slackcat
	echo "b OK ベンチ実行して" | $(SLACKCAT)

bench-c: build-app restart-c git-log-slackcat
	echo "c OK ベンチ実行して" | $(SLACKCAT)


bench-prof-a: build-app restart-a slow-on git-log-slackcat
	echo "ベンチ実行して" | $(SLACKCAT)
	$(MAKE) pprof
	#$(MAKE) fgprof

bench-prof-b: restart-b slow-on git-log-slackcat
	#$(MAKE) pprof
	#$(MAKE) fgprof

bench-prof-c: build-app restart-c git-log-slackcat
	$(MAKE) pprof
	#$(MAKE) fgprof

analyze-log-a: alp-slackcat-oauth slow-show-slackcat-oauth pt-query-digest-slackcat-oauth
analyze-log-b: alp-slackcat-oauth slow-show-slackcat-oauth pt-query-digest-slackcat-oauth
analyze-log-c: alp-slackcat-oauth slow-show-slackcat-oauth pt-query-digest-slackcat-oauth


restart-a:
	sudo systemctl restart mysql
	sudo systemctl restart $(APP_NAME).service
	sudo systemctl restart nginx
	# sudo service memcached restart

restart-b:
	sudo systemctl restart mysql
	#sudo systemctl restart $(APP_NAME).service
	#sudo systemctl restart nginx
	# sudo service memcached restart

restart-c:
	#	sudo systemctl restart mysql
	sudo systemctl restart $(APP_NAME).service
	#	sudo systemctl restart nginx
	# sudo service memcached restart

# pprofのデータをwebビューで見る
# サーバー上で sudo apt install graphvizが必要
.PHONY: pprof
pprof:
	timeout -s INT 220s go tool pprof -http=0.0.0.0:8080 -no_browser -seconds 100 /home/isucon/webapp/go/$(APP_NAME) http://localhost:6060/debug/pprof/profile

.PHONY: pprof-slackcat-oauth
pprof-slackcat-oauth:
	curl http://localhost:8080/ui/flamegraph > pprof.html && slackcat-oauth -n pprof.$(COMMIT_HASH).$(HOSTNAME).html pprof.html

# go get github.com/felixge/fgprof
.PHONY: fgprof
fgprof:
	timeout -s INT 220s go tool pprof -http=0.0.0.0:8080 -seconds 100 /home/isucon/webapp/go/$(APP_NAME) http://localhost:6060/debug/fgprof


log_rotate-a:
	-sudo chmod 777 -R /var/log/nginx /var/log/mysql /var/log/app
	-sudo cp $(MYSQL_SLOW_LOG) $(MYSQL_SLOW_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(MYSQL_SLOW_LOG)
	-sudo cp $(MYSQL_ERROR_LOG) $(MYSQL_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(MYSQL_ERROR_LOG)
	-sudo cp $(NGINX_ACCESS_LOG) $(NGINX_ACCESS_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo tar -zcvf access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz $(NGINX_ACCESS_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(NGINX_ACCESS_LOG)
	-sudo cp $(NGINX_ERROR_LOG) $(NGINX_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(NGINX_ERROR_LOG)
	-sudo cp $(APP_LOG) $(APP_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo tar -zcvf app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz $(APP_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(APP_LOG)
	-$(SLACKCAT_OAUTH) -n mysqld-slow.log.$(COMMIT_HASH).$(HOSTNAME).txt $(MYSQL_SLOW_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n mysqld-error.log.$(COMMIT_HASH).$(HOSTNAME).txt $(MYSQL_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz
	-$(SLACKCAT_OAUTH) -n nginx-error.log.$(COMMIT_HASH).$(HOSTNAME).txt $(NGINX_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz

log_rotate-b:
	-sudo chmod 777 -R /var/log/nginx /var/log/mysql /var/log/app
	-sudo cp $(MYSQL_SLOW_LOG) $(MYSQL_SLOW_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(MYSQL_SLOW_LOG)
	-sudo cp $(MYSQL_ERROR_LOG) $(MYSQL_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(MYSQL_ERROR_LOG)
	-sudo cp $(NGINX_ACCESS_LOG) $(NGINX_ACCESS_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo tar -zcvf access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz $(NGINX_ACCESS_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(NGINX_ACCESS_LOG)
	-sudo cp $(NGINX_ERROR_LOG) $(NGINX_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(NGINX_ERROR_LOG)
	-sudo cp $(APP_LOG) $(APP_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo tar -zcvf app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz $(APP_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(APP_LOG)
	-$(SLACKCAT_OAUTH) -n mysqld-slow.log.$(COMMIT_HASH).$(HOSTNAME).txt $(MYSQL_SLOW_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n mysqld-error.log.$(COMMIT_HASH).$(HOSTNAME).txt $(MYSQL_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz
	-$(SLACKCAT_OAUTH) -n nginx-error.log.$(COMMIT_HASH).$(HOSTNAME).txt $(NGINX_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz

log_rotate-c:
	-sudo chmod 777 -R /var/log/nginx /var/log/mysql /var/log/app
	-sudo cp $(MYSQL_SLOW_LOG) $(MYSQL_SLOW_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(MYSQL_SLOW_LOG)
	-sudo cp $(MYSQL_ERROR_LOG) $(MYSQL_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(MYSQL_ERROR_LOG)
	-sudo cp $(NGINX_ACCESS_LOG) $(NGINX_ACCESS_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo tar -zcvf access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz $(NGINX_ACCESS_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(NGINX_ACCESS_LOG)
	-sudo cp $(NGINX_ERROR_LOG) $(NGINX_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(NGINX_ERROR_LOG)
	-sudo cp $(APP_LOG) $(APP_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo tar -zcvf app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz $(APP_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-sudo cp /dev/null $(APP_LOG)
	-$(SLACKCAT_OAUTH) -n mysqld-slow.log.$(COMMIT_HASH).$(HOSTNAME).txt $(MYSQL_SLOW_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n mysqld-error.log.$(COMMIT_HASH).$(HOSTNAME).txt $(MYSQL_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz access_log.ltsv.$(COMMIT_HASH).$(HOSTNAME).tar.gz
	-$(SLACKCAT_OAUTH) -n nginx-error.log.$(COMMIT_HASH).$(HOSTNAME).txt $(NGINX_ERROR_LOG).$(COMMIT_HASH).$(HOSTNAME)
	-$(SLACKCAT_OAUTH) -n app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz app.log.$(COMMIT_HASH).$(HOSTNAME).tar.gz


chmod-766-logs:
	sudo chmod -R 777 /var/log/mysql /var/log/nginx /var/log/app


git-log-slackcat:
	git log -n 1 | slackcat

# slow-wuery-logを取る設定にする
# DBを再起動すると設定はリセットされる
.PHONY: slow-on
slow-on:
	$(MYSQL) -e "set global slow_query_log_file = '$(MYSQL_SLOW_LOG)'; set global long_query_time = 0; set global slow_query_log = ON;"

.PHONY: slow-on-no-index
slow-on-no-index:
	$(MYSQL) -e "set global slow_query_log_file = '$(MYSQL_SLOW_LOG)'; set global long_query_time = 0; set global slow_query_log = ON; set global log_queries_not_using_indexes = 1;"

.PHONY: slow-off
slow-off:
	$(MYSQL) -e "set global slow_query_log = OFF;"

# mysqldumpslowを使ってslow query logを出力
# オプションは合計時間ソート
.PHONY: slow-show
slow-show:
	sudo mysqldumpslow -s t $(MYSQL_SLOW_LOG) | head -n 100

.PHONY: slow-show-slackcat-oauth
slow-show-slackcat-oauth:
	-sudo mysqldumpslow -s t $(MYSQL_SLOW_LOG) | head -n 100 | slackcat-oauth -n mysqld-slow.log.$(COMMIT_HASH).$(HOSTNAME).txt

.PHONY: pt-query-digest-slackcat-oauth
pt-query-digest-slackcat-oauth:
	 pt-query-digest --explain 'h=$(shell echo $(MYSQL_HOST) | sed -e "s/\"//g"),u=$(MYSQL_USER),p=$(MYSQL_PASS),D=$(MYSQL_DBNAME)' $(MYSQL_SLOW_LOG) | slackcat-oauth -n pt-query-digest.$(COMMIT_HASH).$(HOSTNAME).txt

#.PHONY: netdata-*
#netdata-on:
#	sudo systemctl restart netdata
#
#netdata-off:
#	sudo systemctl stop netdata


# alp
ALPSORT=sum
ALPM="/api/admin/tenants/add,/api/admin/tenants/billing,/api/organizer/players,/api/organizer/players/add,/api/organizer/player/[a-zA-Z0-9]+/disqualified,/api/organizer/competitions/add,/api/organizer/competition/[a-zA-Z0-9]+/finish,/api/organizer/competition/[a-zA-Z0-9]+/score,/api/organizer/billing,/api/organizer/competitions,/api/player/player/[a-zA-Z0-9]+,/api/player/competition/[a-zA-Z0-9]+/ranking,/api/player/competitions,/api/me,/initialize",
#ALPM="/api/isu/.+/icon,/api/isu/.+/graph,/api/isu/.+/condition,/api/isu/[-a-z0-9]+,/api/condition/[-a-z0-9]+,/api/catalog/.+,/api/condition\?,/isu/........-....-.+,/register,/assets,/\?jwt=[a-zA-Z0-9]+"
#OUTFORMAT=all
#OUTFORMAT=count,method,uri,min,max,sum,avg,p99
OUTFORMAT=count,1xx,2xx,3xx,4xx,5xx,method,uri,min,max,sum,avg,p95,min_body,max_body,avg_body
FORMAT=table
#FORMAT=markdown
.PHONY: alp*
alp:
	sudo alp ltsv --file=$(NGINX_ACCESS_LOG) --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse --output $(OUTFORMAT) --format $(FORMAT) --matching-groups $(ALPM) --query-string
alp-slackcat-oauth:
	-sudo alp ltsv --file=$(NGINX_ACCESS_LOG) --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse --output $(OUTFORMAT) --format $(FORMAT) --matching-groups $(ALPM) --query-string | $(SLACKCAT_OAUTH) -n alp.$(COMMIT_HASH).$(HOSTNAME)
alpsave:
	sudo alp ltsv --file=$(NGINX_ACCESS_LOG) --pos /tmp/alp.pos --dump /tmp/alp.dump --sort $(ALPSORT) --reverse --output $(OUTFORMAT) --format $(FORMAT) --matching-groups $(ALPM) --query-string
alpload:
	sudo alp ltsv --load /tmp/alp.dump --sort $(ALPSORT) --reverse --output $(OUTFORMAT) --format $(FORMAT) --query-string

alp-app-slackcat-oauth:
	-sudo alp ltsv --file=$(APP_LOG) --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse --output $(OUTFORMAT) --format $(FORMAT) --matching-groups $(ALPM) --query-string | $(SLACKCAT_OAUTH) -n alp-app.$(COMMIT_HASH).$(HOSTNAME)


.PHONY: newrelic-infra*
newrelic-infra-on:
	sudo systemctl restart newrelic-infra

newrelic-infra-off:
	sudo systemctl disable newrelic-infra
	sudo systemctl stop newrelic-infra


.PHONY: mysql*
mysql:
	$(MYSQL)

mysqldump:
	mysqldump -h$(MYSQL_HOST) -P$(MYSQL_PORT) -u$(MYSQL_USER) -p$(MYSQL_PASS) --all-databases
