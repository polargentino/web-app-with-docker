# 🚀 Guía Completa de Docker: De una App a una Solución Multi-Contenedor

Este documento es un resumen paso a paso de cómo empaquetar una aplicación de React y una base de datos PostgreSQL usando Docker y Docker Compose.

## **Introducción: ¿Por qué todo este "quilombo"?**

En lugar de instalar y configurar React, Node.js, Nginx y PostgreSQL directamente en tu computadora, los empaquetamos en contenedores. Esto crea un entorno de desarrollo aislado, reproducible y portátil. No importa si trabajas en Kali, Windows o Mac, la aplicación funcionará exactamente igual.

### **Ventajas de usar Docker:**
- **Consistencia**: El mismo entorno en desarrollo, testing y producción
- **Aislamiento**: No se mezclan dependencias entre proyectos
- **Portabilidad**: Funciona igual en cualquier máquina que tenga Docker
- **Limpieza**: No "ensucias" tu sistema con instalaciones

---

## 📋 Requisitos Previos

- **Docker Desktop** (o Docker Engine y Docker Compose CLI en Linux)
- El código fuente de tu aplicación de React (en este caso, en el directorio `web-app-with-docker`)
- Un editor de texto (como `nano` o Visual Studio Code)
- Conocimientos básicos de terminal/línea de comandos

### **Verificar que Docker está instalado:**
```bash
docker --version
docker compose version
```

---

## **Paso 1: El `Dockerfile` (La Receta de la Aplicación Web)**

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

# Segunda etapa: 'production'
# Usamos una imagen de Nginx para servir la aplicación estática
FROM nginx:alpine

# Copiamos el resultado de la compilación desde la etapa 'build'
COPY --from=build /app/build /usr/share/nginx/html

# Exponemos el puerto 80 del contenedor, que es donde Nginx servirá la app
EXPOSE 80

# El comando por defecto para ejecutar Nginx
CMD ["nginx", "-g", "daemon off;"]
```

### **¿Qué hace cada línea?**

- **FROM node:18-alpine AS build**: Usa una imagen base ligera de Node.js para la etapa de construcción
- **WORKDIR /app**: Establece el directorio de trabajo dentro del contenedor
- **COPY package.json ./**: Copia solo el package.json primero (para aprovechar el cache de Docker)
- **RUN npm install**: Instala las dependencias
- **COPY . .**: Copia todo el código fuente
- **RUN npm run build**: Compila la aplicación React para producción
- **FROM nginx:alpine**: Segunda etapa usando Nginx para servir archivos estáticos
- **COPY --from=build**: Copia los archivos compilados de la etapa anterior
- **EXPOSE 80**: Documenta que el contenedor expone el puerto 80
- **CMD**: Comando que se ejecuta cuando el contenedor inicia

---

## **Paso 2: El `docker-compose.yml` (El Orquestador)**

Este archivo define todos los servicios de tu aplicación (la web y la base de datos) para que Docker pueda levantarlos con un solo comando.

**Crea un archivo llamado `docker-compose.yml` en el mismo directorio raíz de tu proyecto** y pega este código:

```yaml
services:
  web:
    # Le dice a Docker que construya la imagen desde el Dockerfile en este directorio
    build: .
    # Mapea el puerto 8080 de tu máquina al puerto 80 del contenedor web
    ports:
      - "8080:80"
    # El servicio web depende de que postgres esté funcionando
    depends_on:
      - postgres
    # Restart automático si el contenedor falla
    restart: unless-stopped
  
  postgres:
    # La imagen a usar para el servicio de base de datos
    image: postgres:15-alpine
    # Mapea el puerto 5432 de tu máquina al puerto 5432 del contenedor postgres
    ports:
      - '5432:5432'
    # Define variables de entorno que necesita el contenedor de Postgres
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    # Volumen para persistir los datos de la base de datos
    volumes:
      - postgres_data:/var/lib/postgresql/data
    # Restart automático si el contenedor falla
    restart: unless-stopped

# Definición de volúmenes para persistir datos
volumes:
  postgres_data:
```

### **Explicación detallada:**

- **services**: Define los componentes de tu aplicación (web y postgres)
- **web**:
  - **build: .**: Le indica a Docker que el servicio web se construye a partir del Dockerfile que está en el directorio actual
  - **ports**: Mapea el puerto 8080 de tu máquina host al puerto 80 del contenedor
  - **depends_on**: Asegura que postgres se inicie antes que web
- **postgres**:
  - **image**: Le dice a Docker que el servicio postgres se basa en la imagen oficial que descargará de Docker Hub
  - **environment**: Resuelve el problema que tuvimos de la contraseña faltante. Aquí se la pasamos directamente en el archivo de configuración
  - **volumes**: Persiste los datos de la base de datos incluso si el contenedor se elimina
- **restart: unless-stopped**: Reinicia automáticamente los contenedores si fallan

---

## **Paso 3: Construir y Levantar Todo**

Ahora que tienes los dos archivos de configuración, puedes iniciar toda la aplicación.

**Desde el directorio raíz de tu proyecto** (`~/Escritorio/web-app-with-docker`), ejecuta el siguiente comando:

```bash
docker compose up
```

### **¿Qué hace este comando?**

1. Lee el archivo `docker-compose.yml`
2. Construye la imagen para el servicio web (usando el Dockerfile)
3. Descarga la imagen de postgres (si no la tienes)
4. Crea y lanza los contenedores `web-1` y `postgres-1`
5. Muestra los logs de ambos servicios en la misma terminal

### **Variantes útiles del comando:**

```bash
# Ejecutar en segundo plano (detached mode)
docker compose up -d

# Reconstruir las imágenes antes de iniciar
docker compose up --build

# Ver solo los logs
docker compose logs

# Seguir los logs en tiempo real
docker compose logs -f
```

---

## **Paso 4: Verificar que Funciona**

### **Verificar la aplicación web:**
Abre tu navegador y navega a `http://localhost:8080`

### **Verificar que los contenedores están corriendo:**
Abre una nueva terminal y ejecuta:

```bash
docker ps
```

Deberías ver ambos contenedores en la lista con el estado `Up`.

### **Verificar la base de datos:**
Puedes conectarte a PostgreSQL usando cualquier cliente SQL con estos datos:
- **Host**: localhost
- **Puerto**: 5432
- **Usuario**: postgres
- **Contraseña**: postgres
- **Base de datos**: postgres

---

## **Paso 5: Comandos Útiles de Docker Compose**

### **Gestión básica:**
```bash
# Detener servicios (pero mantener contenedores)
docker compose stop

# Iniciar servicios detenidos
docker compose start

# Reiniciar servicios
docker compose restart

# Ver el estado de los servicios
docker compose ps
```

### **Detener y limpiar:**
```bash
# Detener y eliminar contenedores, redes
docker compose down

# Detener y eliminar contenedores, redes Y volúmenes
docker compose down -v

# Detener, eliminar y también las imágenes
docker compose down --rmi all
```

### **Debugging y mantenimiento:**
```bash
# Ejecutar un comando dentro del contenedor web
docker compose exec web sh

# Ejecutar un comando dentro del contenedor postgres
docker compose exec postgres psql -U postgres

# Ver logs de un servicio específico
docker compose logs web
docker compose logs postgres

# Reconstruir solo un servicio
docker compose build web
```

---

## **Paso 6: Estructura Final del Proyecto**

Tu proyecto debería verse así:

```
web-app-with-docker/
├── public/
├── src/
├── package.json
├── package-lock.json
├── Dockerfile              ← Archivo nuevo
├── docker-compose.yml      ← Archivo nuevo
└── README.md
```

---

## **Troubleshooting: Problemas Comunes**

### **Error: "puerto ya en uso"**
```bash
# Ver qué está usando el puerto 8080
lsof -i :8080

# O cambiar el puerto en docker-compose.yml
ports:
  - "3000:80"  # Usar puerto 3000 en lugar de 8080
```

### **Error: "no se puede conectar a Docker daemon"**
- Asegúrate de que Docker Desktop esté corriendo
- En Linux, verifica que tu usuario esté en el grupo docker

### **Error: "build failed"**
```bash
# Limpiar cache de Docker y reconstruir
docker compose build --no-cache
```

### **La base de datos no persiste datos**
- Verifica que el volumen esté definido correctamente
- Para resetear la base de datos: `docker compose down -v`

---

## **Conceptos Clave Aprendidos**

### **Docker vs Docker Compose:**
- **Docker**: Maneja contenedores individuales
- **Docker Compose**: Orquesta múltiples contenedores y servicios

### **Multi-stage Build:**
- Reduce el tamaño de la imagen final
- Separa el entorno de desarrollo del de producción
- Mejora la seguridad al no incluir herramientas de desarrollo

### **Volúmenes:**
- Persisten datos fuera del ciclo de vida del contenedor
- Permiten compartir datos entre contenedores
- Son esenciales para bases de datos

### **Redes:**
- Docker Compose crea automáticamente una red para tus servicios
- Los servicios pueden comunicarse usando sus nombres (web, postgres)

---

## **Próximos Pasos**

Una vez que domines estos conceptos básicos, puedes explorar:

1. **Variables de entorno con archivos `.env`**
2. **Diferentes perfiles para desarrollo/producción**
3. **Healthchecks para servicios**
4. **Integración con CI/CD**
5. **Docker registries privados**
6. **Orquestación con Kubernetes**

---

## **Consejo Final**

A diferencia de `docker run` que solo maneja un contenedor, `docker compose` es la herramienta ideal para gestionar proyectos con múltiples componentes. Con esto, has pasado de la teoría a la práctica de manera exitosa.

**¡Felicitaciones!** Ahora tienes una aplicación completamente "dockerizada" que puedes compartir con cualquier persona y funcionará exactamente igual en su máquina. 🎉
