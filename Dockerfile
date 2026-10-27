FROM node:22-bookworm-slim

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
WORKDIR /app
RUN mkdir -p /ms-playwright && chown node:node /app /ms-playwright

USER node
COPY --chown=node:node package.json package-lock.json ./
RUN npm ci && npx playwright install chromium

# Chromium's system libraries, needed for PDF export
USER root
RUN npx playwright install-deps chromium && rm -rf /var/lib/apt/lists/*
USER node

EXPOSE 3030
CMD ["npm", "run", "dev", "--", "--remote", "--port", "3030"]
