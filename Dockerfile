

# Etapa 1: Construir la aplicación React
FROM node:18-alpine as build

WORKDIR /app

# Copiamos los archivos de dependencias y las instalamos.
COPY package.json ./
RUN npm install

# Copiamos el resto del código de la aplicación.
COPY . .

# Compilamos la aplicación para producción.
RUN npm run build

# ---

# Etapa 2: Servir la aplicación con Nginx
FROM nginx:alpine

# Copiamos los archivos compilados desde la etapa de "build" a Nginx.
COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80
