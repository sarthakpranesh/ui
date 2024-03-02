# use the official Bun image
# see all versions at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 as base
WORKDIR /usr/src/app

# install dependencies into temp directory
# this will cache them and speed up future builds
# install with --production (exclude devDependencies)
FROM base AS install
RUN mkdir -p /temp/prod/
COPY package.json /temp/prod/
RUN cd /temp/prod && bun install

# copy node_modules from temp directory
# then copy all (non-ignored) project files into the image
FROM base AS prerelease
COPY --from=install /temp/prod/node_modules node_modules
COPY . .
# build
RUN bun vite build

# copy production dependencies and source code into final image
FROM base AS release
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease /usr/src/app/dist .

# run the app
USER bun
EXPOSE 8001/tcp
CMD [ "bun", "serve", "-l", "tcp://0.0.0.0:8001" ]
