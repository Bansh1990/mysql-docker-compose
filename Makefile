THIS_FILE := $(lastword $(MAKEFILE_LIST))
#.PHONY: help build up start down destroy stop restart logs logs-api ps login-timescale login-api db-shell


ifeq (create-database,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(ARGS):;@:)
endif

ifeq (drop-database,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(ARGS):;@:)
endif

ifeq (mysqldump,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  DATABASE := $(wordlist 2,2,  $(MAKECMDGOALS)    )
  FILE := $(wordlist 3,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(DATABASE):;@:)
  $(eval $(FILE):;@:)
endif


ifeq (mysqlrestore,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  DATABASE := $(wordlist 2,2,  $(MAKECMDGOALS)    )
  FILE := $(wordlist 3,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(DATABASE):;@:)
  $(eval $(FILE):;@:)
endif

ifeq (mysql-copy-database,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  DATABASE-ONE := $(wordlist 2,2,  $(MAKECMDGOALS)    )
  DATABASE-TWO := $(wordlist 3,3,$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(DATABASE-ONE):;@:)
  $(eval $(DATABASE-TWO):;@:)
endif



help: 
	make -pRrq  -f $(THIS_FILE) : 2>/dev/null | awk -v RS= -F: '{if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
build: 
	docker-compose -f docker-compose.yml build $(c)
up:
	docker-compose -f docker-compose.yml up -d $(c)
start:
	docker-compose -f docker-compose.yml up -d $(c)
down:
	docker-compose -f docker-compose.yml down $(c)
destroy:
	docker-compose -f docker-compose.yml down -v $(c)
stop:
	docker-compose -f docker-compose.yml stop $(c)

restart:
	docker-compose -f docker-compose.yml stop $(c)
	docker-compose -f docker-compose.yml up -d $(c)
logs:
	docker-compose -f docker-compose.yml logs --tail=100 -f $(c)
ps:
	docker-compose -f docker-compose.yml ps
login-mysql:
	docker-compose -f docker-compose.yml exec mysql mysql -ptestsitecicd
create-database:
	echo $(ARGS)
	docker-compose -f docker-compose.yml exec mysql mysql -ptestsitecicd -Bse "create database \`$(ARGS)\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

show-databases:
	docker-compose -f docker-compose.yml exec mysql mysql -ptestsitecicd -Bse "show databases;"

drop-database:
	echo $(ARGS)
	/usr/local/bin/docker-compose -f docker-compose.yml exec -T mysql mysql -ptestsitecicd -Bse "drop database \`$(ARGS)\`;"

mysqldump:
ifdef DATABASE
ifdef FILE
	docker-compose -f docker-compose.yml exec mysql mysqldump -ptestsitecicd $(DATABASE)  >  $(FILE) 
	sed -i '1d' $(FILE)
else
	@echo 'Укажите все переменные типа например:'
	@echo 'make mysqldump {database} {file.sql}'
endif
endif


mysqlrestore:

ifdef DATABASE
ifdef FILE
	docker-compose -f docker-compose.yml exec mysql mysql -ptestsitecicd -Bse "drop database \`$(DATABASE)\`;" || echo "удалили бд $$?"
	docker-compose -f docker-compose.yml exec mysql mysql -ptestsitecicd -Bse "create database \`$(DATABASE)\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
	cat $(FILE) | docker-compose -f docker-compose.yml exec -T mysql mysql -ptestsitecicd $(DATABASE) 
else
	@echo 'Укажите все переменные типа например:'
	@echo 'make mysqlrestore {database} {file.sql}'
endif
endif



mysql-copy-database:

ifdef DATABASE-ONE
ifdef DATABASE-TWO
	docker-compose -f docker-compose.yml exec -T mysql mysqldump -ptestsitecicd $(DATABASE-ONE)  >  temp.sql
	sed -i '1d' temp.sql

	docker-compose -f docker-compose.yml exec -T mysql mysql -ptestsitecicd -Bse "drop database \`$(DATABASE-TWO)\`;" || echo "удалили бд $$?"
	docker-compose -f docker-compose.yml exec -T mysql mysql -ptestsitecicd -Bse "create database \`$(DATABASE-TWO)\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
	cat temp.sql | docker-compose -f docker-compose.yml exec -T mysql mysql -ptestsitecicd $(DATABASE-TWO) 
	rm -f temp.sql
else
	@echo 'Укажите все переменные типа например:'
	@echo 'make mysql-copy-database {database1} {database2}'
endif
endif
