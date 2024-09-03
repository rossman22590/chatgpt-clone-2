# v0.7.5-rc1

# Base node image
FROM node:20-alpine AS node

# Install necessary build tools and dependencies
RUN apk add --no-cache curl python3 make g++

# Create app directory and set permissions
RUN mkdir -p /app && chown node:node /app
WORKDIR /app

# Switch to non-root user
USER node

# Copy package.json and package-lock.json
COPY --chown=node:node package*.json ./

# Install dependencies including dev dependencies
RUN npm config set fetch-retry-maxtimeout 600000 && \
    npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 15000 && \
    npm ci

# Copy the rest of the application
COPY --chown=node:node . .

# Create necessary directories
RUN mkdir -p /app/data/images /app/data/logs /app/client/public /app/api

# Create symbolic links
RUN ln -s /app/data/images /app/client/public/images && \
    ln -s /app/data/logs /app/api/logs

# Build the frontend
RUN NODE_OPTIONS="--max-old-space-size=2048" npm run frontend

# Prune dev dependencies
RUN npm prune --production && npm cache clean --force

# Node API setup
EXPOSE 3080
ENV HOST=0.0.0.0

# Start script
CMD ["sh", "-c", "ln -sf /app/data/.env /app/.env && npm run backend"]

# Optional: for client with nginx routing
# FROM nginx:stable-alpine AS nginx-client
# WORKDIR /usr/share/nginx/html
# COPY --from=node /app/client/dist /usr/share/nginx/html
# COPY client/nginx.conf /etc/nginx/conf.d/default.conf
# ENTRYPOINT ["nginx", "-g", "daemon off;"]
# # v0.7.5-rc1

# # Base node image
# FROM node:20-alpine AS node

# RUN apk --no-cache add curl

# RUN mkdir -p /app && chown node:node /app
# WORKDIR /app

# USER node

# COPY --chown=node:node . .

# RUN \
#     # Allow mounting of these files, which have no default
#     touch .env ; \
#     # Create directories for the volumes to inherit the correct permissions
#     mkdir -p /app/client/public/images /app/api/logs ; \
#     npm config set fetch-retry-maxtimeout 600000 ; \
#     npm config set fetch-retries 5 ; \
#     npm config set fetch-retry-mintimeout 15000 ; \
#     npm install --no-audit; \
#     # React client build
#     NODE_OPTIONS="--max-old-space-size=2048" npm run frontend; \
#     npm prune --production; \
#     npm cache clean --force

# RUN mkdir -p /app/client/public/images /app/api/logs

# # Node API setup
# EXPOSE 3080
# ENV HOST=0.0.0.0
# CMD ["npm", "run", "backend"]

# # Optional: for client with nginx routing
# # FROM nginx:stable-alpine AS nginx-client
# # WORKDIR /usr/share/nginx/html
# # COPY --from=node /app/client/dist /usr/share/nginx/html
# # COPY client/nginx.conf /etc/nginx/conf.d/default.conf
# # ENTRYPOINT ["nginx", "-g", "daemon off;"]
