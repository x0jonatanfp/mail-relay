NAME := mail-relay
DEST ?= /srv/services/$(NAME)
SERVICE := $(NAME)
SYSTEMD_UNIT := /etc/systemd/system/$(SERVICE).service
# Usuario, grupo y binario del servicio: sobrescribibles al invocar make.
DEPLOY_USER ?= $(shell id -un)
DEPLOY_GROUP ?= $(shell id -gn)
DEPLOY_HOME ?= $(shell getent passwd $(DEPLOY_USER) | cut -d: -f6)
NODE_BIN ?= $(shell command -v node 2>/dev/null || echo /usr/bin/node)
# Fichero temporal donde se renderiza la unidad antes de instalarla.
RENDERED_UNIT := /tmp/$(SERVICE).service.render

.PHONY: install deploy restart status logs check-clean release

# Instalación inicial: prepara el destino e instala la unidad renderizada desde
# la plantilla, pero no la habilita ni la arranca. El deploy la activa cuando ya
# existen los secretos de producción.
install:
	sudo install -d -o $(DEPLOY_USER) -g $(DEPLOY_GROUP) -m 0750 $(DEST) $(DEST)/dist
	rm -f $(RENDERED_UNIT)
	sed -e 's|@DEPLOY_USER@|$(DEPLOY_USER)|g' \
		-e 's|@DEPLOY_GROUP@|$(DEPLOY_GROUP)|g' \
		-e 's|@DEPLOY_HOME@|$(DEPLOY_HOME)|g' \
		-e 's|@DEST@|$(DEST)|g' \
		-e 's|@NODE_BIN@|$(NODE_BIN)|g' \
		deploy/$(SERVICE).service > $(RENDERED_UNIT)
	sudo install -m 0644 $(RENDERED_UNIT) $(SYSTEMD_UNIT)
	rm -f $(RENDERED_UNIT)
	sudo systemctl daemon-reload

deploy: release
	pnpm build && \
	  rsync -av --delete dist/ $(DEST)/dist/ && \
	  cp package.json pnpm-lock.yaml $(DEST)/
	rsync -av --delete templates/ $(DEST)/templates/
	cp clients.yaml $(DEST)/
	cd $(DEST) && rm -rf node_modules && CI=true pnpm install --prod --no-frozen-lockfile
	sudo systemctl restart $(SERVICE).service

restart:
	sudo systemctl restart $(SERVICE).service

status:
	sudo systemctl status $(SERVICE).service --no-pager

logs:
	journalctl -u $(SERVICE).service -n 50 -f

# Versión: la calcula commit-and-tag-version a partir de los commits desde la
# última etiqueta (`!` major, feat minor, fix patch, el resto nada). Escribe
# la versión y el CHANGELOG.md, commitea `chore(release)` y etiqueta; si no
# hay feat, fix ni `!` nuevos, no hace nada. Corre antes de desplegar.
CATV := npx -y commit-and-tag-version@13.3.0

check-clean:
	@test -z "$$(git status --porcelain)" || { echo "ERROR: hay cambios sin commitear; commitea antes de desplegar"; exit 1; }

release: check-clean
	$(CATV)
	git push --follow-tags
