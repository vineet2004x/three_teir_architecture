# Docker-Based 3-Tier Application

A containerized three-tier web application using **Nginx**, **Node.js**, and **MySQL** with Docker Compose.

## 1. Setup Instructions

```bash
git clone <your-repo-url>
cd fifty-five-project
cp .env.example .env
docker compose up --build
```

Services start in order: **MySQL → Backend → Frontend**

## 2. Architecture Diagram

```
[ Browser ] → Nginx :80 → /api → Backend API :3000 → MySQL :3306
```

| Service  | Image          | Port | Role                                       |
| -------- | -------------- | ---- | ------------------------------------------ |
| Frontend | nginx:alpine   | 80   | Static HTML + reverse proxy /api → backend |
| Backend  | node:18-alpine | 3000 | REST API, DB queries, health endpoint      |
| Database | mysql:8.0      | 3306 | Persistent storage via named Docker volume |

All services use a custom bridge network (`three-tier-network`) and communicate via service names.

## 3. Explanation

### How Backend Waits for MySQL

Two mechanisms ensure the backend doesn't crash if MySQL isn't ready:

1. **`depends_on` with `condition: service_healthy`** — backend starts only after MySQL passes its health check (`mysqladmin ping`)
2. **`wait-for-it.sh`** — entrypoint script loops with `nc` (netcat) until MySQL port is reachable, then starts `node server.js`

### How Nginx Gets Backend URL

- Backend URL is **never hardcoded** in nginx config
- `nginx.conf.template` uses the `$BACKEND_URL` environment variable
- The official `nginx:alpine` entrypoint runs `envsubst` automatically on template files at container start

### How Services Communicate

- All services are on a custom Docker bridge network
- Services reference each other by **container names** (`db`, `backend-api`)
- Nginx proxies `/api/*` requests to `http://backend-api:3000/`

## 4. Testing Steps

**Access Frontend:**

```
http://localhost
```

**Test API via Nginx proxy:**

```bash
curl http://localhost/api/
# {"status":"ok","service":"backend"}

curl http://localhost/api/health
# {"status":"healthy","database":"connected"}
```

**Test Backend directly:**

```bash
curl http://localhost:3000/
curl http://localhost:3000/health
```

**View logs:**

```bash
docker compose logs -f
```

## 5. Failure Scenario — MySQL Restart

```bash
docker restart mysql-db
```

**What happens:**

- During MySQL downtime (~5-10s), `/api/health` returns `{"status":"unhealthy","database":"disconnected"}`
- Backend does **not crash** — it continues running and returns error responses
- Once MySQL is back up, `/api/health` automatically recovers to `{"status":"healthy","database":"connected"}`

**Recovery time:** ~10-15 seconds

**Why it works:** Backend creates a new DB connection per request (no persistent pool), so it naturally recovers when MySQL accepts connections again.

## Project Structure

```
├── frontend/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── nginx.conf.template
│   └── index.html
├── backend/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── package.json
│   ├── server.js
│   └── wait-for-it.sh
├── docker-compose.yml
├── .env.example
├── .gitignore
└── README.md
```
