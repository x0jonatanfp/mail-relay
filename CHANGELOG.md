# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## 1.5.0 (2026-11-14)

### Features

* **deploy:** unidad de systemd --user ([47efb98](https://github.com/x0jonatanfp/mail-relay/commit/47efb98efefd63b3110c6e90379067e61a85ac68))
* estandarizar deploy con Makefile + dist/ + systemd ([b1f2e42](https://github.com/x0jonatanfp/mail-relay/commit/b1f2e42b9664cee9c5b148d57cd611cf6e7902aa))
* **http:** añade /health ligero en la raíz ([c0d5c0a](https://github.com/x0jonatanfp/mail-relay/commit/c0d5c0aee70b0ce7f70add7825f4e5855f212c7b))
* **logging:** logger con fichero único en /var/log/mail-relay.log ([f3d22d8](https://github.com/x0jonatanfp/mail-relay/commit/f3d22d80213e85e9007646190760fb421bad5bde))
* **mailrelay:** añade self-test semanal de SMTP sin enviar correos ([1a81e49](https://github.com/x0jonatanfp/mail-relay/commit/1a81e4919fcac57d61f4cf72513448a9f8a2cdb9))
* persistir envíos en PostgreSQL y mejorar notificaciones de Telegram ([abffe11](https://github.com/x0jonatanfp/mail-relay/commit/abffe118054692c86ffa4c218825272e510a8b8c))

### Bug Fixes

* activar envío SMTP en endpoint de formularios ([69da2bb](https://github.com/x0jonatanfp/mail-relay/commit/69da2bbd5885d51237b9db8019dfafd397f1d4d5))
* center language selector ([c0be942](https://github.com/x0jonatanfp/mail-relay/commit/c0be942f5501228e732556d2671255d361a13dd2))
* improve language selector placement and naming ([9208628](https://github.com/x0jonatanfp/mail-relay/commit/9208628a9334c818b0561841145e6ae1db34b14f))
* **mailrelay:** formatea el self-test de Telegram en una sola línea ([67c4267](https://github.com/x0jonatanfp/mail-relay/commit/67c4267b304d077d7f0aac5064ab975ac88da19d))
* quitar --delete-excluded, añadir CI=true y --exclude=.git/ ([1a13672](https://github.com/x0jonatanfp/mail-relay/commit/1a136726f0daf1ae4af214e7c6bf192e3894abc1))
* remove obsolete progress documentation ([f6b2a16](https://github.com/x0jonatanfp/mail-relay/commit/f6b2a165493fb0b9c330fda52e28d28015880f9b))
* replace flag emojis with text in language selectors ([758e98d](https://github.com/x0jonatanfp/mail-relay/commit/758e98d623aa3e98c3f87236ee97b3e761c0435e))
* reposition language selector between dividers ([673effc](https://github.com/x0jonatanfp/mail-relay/commit/673effc0fc19b937bdc0a23896f85b9511688744))
* rsync selectivo en deploy (solo dist/ templates/ clients.yaml package.json) ([e8d4406](https://github.com/x0jonatanfp/mail-relay/commit/e8d440674881d1956e5ee7cda0f84d035c1e8726))
