# Base image docs: apify-docs sources/platform/actors/development/actor_definition/docker.md
# Node 22 per project brief (official templates currently use apify/actor-node:24).
FROM apify/actor-node:22

# Copy package files first for Docker layer caching.
COPY --chown=myuser:myuser package*.json ./

# Production deps only; print the tree for build-log debugging.
RUN npm --quiet set progress=false \
    && npm install --omit=dev --omit=optional \
    && echo "Installed NPM packages:" \
    && (npm list --omit=dev --all || true) \
    && echo "Node.js version:" && node --version \
    && echo "NPM version:" && npm --version \
    && rm -r ~/.npm

COPY --chown=myuser:myuser . ./

CMD ["node", "src/main.js"]
