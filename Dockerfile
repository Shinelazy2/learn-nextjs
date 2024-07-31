# Install dependencies only when needed
FROM node:20-alpine AS deps

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM node:20-alpine AS builder

ARG POSTGRES_URL
ARG POSTGRES_PRISMA_URL
ARG POSTGRES_URL_NO_SSL
ARG POSTGRES_URL_NON_POOLING
ARG POSTGRES_USER
ARG POSTGRES_HOST
ARG POSTGRES_PASSWORD
ARG POSTGRES_DATABASE
ARG AUTH_URL

ENV POSTGRES_URL=$POSTGRES_URL
ENV POSTGRES_PRISMA_URL=$POSTGRES_PRISMA_URL
ENV POSTGRES_URL_NO_SSL=$POSTGRES_URL_NO_SSL
ENV POSTGRES_URL_NON_POOLING=$POSTGRES_URL_NON_POOLING
ENV POSTGRES_USER=$POSTGRES_USER
ENV POSTGRES_HOST=$POSTGRES_HOST
ENV POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ENV POSTGRES_DATABASE=$POSTGRES_DATABASE
ENV AUTH_URL=$AUTH_URL

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Install pnpm and build the project
RUN npm install -g pnpm && pnpm run build

# Production image, copy all the files and run next
FROM node:20-alpine AS runner

WORKDIR /app



ENV NODE_ENV=production

# Copy build artifacts from builder stage
COPY --from=builder /app/next.config.mjs ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
RUN npm install -g pnpm
EXPOSE 3000

CMD ["pnpm", "start"]
