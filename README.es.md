<div align="center">

# mail-relay

[![MIT License](https://img.shields.io/badge/Licencia-MIT-green.svg)](LICENSE)
[![Node Version](https://img.shields.io/badge/node-%3E%3D18-blue)]()
[![TypeScript](https://img.shields.io/badge/construido_con-TypeScript-3178C6)]()

**Relay SMTP multi-cliente para formularios de contacto web. Un servicio, proyectos ilimitados.**

</div>


---

<p align="center">🌐 <strong>También disponible en:</strong> <a href="README.md">Inglés</a></p>

---
## Características

- **Multi-cliente** — Gestiona formularios de contacto de múltiples sitios web con un solo servicio
- **Configuración YAML** — Añade un nuevo cliente copiando un bloque
- **SMTP seguro** — Soporta SSL/TLS (puerto 465) y STARTTLS (puerto 587)
- **Persistencia PostgreSQL** — Cada envío queda registrado con fecha, cliente, estado y detalles del error
- **Notificaciones Telegram** — Alertas detalladas al recibir un formulario, reportes de error en fallos, y estado del servicio cada 2 horas
- **Plantillas HTML personalizadas** — Templates de email por cliente con inyección de variables
- **Listo para producción** — Incluye un unit de servicio systemd para despliegue automatizado

---

## Inicio rápido

### Requisitos previos

- Node.js 18+
- pnpm
- PostgreSQL (en ejecución y accesible)

### Instalación

```bash
git clone https://github.com/x0jonatanfp/mail-relay.git
cd mail-relay
pnpm install
```

### Configuración

Comienza copiando los archivos de ejemplo:

```bash
cp clients.example.yaml clients.yaml
cp .env.example .env
```

Edita `clients.yaml` con tus credenciales SMTP:

```yaml
clients:
  - id: mi-cliente
    name: Mi Cliente
    domains:
      - micliente.com
    smtp:
      host: smtp.micliente.com
      port: 587
      secure: false
      user: formularios@micliente.com
      pass: "tu-contraseña"
    from:
      name: Mi Cliente
      email: no-reply@micliente.com
    to: info@micliente.com
    template: default
```

Crea la base de datos y configura `.env`:

```bash
createdb mailrelay
```

Luego configura las variables de entorno:

| Variable | Descripción |
|---|---|
| `PORT` | Puerto del servidor (por defecto: 4001) |
| `BIND` | Dirección de escucha (`127.0.0.1` o `0.0.0.0`) |
| `TELEGRAM_BOT_TOKEN` | Token de tu bot de Telegram |
| `TELEGRAM_CHAT_ID` | ID del chat o grupo para notificaciones |
| `DATABASE_URL` | Cadena de conexión PostgreSQL (`postgresql://user:pass@host:5432/mailrelay`) |

> **Nota:** `clients.yaml` y `.env` están en `.gitignore` para evitar commits accidentales de datos sensibles.

La tabla necesaria se crea automáticamente — o manualmente con:

```sql
CREATE TABLE sent_emails (
  id         SERIAL PRIMARY KEY,
  date       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  client_id  VARCHAR(100) NOT NULL,
  client_name VARCHAR(200) NOT NULL,
  to_email   VARCHAR(255) NOT NULL,
  subject    VARCHAR(255),
  status     VARCHAR(20) NOT NULL,
  error_msg  TEXT
);
```

---

## Uso

```bash
# Desarrollo
pnpm dev

# Producción
pnpm build
pnpm serve
```

### Endpoints de la API

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/health` | Health check del servicio |
| `POST` | `/api/send` | Enviar un formulario de contacto |

### Envío de un formulario

```bash
curl -X POST http://localhost:4001/api/send \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "mi-cliente",
    "from_name": "Juan Pérez",
    "from_email": "juan@example.com",
    "message": "Me gustaría recibir más información sobre sus productos."
  }'
```

Respuesta:

```json
{
  "success": true,
  "method": "smtp",
  "message": "Mensaje enviado correctamente"
}
```

### Integrar otra aplicación

El relay escucha por defecto solo en `127.0.0.1:4001`. Esto impide conectarse directamente al puerto desde otro equipo, pero **no** hace privadas las rutas que un proxy inverso publique.

Convención recomendada para una aplicación nueva:

1. Añade un cliente en `clients.yaml` con un `id` estable, dominios y configuración SMTP/destinatario. No copies credenciales a la aplicación consumidora.
2. Haz que el **backend de la aplicación** envíe `POST http://127.0.0.1:4001/api/send` con `Content-Type: application/json` y un cuerpo como el ejemplo anterior. El backend debe fijar el `client_id` y el destinatario permitido; no confíes en esos valores si vienen libremente del navegador.
3. Valida y limita las peticiones en el endpoint público de la aplicación (autenticación cuando corresponda, protección anti-CSRF para sesiones/cookies, validación de campos y rate limit). El backend traduce el resultado del relay a la respuesta de su propia API.
4. Si el frontend es estático y no tiene backend propio, publica una ruta del mismo origen (por ejemplo, `/api/send`) mediante Nginx hacia `127.0.0.1:4001`. Esa ruta será pública aunque el puerto siga escuchando solo en loopback: protégela y limita qué campos/clientes/destinatarios puede aceptar.

No llames a `127.0.0.1:4001` desde el navegador del usuario: `127.0.0.1` apuntaría al dispositivo de ese usuario, no al servidor. Tampoco cambies `BIND` a `0.0.0.0` para integrar una web.

La dirección `http://localhost:4001` de los ejemplos de `curl` sirve para probar desde el propio servidor donde corre el relay. En desarrollo, usa un proxy local o configura el backend para alcanzar el relay por loopback en el mismo host.

---

## Notificaciones Telegram

**Formulario recibido:**

```
📬 Nuevo formulario · Mi Cliente
━━━━━━━━━━━━━━━━━━
👤 Juan Pérez
📧 juan@example.com
📞 +34 612 345 678
📝 Consulta sobre productos
```

**Error al enviar:**

```
❌ Error · Mi Cliente
━━━━━━━━━━━━━━━━━━
⚠️  Conexión rehusada
🔧 smtp.micliente.com:587
```

**Estado periódico (cada 2h):**

```
📊 mail-relay · Status 14:30
━━━━━━━━━━━━━━━━━━
👥 Clientes:     3 activos
📬 Envíos hoy:   8
📈 Total acum.:  340
⏱  Último envío: hace 2 min
━━━━━━━━━━━━━━━━━━
```

---

## Despliegue

El servicio corre como **unidad de sistema systemd** (`deploy/mail-relay.service`,
código en `/srv/services/mail-relay`). Build, sincronizado y reinicio en un paso:

```bash
make deploy
```

La unidad toma las credenciales de la BD de `~/.secrets` mediante
`~/.secrets/bin/run`, escribe `/var/log/mail-relay.log` (lo rota logrotate) y
mantiene el journal (`journalctl -u mail-relay`).

Instalación manual de la unidad:

```bash
sudo cp deploy/mail-relay.service /etc/systemd/system/mail-relay.service
sudo systemctl daemon-reload
sudo systemctl enable --now mail-relay.service
```

---

## Estructura del proyecto

```
mail-relay/
├── src/
│   ├── application/services/   # Lógica de negocio
│   ├── config/                 # Cargadores de YAML, env y BD
│   ├── domain/                 # Entidades y puertos
│   ├── infrastructure/
│   │   ├── http/               # Servidor Express
│   │   ├── smtp/               # Adaptador Nodemailer
│   │   ├── telegram/           # Notificaciones Telegram
│   │   └── persistence/        # Relay-store PostgreSQL
│   └── index.ts                # Punto de entrada
├── templates/                  # Plantillas HTML de email
├── clients.example.yaml        # Plantilla de configuración de cliente
├── .env.example                # Plantilla de variables de entorno
├── deploy/mail-relay.service   # Unidad systemd (sistema)
├── Makefile                    # build + deploy + restart
└── LICENSE                     # Licencia MIT
```

---

## Stack tecnológico

| Componente | Tecnología |
|---|---|
| Runtime | Node.js 18+ |
| Framework | Express |
| Email | Nodemailer |
| Base de datos | PostgreSQL |
| Configuración | js-yaml + dotenv |
| Notificaciones | Telegram Bot API |
| Sistema de inicio | systemd |
