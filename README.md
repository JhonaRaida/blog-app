# Blog App — Flutter + FastAPI + MySQL

Evaluación Unidad 3 · Caso práctico: diseño de blog.

Equipo:

Joathan Uriel.

David Sosa.

José Vidal.

José Ismael.

Alejandro Ramírez.

App móvil de blog: los usuarios se registran, inician sesión, publican entradas, leen las de otros y comentan. Incluye dos funciones opcionales:

1. **Valoración con estrellas:** se califica cada entrada de 1 a 5 (un voto por usuario, se puede cambiar).
2. **Comentarios interactivos:** reacciones con emoji (👍 ❤️ 😂 😮 😢 🔥) en los comentarios y una barra de emojis rápidos al escribir.

---

## 1. Cómo funciona

El proyecto tiene tres partes que se hablan en cadena:

```
App Flutter (celular)  ──HTTP/JSON──>  API FastAPI (tu PC)  ──SQL──>  MySQL
```

- **MySQL** guarda usuarios, entradas, comentarios, estrellas y reacciones.
- **La API (FastAPI)** es la única que toca la base de datos. Revisa quién eres, valida los datos y responde en JSON.
- **La app (Flutter)** muestra las pantallas y le pide todo a la API.

### Qué pasa al iniciar sesión

1. Escribes correo y contraseña en la app.
2. La API compara la contraseña con el hash guardado (bcrypt). Si coincide, devuelve un **token** que dura 60 minutos.
3. La app guarda el token cifrado en el teléfono y lo manda en cada petición.
4. Si el token vence, la app te regresa al login sola.

### Qué puedes hacer en la app

- **Registrarte e iniciar sesión.** La contraseña necesita 8 caracteres o más, con letras y números.
- **Ver entradas:** pestaña *Todos* (de todos los usuarios) y *Mis posts*.
- **Publicar** una entrada nueva y **borrar** las tuyas (nadie más puede borrarlas).
- **Comentar** en cualquier entrada, con emojis si quieres.
- **Valorar** entradas de otros con estrellas (la propia no se puede valorar).
- **Reaccionar** a un comentario con un emoji; tocar el mismo emoji otra vez quita la reacción.

### Estructura del proyecto

```
blog-app/
├── database/schema.sql     # Crea la base de datos en MySQL
├── api/                    # API en FastAPI
│   ├── app/
│   │   ├── core/           # configuración, conexión a BD, seguridad, token
│   │   ├── models/         # tablas (SQLAlchemy)
│   │   ├── schemas/        # validación de datos (Pydantic)
│   │   ├── routers/        # rutas: auth, posts, comments
│   │   └── main.py
│   ├── tests/test_api.py   # 14 pruebas automáticas
│   └── requirements.txt
├── mobile/                 # App Flutter
│   └── lib/
│       ├── config/         # URL de la API y constantes
│       ├── models/         # User, Post, Comment
│       ├── services/       # ApiClient, AuthService, PostService
│       ├── providers/      # AuthProvider (estado de la sesión)
│       ├── screens/        # login, registro, home, detalle, crear post
│       └── widgets/        # tarjeta de post, estrellas, reacciones, comentario
└── docs/                   # reporte y diagramas
```

---

## 2. Instalación

Necesitas instalar estos programas (una sola vez por computadora):

| Programa | Versión | Para qué |
|---|---|---|
| Git | cualquiera | Descargar el proyecto |
| Python | 3.10 o superior | Ejecutar la API |
| MySQL | 8.0 (o MariaDB 10.5+) | Base de datos |
| Flutter | 3.19 o superior | Compilar la app |
| Android Studio | reciente | Emulador y herramientas de Android |

> Tip: al instalar Python en Windows marca la casilla **"Add Python to PATH"**.

### 2.1 Descargar el proyecto

```bash
git clone <LIGA_DE_TU_REPOSITORIO>
cd blog-app
```

### 2.2 Instalar las herramientas según tu sistema

**Windows**

1. Python: https://www.python.org/downloads/ (marca *Add Python to PATH*).
2. MySQL: https://dev.mysql.com/downloads/installer/ (elige *MySQL Server* y anota la contraseña de `root`).
3. Git: https://git-scm.com/download/win
4. Flutter: https://docs.flutter.dev/get-started/install/windows y Android Studio: https://developer.android.com/studio
5. Verifica en PowerShell: `python --version`, `mysql --version`, `flutter doctor`.

**macOS**

```bash
brew install python git mysql
brew services start mysql
mysql_secure_installation        # opcional: define contraseña de root
brew install --cask flutter android-studio
flutter doctor
```

**Linux (Ubuntu/Debian)**

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git mysql-server
sudo systemctl start mysql
sudo snap install flutter --classic       # o sigue la guía oficial de Flutter
flutter doctor
```

En Linux, si `mysql -u root -p` no deja entrar, usa `sudo mysql` en su lugar.

Ejecuta `flutter doctor` y resuelve lo que marque en rojo (normalmente aceptar licencias con `flutter doctor --android-licenses` y tener un emulador).

### 2.3 Crear la base de datos

```bash
mysql -u root -p < database/schema.sql
```

Se crea `blog_db` con sus 5 tablas. En Linux sin contraseña de root: `sudo mysql < database/schema.sql`.

### 2.4 Levantar la API

**Windows (PowerShell)**

```powershell
cd api
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```

**macOS / Linux**

```bash
cd api
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Abre el archivo `.env` y ajusta:

```
DATABASE_URL=mysql+pymysql://root:TU_PASSWORD@localhost:3306/blog_db
SECRET_KEY=una-clave-larga-y-aleatoria
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

Si tu contraseña de MySQL tiene caracteres especiales (`@`, `#`, `/`), escríbelos codificados (por ejemplo `@` = `%40`).

Inicia la API:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Comprueba que funciona abriendo http://localhost:8000/docs (documentación interactiva). Para detenerla: `Ctrl + C`.

### 2.5 Preparar y ejecutar la app

En otra terminal:

```bash
cd mobile
flutter create . --platforms=android,ios --project-name blog_app
flutter pub get
```

Configuración de Android (solo la primera vez):

1. En `android/app/build.gradle` (o `build.gradle.kts`) pon `minSdk = 23` (o `minSdkVersion 23`). Lo pide `flutter_secure_storage`.
2. En `android/app/src/main/AndroidManifest.xml`, dentro de `<application ...>`, agrega:
   `android:usesCleartextTraffic="true"` (permite `http://` en desarrollo).

Ejecutar según el dispositivo:

| Dispositivo | Comando | Dirección de la API |
|---|---|---|
| Emulador de Android | `flutter run` | `http://10.0.2.2:8000` (ya viene por defecto) |
| Simulador de iOS (solo macOS) | `flutter run --dart-define=API_URL=http://localhost:8000` | `localhost` |
| Celular físico | `flutter run --dart-define=API_URL=http://IP_DE_TU_PC:8000` | IP de tu PC |

**Celular físico:** el teléfono y la PC deben estar en la **misma red Wi-Fi**. Para saber la IP de tu PC: `ipconfig` (Windows) o `ifconfig` / `ip a` (macOS/Linux). Si no conecta, permite el puerto 8000 en el firewall.

---

## 3. Probar que todo funciona

1. Abre la app y toca **Regístrate**; crea una cuenta.
2. Publica una entrada con **Nuevo post**.
3. Crea una segunda cuenta (cierra sesión) y, con ella, comenta, da estrellas y reacciona.
4. Regresa a la primera cuenta y revisa el promedio de estrellas y las reacciones.

Pruebas automáticas (no tocan tu MySQL, usan una base temporal):

```bash
cd api && pytest          # API: 14 pruebas
cd mobile && flutter test # App: pruebas de modelos
```

## 4. Problemas comunes

| Problema | Solución |
|---|---|
| `Access denied for user 'root'` | Revisa usuario y contraseña en `DATABASE_URL` del `.env`. |
| `Can't connect to MySQL server` | MySQL no está iniciado: inícialo (`brew services start mysql`, `sudo systemctl start mysql` o el servicio en Windows). |
| La app dice "No se pudo conectar con el servidor" | Revisa que la API esté corriendo, que la dirección sea la correcta para tu dispositivo (ver tabla 2.5) y el firewall. |
| Error de `minSdkVersion` al compilar | Pon `minSdk = 23` como en el paso 2.5. |
| `Cleartext HTTP traffic not permitted` | Agrega `usesCleartextTraffic="true"` en el AndroidManifest. |
| Los emojis salen como `???` | La base debe crearse con `schema.sql` (usa utf8mb4); no la crees a mano. |
| `Activate.ps1 cannot be loaded` (Windows) | Ejecuta una vez `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`. |

## 5. Rutas de la API

| Método | Ruta | Descripción | Requiere sesión |
|---|---|---|---|
| POST | `/auth/register` | Crear cuenta | No |
| POST | `/auth/login` | Iniciar sesión (devuelve token) | No |
| GET | `/auth/me` | Usuario de la sesión | Sí |
| GET | `/posts` | Todas las entradas | Sí |
| GET | `/posts/mine` | Mis entradas | Sí |
| GET | `/posts/{id}` | Detalle de una entrada | Sí |
| POST | `/posts` | Crear entrada | Sí |
| DELETE | `/posts/{id}` | Borrar entrada (solo el autor) | Sí |
| PUT | `/posts/{id}/rating` | Valorar de 1 a 5 estrellas | Sí |
| GET | `/posts/{id}/comments` | Leer comentarios | Sí |
| POST | `/posts/{id}/comments` | Comentar | Sí |
| PUT | `/comments/{id}/reactions` | Poner o quitar una reacción | Sí |

## 6. Seguridad

- **Contraseñas:** se guardan con hash bcrypt (con salt); nunca en texto plano.
- **Sesiones:** token JWT firmado que caduca; en el teléfono se guarda cifrado (`flutter_secure_storage`).
- **Control de acceso:** todas las rutas, salvo registro y login, exigen token. Solo el autor borra su entrada.
- **Validación:** correo válido, contraseña fuerte, longitudes máximas y reacciones solo de una lista permitida, tanto en la app como en la API.
- **Errores:** códigos HTTP claros (401, 403, 404, 409, 422); el login da el mismo mensaje si falla el correo o la contraseña.
- **Secretos:** `.env` está en `.gitignore`; no lo subas al repositorio.

## 7. Modelo de datos

```mermaid
erDiagram
    users ||--o{ posts : escribe
    users ||--o{ comments : escribe
    posts ||--o{ comments : tiene
    users ||--o{ ratings : vota
    posts ||--o{ ratings : recibe
    comments ||--o{ comment_reactions : recibe
    users ||--o{ comment_reactions : reacciona
    users {
        int id PK
        string name
        string email UK
        string password_hash
    }
    posts {
        int id PK
        int author_id FK
        string title
        text content
    }
    comments {
        int id PK
        int post_id FK
        int author_id FK
        string content
    }
    ratings {
        int id PK
        int post_id FK
        int user_id FK
        int stars
    }
    comment_reactions {
        int id PK
        int comment_id FK
        int user_id FK
        string emoji
    }
```
