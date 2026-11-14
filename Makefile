NAME := mail-relay
DEST := /srv/services/$(NAME)
SERVICE := $(NAME)  # unidad de sistema (deploy/$(NAME).service)

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

.PHONY: check-clean release

check-clean:
	@test -z "$$(git status --porcelain)" || { echo "ERROR: hay cambios sin commitear; commitea antes de desplegar"; exit 1; }

release: check-clean
	$(CATV)
	git push --follow-tags
