# Semana del equipo · cómo ponerla en marcha

Web instalable (PWA) de tareas semanales. El código se publica en **GitHub Pages** y los datos y usuarios se guardan en **Supabase**.

## 1. Supabase: crear la base de datos (una sola vez)

1. Entra en supabase.com y crea un proyecto nuevo (**New project**). Elige la región de Europa más cercana y apunta la contraseña de la base de datos en un lugar seguro.
2. Ve a **SQL Editor → New query**, pega el contenido completo de `supabase/schema.sql` y pulsa **Run**. Debe terminar con "Success".
3. Ve a **Project Settings → API** y copia:
   - **Project URL** (algo como `https://abcd1234.supabase.co`)
   - **anon public key** (una clave larga que empieza por `eyJ...`)
4. Abre `config.js` con el Bloc de notas, pega esos dos valores en lugar de `PEGA_AQUI_...` y guarda.
5. En **Authentication → Sign In / Providers → Email**:
   - Deja activado **Confirm email**.
   - Desactiva **Allow new users to sign up**. Así solo entra quien tú des de alta.

## 2. GitHub: publicar la web

1. En github.com pulsa **New repository**. Ponle de nombre `gestor-tareas`, márcalo como **Public** y créalo.
2. En la página del repositorio pulsa **uploading an existing file** y arrastra **todo el contenido** de esta carpeta: `index.html`, `config.js`, `manifest.webmanifest`, `sw.js`, la carpeta `icons` y la carpeta `supabase`. Pulsa **Commit changes**.
3. Ve a **Settings → Pages**. En *Source* elige **Deploy from a branch**, rama **main**, carpeta **/ (root)**, y pulsa **Save**.
4. Espera uno o dos minutos. Tu app estará en `https://TU-USUARIO.github.io/gestor-tareas/`.

## 3. Conectar las dos cosas

En Supabase, ve a **Authentication → URL Configuration** y pon en **Site URL** la dirección de tu app (`https://TU-USUARIO.github.io/gestor-tareas/`). Sirve para que los correos de "olvidé mi contraseña" lleven a tu app.

## 4. Tu primer acceso (administrador)

1. En Supabase: **Authentication → Users → Add user → Create new user**. Pon tu correo y una contraseña, marca **Auto Confirm User** y créalo.
2. Abre la app, entra con ese correo y escribe tu nombre. Quedarás como administrador.

## 5. Dar de alta a cada empleado

Para cada persona hay que hacer dos cosas, siempre con **el mismo correo**:

1. **En Supabase:** Authentication → Users → Add user → Create new user, con su correo, una contraseña inicial y **Auto Confirm User** marcado.
2. **En la app:** Equipo → escribe su nombre y su correo → Añadir. Aquí decides si puede editar las tareas de los demás o si es administrador.

Después pásale el enlace de la app y su contraseña inicial. Puede cambiarla en el botón con su nombre (arriba a la derecha) → Cambiar contraseña.

## 6. Instalar la app

- **Windows / Mac (Chrome o Edge):** abre el enlace y pulsa **Instalar app** dentro de la propia app, o el icono de instalar en la barra de direcciones. Queda en el escritorio y en el menú de inicio, en su propia ventana.
- **Android (Chrome):** menú ⋮ → **Instalar aplicación** o **Añadir a pantalla de inicio**.
- **iPhone / iPad (Safari):** botón Compartir → **Añadir a pantalla de inicio**.

## Cambios futuros

Para actualizar la app, sube el archivo modificado al repositorio (Add file → Upload files). En uno o dos minutos la web se actualiza, y las apps instaladas cogen la versión nueva la próxima vez que se abren.

## Bueno saber

- Los permisos (quién edita qué) los aplica la base de datos, no solo la pantalla, así que nadie puede saltárselos.
- La clave de `config.js` es pública por diseño y puede estar a la vista en GitHub sin problema. **Nunca** pegues en ningún archivo la clave `service_role` de Supabase.
- Supabase pausa los proyectos gratuitos que pasan una semana sin uso. Si ocurre, entra en supabase.com y pulsa **Restore**; no se pierde nada.
- Las tareas sin terminar de días anteriores aparecen solas en el día de hoy. Las terminadas se quedan en su día.
