# Bobux Clicker Tycoon

Juego incremental/tycoon genérico listo para publicar, generado a partir de tu `Place1.rbxl`.

## Archivos

| Archivo | Qué es |
|---|---|
| `Place1.rbxl` | **El juego final listo para abrir y publicar.** |
| `Place1.original.rbxl` | Copia de seguridad de tu place original, sin tocar. |
| `BobuxClicker.rbxl` | Copia idéntica del juego generado (por si quieres guardarla aparte). |
| `src/Config.lua` | Economía, nombres y **IDs de gamepasses/productos**. |
| `src/Server.lua` | Servidor: clics, dinero, compras, rebirth, guardado y leaderboard. |
| `src/Client.lua` | Interfaz, botones, tienda y efectos visuales. |
| `build.lua` | Ensambla todo desde el backup y reescribe `Place1.rbxl`. |
| `build.bat` | Doble clic para regenerar `Place1.rbxl` después de editar el código. |
| `.tools/lune.exe` | Herramienta usada por `build.bat` (no necesita instalación). |

## Cómo probarlo

1. **Cierra Roblox Studio** antes de abrir el archivo (si está abierto aparece `Place1.rbxl.lock`).
2. Abre `Place1.rbxl` con Roblox Studio.
3. Presiona **Play** para probar.

## Cómo funciona

- Haz clic en el botón rosa del mundo, en el botón **¡CLIC!** de la pantalla o con la **barra espaciadora**.
- **Combo:** si clicas seguido sube un multiplicador temporal (hasta x2.5). Se apaga al dejar de clicar.
- **Críticos:** 8% de los clics valen x5 y muestran un aviso dorado.
- **Compra múltiple:** arriba de cada panel elige `x1`, `x10` o `MAX` para comprar de golpe.
- Compra generadores a la izquierda para ganar monedas por segundo y mejoras a la derecha (clic más fuerte, +25% producción, más tiempo offline).
- **Regalo diario:** pulsa el panel dorado de arriba (o el pad del mundo) para reclamar monedas y mantener una racha de hasta 7 días.
- **Logros:** 9 metas con recompensa. Consulta el botón ★ de la barra superior.
- Con suficientes clics y al menos 1 generador puedes hacer **Rebirth**: pierdes dinero y mejoras, pero ganas un multiplicador permanente (x1.5, x2.0, x2.5...).
- Hay guardado automático (DataStore), ganancias offline (hasta 2 h) y leaderboard de los mayores ganadores totales.
- La interfaz se escala sola en pantallas pequeñas y hay un tutorial inicial que se puede volver a ver borrando el guardado.

## Configurar los Robux (importante)

El juego **no genera Robux automáticamente**. Los Robux llegan solo cuando jugadores reales compran tus pases/productos (o por Premium/Paid Access si lo activas). Cualquier promesa de "Robux gratis/plata fácil" es estafa y va contra los términos de Roblox.

Para activar la tienda:

1. En [Roblox Creator Hub](https://create.roblox.com/) entra a tu experiencia y ve a **Store**.
2. Crea los gamepasses:
   - `2x MONEDAS`
   - `VIP`
   - `AUTOCLIC` (+5 clics automáticos por segundo)
3. Crea los developer products:
   - `10K Monedas`
   - `100K Monedas`
   - `Mega Pack`
4. Copia cada ID numérico en `src/Config.lua`, reemplazando `Id = 0`:

```lua
Config.Gamepasses = {
	{ Key = "Double", Id = 123456789, Name = "2x MONEDAS", ... },
	{ Key = "VIP",       Id = 123456790, Name = "VIP", ... },
{ Key = "AutoClick", Id = 123456791, Name = "AUTOCLIC", ... },
}

Config.Products = {
	{ Key = "Coins10K",  Id = 987654321, Name = "10K Monedas", Coins = 10000, ... },
	...
}
```

5. Guarda `Config.lua`, cierra Studio y ejecuta `build.bat` (o `lune run build.lua`) para regenerar `Place1.rbxl`.
6. Abre `Place1.rbxl` en Studio y publica (**File > Publish to Roblox**). En **Game Settings > Security** deja activado *Enable Studio Access to API Services* para que DataStore y el leaderboard funcionen.

Mientras un `Id` siga siendo `0`, el botón aparece con “⚠ Configura el ID” y el servidor mostrará un aviso en vez de abrir la compra.

## Publicar / actualizar

- Publica una vez desde Studio. Para subir cambios: **File > Save to Roblox** (o Publish to Existing Place).
- Si editas los `.lua`, cierra Studio y ejecuta `build.bat` antes de volver a publicar, porque Studio lee el código dentro del `.rbxl`, no los archivos de carpeta. El script se niega a escribir si detecta `Place1.rbxl.lock`.

## Balanceo rápido

Todo está en `src/Config.lua`:

- `Config.Generators`: coste base, crecimiento y monedas/segundo.
- `Config.Upgrades`: costes y límites de las mejoras.
- `Config.Rebirth`: clics requeridos y multiplicador por rebirth.
- `Config.Crit`: probabilidad y multiplicador de clics críticos.
- `Config.Combo`: ventana, tope y bonus por clic consecutivo.
- `Config.Daily`: monedas base, bonus por racha y tope de días.
- `Config.Achievements`: nombre, descripción y recompensa de cada logro.
- `Config.MaxOfflineSeconds`: tope de ganancia offline.

---

Hecho para ser un punto de partida legítimo y modificable. Éxito con el juego 🎮
