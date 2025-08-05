### 🚀 Guía de Docker: De una App a una Solución Multi-Contenedor

Este documento es un resumen paso a paso de cómo empaquetar una aplicación de React y una base de datos PostgreSQL usando Docker y Docker Compose.

#### **Introducción: ¿Por qué todo este "quilombo"?**

En lugar de instalar y configurar React, Node.js, Nginx y PostgreSQL directamente en tu computadora, los empaquetamos en contenedores. Esto crea un entorno de desarrollo aislado, reproducible y portátil. No importa si trabajas en Kali, Windows o Mac, la aplicación funcionará exactamente igual.

### 📋 Requisitos Previos

* **Docker Desktop** (o Docker Engine y Docker Compose CLI en Linux).
* El código fuente de tu aplicación de React (en este caso, en el directorio `web-app-with-docker`).
* Un editor de texto (como `nano` o Visual Studio Code).

---

### **Paso 1: El `Dockerfile` (La Receta de la Aplicación Web)**

Este archivo le dice a Docker cómo construir la imagen de tu aplicación de React. Usamos un "multi-stage build" para mantener la imagen final pequeña y segura.

**Crea un archivo llamado `Dockerfile` en el directorio raíz de tu proyecto** (`~/Escritorio/web-app-with-docker`) y pega el siguiente código:

```dockerfile
# Primera etapa: 'build'
# Usamos una imagen de Node para compilar la aplicación React
FROM node:18-alpine AS build

# Establecemos el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos solo el archivo de dependencias para instalarlas
COPY package.json ./

# Instalamos las dependencias
RUN npm install

# Copiamos el resto del código
COPY . .

# Compilamos la aplicación para producción
RUN npm run build

# Segunda etapa: 'stage-1'
# Usamos una imagen de Nginx para servir la aplicación estática
FROM nginx:alpine

# Copiamos el resultado de la compilación desde la etapa 'build'
COPY --from=build /app/build /usr/share/nginx/html

# Exponemos el puerto 80 del contenedor, que es donde Nginx servirá la app
EXPOSE 80

# El comando por defecto para ejecutar Nginx
CMD ["nginx", "-g", "daemon off;"]



# Paso 2: El docker-compose.yml (El Orquestador)
Este archivo define todos los servicios de tu aplicación (la web y la base de datos) para que Docker pueda levantarlos con un solo comando.

Crea un archivo llamado docker-compose.yml en el mismo directorio raíz de tu proyecto y pega este código:

YAML

services:
  web:
    # Le dice a Docker que construya la imagen desde el Dockerfile en este directorio
    build: .
    # Mapea el puerto 8080 de tu máquina al puerto 80 del contenedor web
    ports:
      - "8080:80"
  
  postgres:
    # La imagen a usar para el servicio de base de datos
    image: postgres
    # Mapea el puerto 5432 de tu máquina al puerto 5432 del contenedor postgres
    ports:
      - '5432:5432'
    # Define variables de entorno que necesita el contenedor de Postgres
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
Explicación:

services: Define los componentes de tu aplicación (web y postgres).

web: build: .: Le indica a Docker que el servicio web se construye a partir del Dockerfile que está en el directorio actual.

postgres: image: postgres: Le dice a Docker que el servicio postgres se basa en la imagen oficial que descargará de Docker Hub.

environment: Resuelve el problema que tuvimos de la contraseña faltante. Aquí se la pasamos directamente en el archivo de configuración.

Paso 3: Construir y Levantar Todo
Ahora que tienes los dos archivos de configuración, puedes iniciar toda la aplicación.

Desde el directorio raíz de tu proyecto (~/Escritorio/web-app-with-docker), ejecuta el siguiente comando:

Bash

docker compose up
Qué hace este comando:

Lee el archivo docker-compose.yml.

Construye la imagen para el servicio web.

Descarga la imagen de postgres (si no la tienes).

Crea y lanza los contenedores web-1 y postgres-1.

Muestra los logs de ambos servicios en la misma terminal.

TIP: Si quieres que se ejecute en segundo plano para poder seguir usando la terminal, puedes usar docker compose up -d.

Paso 4: Verificar que Funciona
Para ver tu aplicación web, abre tu navegador y navega a http://localhost:8080.

Para ver que ambos contenedores están corriendo, abre una nueva terminal y ejecuta:

Bash

docker ps
Deberías ver ambos contenedores en la lista con el estado Up.

Paso 5: Detener y Limpiar
Cuando termines de trabajar y quieras detener los servicios, usa el comando docker compose down. Este comando es el opuesto de up y es la forma correcta de detener y eliminar todos los contenedores, redes y volúmenes creados por el docker-compose.yml.

Bash

docker compose down
Consejo Final: A diferencia de docker run que solo maneja un contenedor, docker compose es la herramienta ideal para gestionar proyectos con múltiples componentes. Con esto, has pasado de la teoría a la práctica de manera exitosa.

