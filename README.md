# Bobux Clicker Tycoon

Juego incremental/tycoon listo para publicar. El código fuente vive en GitHub y se refleja en Roblox Studio mediante **Script Sync** (función nativa de Studio).

## Sincronización GitHub → Roblox Studio

### 1. Configuración única en Studio

La carpeta local del repo es `C:\Users\SoporteTIC\Desktop\Bobux`.

1. Abre `Place1.rbxl` con Roblox Studio (si ya está abierto, mejor).
2. En el **Explorer**, selecciona con `Ctrl+clic` estos tres contenedores:
   - `ReplicatedStorage`
   - `ServerScriptService`
   - `StarterPlayerScripts` (dentro de `StarterPlayer`)
3. Clic derecho → **Script Sync → Sync to…** → elige la carpeta `C:\Users\SoporteTIC\Desktop\Bobux`.
4. Si aparece el diálogo de conflictos, elige **Keep Disk** para que gane el código de GitHub (elige *Keep Studio* solo si tenías cambios sin guardar en Studio que quieras conservar).

Studio recuerda esta configuración y la restaura al volver a abrir el place. No hay que instalar plugins.

### 2. Dejar el vigilante activo

Haz doble clic en **`sync-from-github.bat`** y deja la ventana abierta. Cada 30 segundos comprueba `main` en GitHub:

- Si hay cambios nuevos, los baja a esta carpeta.
- Script Sync aplica los cambios de `.luau` dentro de Studio automáticamente.
- Si el cambio está en `build.lua` o en un `.rbxl`, el vigilante **cierra Studio de forma ordenada, ejecuta `build.lua` y vuelve a abrir `Place1.rbxl`**. Si Studio te pregunta si quieres guardar, responde y el proceso continúa solo en el siguiente ciclo; nunca se fuerza el cierre para no perder trabajo.
- Si detectas que no se aplica nada, revisa la ventana del vigilante: si hay cambios locales sin commitear, se detiene para no sobrescribirlos (usa `sync-from-github.ps1 -DiscardLocal` si quieres que gane GitHub siempre).

### 3. Flujo normal

1. Editas un archivo en GitHub (por ejemplo `ServerScriptService/GameServer.server.luau`) y haces commit en `main`.
2. Esperas ~30 s.
3. El script cambia en Studio sin cerrarlo. Si tocaste `build.lua` o un place, Studio se cierra y se reabre solo con la versión regenerada.

> Si editas el código dentro de Studio, Script Sync escribirá el archivo en disco. Haz commit de ese cambio antes de editar el mismo archivo en GitHub, o el vigilante se saltará el pull para protegerlo.

## Archivos

| Archivo | Qué es |
| --- | --- |
| `ReplicatedStorage/Config.luau` | Economía, nombres e IDs de gamepasses/productos (ModuleScript `Config`). |
| `ServerScriptService/GameServer.server.luau` | Servidor: clics, dinero, compras, rebirth, guardado y leaderboard. |
| `StarterPlayerScripts/Client.local.luau` | Interfaz, botones, tienda y efectos visuales (LocalScript `Client`). |
| `Place1.rbxl` | Place generado, listo para abrir y publicar. |
| `Place1.original.rbxl` | Copia de seguridad del place original, sin tocar. |
| `BobuxClicker.rbxl` | Copia idéntica del juego generado. |
| `build.lua` | Ensambla el place desde el backup usando los tres `.luau` de arriba. |
| `build.bat` | Doble clic para regenerar `Place1.rbxl` después de editar `build.lua`. |
| `sync-from-github.ps1` / `.bat` | Vigilante que baja cambios de GitHub a esta carpeta. |
| `.tools/lune.exe` | Herramienta usada por `build.bat` en esta PC (no se sube al repo). |

## Cómo probarlo

1. Cierra Roblox Studio antes de regenerar el place (si está abierto aparece `Place1.rbxl.lock`).
2. Abre `Place1.rbxl` con Roblox Studio.
3. Pulsa **Play**.

## Cómo se juega

- Haz clic en el botón rosa del mundo, en **¡CLIC!** o con la barra espaciadora.
- **Combo:** clics seguidos suben un multiplicador temporal (hasta x2.5).
- **Críticos:** 8 % de los clics valen x5 y muestran aviso dorado.
- **Compra múltiple:** elige `x1`, `x10` o `MAX` sobre cada panel.
- Generadores a la izquierda (monedas/segundo) y mejoras a la derecha (clic, producción, tiempo offline).
- **Regalo diario:** panel dorado superior o el pad del mundo (racha de hasta 7 días).
- **Logros:** 9 metas con recompensa (botón ★).
- **Rebirth:** con suficientes clics y al menos 1 generador; multiplicador permanente.
- Guardado automático (DataStore), ganancias offline (hasta 2 h) y leaderboard.

## Configurar los Robux (importante)

El juego **no genera Robux automáticamente**. Los Robux llegan solo cuando jugadores reales compran tus pases/productos. Cualquier promesa de "Robux gratis" es estafa y va contra los términos de Roblox.

1. En [Roblox Creator Hub](https://create.roblox.com/) → tu experiencia → **Store**.
2. Crea los gamepasses `2x MONEDAS`, `VIP`, `AUTOCLIC` y los developer products `10K Monedas`, `100K Monedas`, `Mega Pack`.
3. Copia los IDs numéricos en `ReplicatedStorage/Config.luau`, reemplazando `Id = 0`:

```lua
Config.Gamepasses = {
	{ Key = "Double", Id = 123456789, Name = "2x MONEDAS", ... },
	{ Key = "VIP", Id = 123456790, Name = "VIP", ... },
	{ Key = "AutoClick", Id = 123456791, Name = "AUTOCLIC", ... },
}
Config.Products = {
	{ Key = "Coins10K", Id = 987654321, Name = "10K Monedas", Coins = 10000, ... },
	...
}
```

4. Guarda y haz commit en GitHub: el vigilante baja el cambio y Script Sync lo mete en Studio.
5. Publica (**File > Publish to Roblox**). En **Game Settings > Security** deja activado *Enable Studio Access to API Services* para DataStore y leaderboard.

Mientras un `Id` siga siendo `0`, el botón muestra "⚠ Configura el ID".

## Publicar / actualizar

- Publica una vez desde Studio. Para subir cambios: **File > Save to Roblox**.
- Los cambios de código se ven en Studio sin regenerar nada.
- Si cambias `build.lua` o un `.rbxl` en GitHub, el vigilante hace el cierre → `build.lua` → reapertura por ti. `build.bat` sigue disponible para usarlo a mano; se niega a escribir si detecta `Place1.rbxl.lock`.

## Balanceo rápido

Todo está en `ReplicatedStorage/Config.luau`: `Generators`, `Upgrades`, `Rebirth`, `Crit`, `Combo`, `Daily`, `Achievements` y `MaxOfflineSeconds`.

---

Hecho para ser un punto de partida legítimo y modificable. Éxito con el juego 🎮
