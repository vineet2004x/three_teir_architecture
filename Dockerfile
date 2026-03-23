# ---- Stage 1: Build ----
FROM node:18-alpine AS builder

WORKDIR /app

COPY package.json ./
RUN npm install --production

# ---- Stage 2: Production ----
FROM node:18-alpine

# Install netcat for wait-for-it script
RUN apk add --no-cache netcat-openbsd

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy built node_modules from builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy application source
COPY package.json server.js ./
COPY wait-for-it.sh ./
RUN chmod +x wait-for-it.sh

# Switch to non-root user
USER appuser

EXPOSE 3000

# Use wait-for-it to wait for DB, then start the server
ENTRYPOINT ["./wait-for-it.sh"]
CMD ["node", "server.js"]
