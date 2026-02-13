# ═══════════════════════════════════════════════════════════════
# PM.BFF Dockerfile
# Build context = корень репозитория (PMServices/)
# ═══════════════════════════════════════════════════════════════

# ── restore (кэшируемый слой) ──
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS restore
WORKDIR /src

COPY PMPlatform.slnx Directory.Build.props ./
COPY src/Platform/PM.Platform.Core/PM.Platform.Core.csproj                     src/Platform/PM.Platform.Core/
COPY src/Platform/PM.Platform.Infrastructure/PM.Platform.Infrastructure.csproj src/Platform/PM.Platform.Infrastructure/
COPY src/Platform/PM.Platform.Contracts/PM.Platform.Contracts.csproj           src/Platform/PM.Platform.Contracts/
COPY src/IAM/PM.IAM.Contracts/PM.IAM.Contracts.csproj                         src/IAM/PM.IAM.Contracts/
COPY src/BFF/PM.BFF/PM.BFF.csproj                                             src/BFF/PM.BFF/

RUN dotnet restore src/BFF/PM.BFF/PM.BFF.csproj

# ── publish ──
FROM restore AS publish
COPY src/ src/
RUN dotnet publish src/BFF/PM.BFF/PM.BFF.csproj -c Release -o /app/publish --no-restore

# ── runtime (chiseled = non-root by default) ──
FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS runtime
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "PM.BFF.dll"]

# ── dev (hot reload с dotnet watch) ──
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS dev
WORKDIR /src
COPY . .
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Development
EXPOSE 8080
ENTRYPOINT ["dotnet", "watch", "run", "--project", "src/BFF/PM.BFF/PM.BFF.csproj"]
