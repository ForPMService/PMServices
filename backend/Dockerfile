# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY PMServices.sln ./
COPY src/ ./src/

RUN --mount=type=cache,id=pmservices-nuget,target=/root/.nuget/packages \
    dotnet restore "./PMServices.sln"

WORKDIR /src/src/PMServices
RUN --mount=type=cache,id=pmservices-nuget,target=/root/.nuget/packages \
    dotnet publish "PMServices.csproj" \
      -c $BUILD_CONFIGURATION \
      -o /app/publish \
      --no-restore \
      /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
USER app

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "PMServices.dll"]