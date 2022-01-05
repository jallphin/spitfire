FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build

WORKDIR /app
RUN git clone --recurse-submodules https://github.com/cobbr/Covenant
WORKDIR /app/Covenant/Covenant
RUN dotnet publish -c Release -o out

ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG COMMIT="local"
ARG VERSION="v0.4.0"

FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS runtime
WORKDIR /app
COPY --from=build /app/Covenant/Covenant/out .
COPY --from=build /app/Covenant/Covenant/Data ./Data
EXPOSE 7443 80 443
ENTRYPOINT ["dotnet", "Covenant.dll"]

STOPSIGNAL SIGKILL

LABEL org.opencontainers.image.ref.name="warhorse/covenant" \
      org.opencontainers.image.created=$BUILD_RFC3339 \
      org.opencontainers.image.authors="warhorse <warhorse@thedarkcloud.net>" \
      org.opencontainers.image.documentation="https://github.com/war-horse/docker-covenant/README.md" \
      org.opencontainers.image.description="Covenant Docker Build" \
      org.opencontainers.image.licenses="GPLv3" \
      org.opencontainers.image.source="https://github.com/war-horse/docker-covenant" \
      org.opencontainers.image.revision=$COMMIT \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.url="https://hub.docker.com/r/warhorse/covenant/"

ENV BUILD_RFC3339 "$BUILD_RFC3339"
ENV COMMIT "$COMMIT"
ENV VERSION "$VERSION"
