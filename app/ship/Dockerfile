# ===== Stage 1: Build =====
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (better layer caching)
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the source and build
COPY . .
RUN npm run build

# ===== Stage 2: Serve =====
FROM nginx:1.27-alpine

# Vite's default build output directory is "dist"
COPY --from=builder /app/dist /usr/share/nginx/html

# Optional: custom nginx config for SPA routing (client-side routes)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
