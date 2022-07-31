include taki.env

SHELL=/bin/bash
REPO_NAME := isucon12-qualify

# ------------------------------------------------------------

.PHONY: setup/*
.PHONY: local-*

setup/unzip:
	sudo apt install -y zip unzip

setup/git-config: setup/git /home/isucon/.ssh/config
	git config --global core.filemode false # パーミッションの変更とかで差分が出ないようにする。実務でやったらやばい。
	git config --global user.name "tetsuzawa"
	git config --global user.email "tetsu.takizawa5@gmail.com"
	git config --global color.ui auto
	git config --global core.editor 'vim -c "set fenc=utf-8"'
	git config --global push.default current
	git config --global init.defaultBranch main
	git config --global alias.st status

setup/git:
	sudo apt install -y git

/home/isucon/.ssh/config: /home/isucon/.ssh/id_rsa
	echo > $@ -e "Host github github.com\n  HostName github.com\n  IdentityFile $<\n  User git\n"

/home/isucon/.ssh/id_rsa /home/isucon/.ssh/id_rsa.pub:
	mkdir -p ~/.ssh
	ssh-keygen -t rsa -b 4096 -f $@ -q -N ""

setup/alp:
	wget -O alp.zip https://github.com/tkuchiki/alp/releases/download/v1.0.8/alp_linux_amd64.zip
	unzip alp.zip
	sudo install alp /usr/local/bin/alp
	rm -rf alp alp.zip

setup/graphviz:
	sudo apt install -y graphviz

setup/nginx: ./backup/etc/nginx

./backup/etc/nginx:
	mkdir -p ./etc
	mkdir -p ./backup/etc
	cp -r /etc/nginx ./backup/etc/nginx
	sudo mv /etc/nginx ./etc/nginx
	sudo ln -s /home/isucon/etc/nginx /etc/nginx
	sudo chmod 766 -R /home/isucon/etc/nginx
	sudo chmod 777 -R /var/log/nginx
	@#sudo chown isucon:isucon -R /home/isucon/etc/nginx
	sudo nginx -t

setup/mysql: ./backup/etc/mysql

./backup/etc/mysql:
	mkdir -p ./etc
	mkdir -p ./backup/etc
	sudo cp -r /etc/mysql ./backup/etc/mysql
	sudo mkdir -p /home/isucon/etc/mysql/conf.d
	sudo mkdir -p /home/isucon/etc/mysql/mysql.conf.d
	sudo ln /etc/mysql/conf.d/mysql.cnf /home/isucon/etc/mysql/conf.d/mysql.cnf
	sudo ln /etc/mysql/conf.d/mysqldump.cnf /home/isucon/etc/mysql/conf.d/mysqldump.cnf
	sudo ln /etc/mysql/mysql.conf.d/mysql.cnf /home/isucon/etc/mysql/mysql.conf.d/mysql.cnf
	sudo ln /etc/mysql/mysql.conf.d/mysqld.cnf /home/isucon/etc/mysql/mysql.conf.d/mysqld.cnf
	sudo chmod 755 -R /home/isucon/etc/mysql
	mkdir -p /var/log/mysql
	sudo chmod 777 -R /var/log/mysql

hardlink/mysql:
	sudo rm /etc/mysql/conf.d/my.cnf
	sudo rm /etc/mysql/conf.d/mysql.cnf
	sudo rm /etc/mysql/conf.d/mysqldump.cnf
	sudo rm /etc/mysql/mysql.conf.d/50-client.cnf
	sudo rm /etc/mysql/mysql.conf.d/50-mysql-clients.cnf
	sudo rm /etc/mysql/mysql.conf.d/50-mysqld_safe.cnf
	sudo rm /etc/mysql/mysql.conf.d/50-server.cnf
	sudo ln /etc/mysql/conf.d/mysql.cnf /home/isucon/etc/mysql/conf.d/mysql.cnf
	sudo ln /etc/mysql/conf.d/mysqldump.cnf /home/isucon/etc/mysql/conf.d/mysqldump.cnf
	sudo ln /etc/mysql/mysql.conf.d/mysql.cnf /home/isucon/etc/mysql/mysql.conf.d/mysql.cnf
	sudo ln /etc/mysql/mysql.conf.d/mysqld.cnf /home/isucon/etc/mysql/mysql.conf.d/mysqld.cnf

setup/app.log:
	sudo mkdir -p /var/log/app
	sudo chmod -R 777 /var/log/app

setup/pt-query-digest:
	sudo apt install -y percona-toolkit

setup/fish:
	sudo apt install -y fish

setup/fisher:
	fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"

setup/fzf:
	fish -c "fisher install jethrokuan/fzf"
	sudo apt install -y fzf

setup/vim:
	echo 'inoremap jj <Esc>' >> .vimrc

setup/slackcat:
	go install github.com/tetsuzawa/slackcat@latest

setup/slackcat-oauth:
	curl -Lo slackcat-oauth https://github.com/bcicen/slackcat/releases/download/1.7.3/slackcat-1.7.3-$(shell uname -s)-amd64
	sudo mv slackcat-oauth /usr/local/bin/
	sudo chmod +x /usr/local/bin/slackcat-oauth
	mkdir -p .config/slackcat

setup/slackcat-oauth-config:
	#rsync -avz .config/slackcat/config isucon@$(IP_BENCH):~/.config/slackcat/
	rsync -avz .config/slackcat/config isucon@$(IP_A):~/.config/slackcat/
	rsync -avz .config/slackcat/config isucon@$(IP_B):~/.config/slackcat/
	rsync -avz .config/slackcat/config isucon@$(IP_C):~/.config/slackcat/

	#ssh isucon@$(IP_BENCH) sudo cp .config/slackcat/config /root/.slackcat
	ssh isucon@$(IP_A) sudo cp .config/slackcat/config /root/.slackcat
	ssh isucon@$(IP_B) sudo cp .config/slackcat/config /root/.slackcat
	ssh isucon@$(IP_C) sudo cp .config/slackcat/config /root/.slackcat

setup/newrelic-cli:
	curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY=$(NEW_RELIC_API_KEY) NEW_RELIC_ACCOUNT_ID=3244867 /usr/local/bin/newrelic install

.PHONY: local-rsync-make
local-rsync-make:
	rsync -avz taki.env setup.mk Makefile isucon@$(IP_A):~/
	#rsync -avz taki.env setup.mk Makefile isucon@$(IP_B):~/
	#rsync -avz taki.env setup.mk Makefile isucon@$(IP_C):~/
	rsync -avz taki.env setup.mk Makefile isucon@$(IP_BENCH):~/

setup/init-git:
	git init
	git config core.filemode false
	echo -e "taki.env\n.config/slackcat/config\n.slackcat\nssh" >> .gitignore
	git add setup.mk Makefile .bashrc .gitignore
	git commit -m "setup repo"

setup/gh: /usr/bin/gh
	gh config set editor vim
	gh config set git_protocol ssh
	gh config set git_protocol ssh -h github.com

/usr/bin/gh:
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(shell dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update
	sudo apt install -y gh

add-deploy-key.lock:
	gh repo deploy-key add --allow-write --repo tetsuzawa/$(REPO_NAME) /home/isucon/.ssh/id_rsa.pub
	touch add-deploy-key.lock

setup/push-git:
	git remote add origin git@github.com:tetsuzawa/$(REPO_NAME).git
	git push -u origin master

local-rsync-pull-key-from-a:
	mkdir -p ./ssh
	rsync -avz isucon@$(IP_A):/home/isucon/.ssh/id_rsa ./ssh/
	rsync -avz isucon@$(IP_A):/home/isucon/.ssh/id_rsa.pub ./ssh/

local-rsync-put-keys-to-bc:
	#	rsync -avz ./ssh/id_rsa ./ssh/id_rsa.pub isucon@$(IP_BENCH):~/.ssh/
	#	ssh isucon@$(IP_BENCH) sudo chown isucon:isucon /home/isucon/.ssh/id_rsa /home/isucon/.ssh/id_rsa.pub
	#	ssh isucon@$(IP_BENCH) "cat /home/isucon/.ssh/id_rsa.pub >> /home/isucon/.ssh/authorized_keys"
	#	ssh isucon@$(IP_BENCH) sudo systemctl restart sshd

	rsync -avz ./ssh/id_rsa ./ssh/id_rsa.pub isucon@$(IP_B):~/.ssh/
	ssh isucon@$(IP_B) sudo chown isucon:isucon /home/isucon/.ssh/id_rsa /home/isucon/.ssh/id_rsa.pub
	ssh isucon@$(IP_B) "cat /home/isucon/.ssh/id_rsa.pub >> /home/isucon/.ssh/authorized_keys"
	ssh isucon@$(IP_B) sudo systemctl restart sshd

	rsync -avz ./ssh/id_rsa ./ssh/id_rsa.pub isucon@$(IP_C):~/.ssh/
	ssh isucon@$(IP_C) sudo chown isucon:isucon /home/isucon/.ssh/id_rsa /home/isucon/.ssh/id_rsa.pub
	ssh isucon@$(IP_C) "cat /home/isucon/.ssh/id_rsa.pub >> /home/isucon/.ssh/authorized_keys"
	ssh isucon@$(IP_C) sudo systemctl restart sshd

.git:
	git clone git@github.com:tetsuzawa/$(REPO_NAME).git
	mv $(REPO_NAME)/.git .
	rm -rf $(REPO_NAME)
	git reset --hard