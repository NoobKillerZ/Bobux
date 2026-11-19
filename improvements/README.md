# Neon Arcade — propuesta de pulido v1

Esta rama NO sustituye las mecanicas actuales ni altera el guardado. La rama `main` sigue intacta.

## Diagnostico verificado
- `build.lua` genera un entorno con base de 160x160, suelo cuadriculado, 14 pilares, 6 pedestales de generadores y portal Rebirth.
- El README describe monedas, combos, criticos, rebirth, recompensas diarias y logros. **No se pudieron verificar esos scripts**: la carpeta `src/` no existe en la rama principal.
- `build.lua` intenta leer `src/Config.lua`, `src/Server.lua` y `src/Client.lua`. La compilacion fallara hasta que se restauren esos archivos.
- El README tambien menciona `.tools/lune.exe`, pero ese ejecutable no esta versionado.

## Instalar la primera capa visual SIN reconstruir el .rbxl
1. Abrir una copia de `Place1.rbxl` en Roblox Studio.
2. En `ServerScriptService` crear un `Script` llamado `BobuxLighting` y pegar `improvements/BobuxLighting.server.lua`.
3. En `StarterPlayer > StarterPlayerScripts` crear un `LocalScript` llamado `BobuxUIEffects` y pegar `improvements/BobuxUIEffects.client.lua`.
4. Opcional: crear un `ModuleScript` en `ReplicatedStorage` llamado `BobuxPopup` y pegar `improvements/BobuxPopup.lua`. El modulo solo muestra popup si se llama explicitamente desde el cliente; no inventa recompensas.
5. Probar Play solo y Start Server + 2 Players, luego emulacion tactil. Verificar que el nuevo script no interfiera con la UI previa.
6. Guardar como NUEVA copia y probar en telefono antes de publicar.

## Direccion artistica
- Fondo #101628, paneles #253659, accion #35D8FF, click principal #FF53AD, recompensas #FFD66B.
- Uso moderado de Neon solamente en bordes, portal, boton central y recompensas.
- Materiales: Slate, SmoothPlastic, Metal; SurfaceAppearance PBR solo para elementos protagonistas con mapas comprimidos.
- Evitar una luz por baldosa y demasiadas particulas simultaneas. Priorizar contraste y legibilidad.
- DOF desactivado; Bloom suave. Las opciones LightingStyle/Technology pueden variar entre versiones de Studio.

## UI / UX
- HUD: monedas / segundo / combo arriba; click principal accesible abajo; accesos de tienda, mejoras, logros y Rebirth por prioridad.
- Usar `Scale` en `UDim2`, `UIListLayout`, `UIPadding`, `UISizeConstraint` y `UIAspectRatioConstraint` solo donde preserve bien la relacion visual.
- `GuiButton.Activated` para raton, toque y mando; comprobar seleccion de gamepad.
- `BobuxUIEffects.client.lua` pule botones EXISTENTES y no duplica HUD.

## Game feel
- Pulso de escala al pulsar, microsonido opcional, feedback de click confirmado por servidor.
- Popups solo con valores confirmados; limitar cantidad simultanea.
- Particulas cortas de bajo costo y camera shake opcional de amplitud muy reducida, sin afectar accesibilidad.
- Movimiento del avatar con animaciones compatibles R15 solo si se tienen assets propios.

## Core loop
1. Primeros 10 segundos: click + primera compra resaltada.
2. Primer minuto: generador 1 y barra visible de progreso hacia siguiente objetivo.
3. 5-10 minutos: nuevas estaciones, cosméticos y una meta Rebirth clara.
4. Mantener recompensas diarias ya documentadas; evitar mecanicas aleatorias de apuestas.
5. Guardar progresos en servidor; validar compras y recompensas en servidor; nunca confiar en cantidades enviadas por el cliente.

## Rendimiento
- `Workspace.StreamingEnabled` configurarlo en Studio y probar conexiones lentas.
- Evitar `RenderStepped` para animar todos los adornos; usar Tweens y eventos.
- Apagar `CanTouch`/`CanQuery` en decoraciones no interactivas cuando no sean necesarios.
- Evitar texturas 4K; probar perfiles GPU/CPU y memoria con herramientas de Studio.
- Comprobar que efectos repetidos no se acumulen tras respawn.

## Bloqueador del build original
Restaurar `src/Config.lua`, `src/Server.lua`, `src/Client.lua` desde el proyecto fuente antes de ejecutar `build.bat`. Los scripts incrustados en `.rbxl` no han podido auditarse con esta conexion. Estos archivos de `improvements/` se instalan manualmente en Studio hasta resolver ese punto.

## Pruebas pendientes
No se ha ejecutado Roblox Studio ni se ha compilado el juego. Las tres piezas Luau son una primera propuesta lista para probar, NO una build validada ni publicada.
