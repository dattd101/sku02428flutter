FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY index.mjs ./index.mjs
COPY lib ./lib
ENV PORT=8080
EXPOSE 8080
CMD ["node", "index.mjs"]
