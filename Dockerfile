# === Stage 1: Build the Frontend Client ===
FROM node:22-alpine AS client-build

WORKDIR /usr/src/app/client

# Copy package files first to leverage caching
COPY client/package*.json ./
RUN npm install

# Copy the rest of the client source and build
COPY client/ ./
RUN npm run build


# === Stage 2: Final Production Server ===
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /usr/src/app/server

# 1. Create non-root user and group early
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 2. Copy server package files and install production dependencies
COPY server/package*.json ./
RUN npm install --omit=dev

# 3. Copy server source code and set ownership immediately
COPY --chown=appuser:appgroup server/ ./

# 4. Copy frontend static assets to where server.js serves them from.
# webpack.config.js outputs to client/public, and server.js serves
# static files from path.join(__dirname, '../client/public').
COPY --chown=appuser:appgroup --from=client-build /usr/src/app/client/public/ /usr/src/app/client/public/

EXPOSE 5000

# 5. Switch to non-root user safely—all files are already owned by appuser!
USER appuser

CMD ["npm", "start"]