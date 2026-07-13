# Obsidian App Troubleshooting

## Blank dark/black screen on Windows (GPU rendering failure)

**Symptom:** Obsidian opens to a completely uniform dark grey/near-black window — no UI elements, no icons, no text, no file explorer. The main process starts fine (checking for updates in `%APPDATA%\Obsidian\obsidian.log`), but the Electron/Chromium renderer cannot paint the window.

**Root cause:** GPU / WebGPU (Dawn) hardware acceleration failure — very common with Electron apps on Windows 10. The `DawnGraphiteCache` and `DawnWebGPUCache` shader caches can become corrupted, or the GPU driver doesn't cooperate with Electron's WebGPU renderer.

### Fix

1. **Close Obsidian fully.** Check Task Manager — `Obsidian.exe` processes can linger.

2. **Create the GPU-disable flags file:**

   Write `{"disable-gpu": true}` to `%APPDATA%\Obsidian\obsidian-flags.json`.

   ```bash
   echo '{"disable-gpu": true}' > "$APPDATA/Obsidian/obsidian-flags.json"
   ```

   This tells Electron to skip GPU hardware rendering and use the software fallback.

3. **Clear the Dawn/WebGPU shader caches** (corrupted cached shaders can cause the same symptom even with correct config):

   ```bash
   rm -rf "$APPDATA/Obsidian/GPUCache/"*
   rm -rf "$APPDATA/Obsidian/DawnGraphiteCache/"*
   rm -rf "$APPDATA/Obsidian/DawnWebGPUCache/"*
   ```

4. **Reopen Obsidian.** It should render normally using software-based drawing.

### If still broken

- Try launching with explicit CLI flags: `"C:\Program Files\Obsidian\Obsidian.exe" --disable-gpu --disable-software-rasterizer`
- Check for GPU driver updates (Intel, NVIDIA, AMD) — outdated drivers are a common trigger.
- The %APPDATA%\Obsidian folder contains the `obsidian.json` (vault registry), `obsidian.log` (main process logs), and the `blob_storage`/`Local Storage`/`IndexedDB` directories (app state). Back up before aggressive clearing.

## Useful paths (Windows)

| Item | Path |
|------|------|
| Vault list / vault registry | `%APPDATA%\Obsidian\obsidian.json` |
| Main process log | `%APPDATA%\Obsidian\obsidian.log` |
| GPU flags file | `%APPDATA%\Obsidian\obsidian-flags.json` |
| Vault config (per vault) | `<vault_root>\.obsidian\app.json` |
| Community plugins config | `<vault_root>\.obsidian\community-plugins.json` |
| Workspace layout | `<vault_root>\.obsidian\workspace.json` |
| Core plugins enabled | `<vault_root>\.obsidian\core-plugins.json` |

## Community plugin crash — blank screen

If the user has community plugins (`community-plugins.json` is **not** `[]`) and gets a blank screen:

1. Close Obsidian.
2. Temporarily rename or empty `community-plugins.json` to `[]`.
3. Reopen Obsidian — it should load without plugins.
4. Re-enable plugins one by one to find the culprit.

## Stuck on "Loading cache..." / "Opening vault..." (Windows)

**Symptom:** Obsidian splash screen hangs indefinitely on "Loading cache..." or "Opening vault..." spinner. Main process starts (visible in Task Manager) but UI never appears.

**Root cause:** Corrupted cache databases (main `Cache/`, `GPUCache/`, `Code Cache/`, Dawn caches) or stale `workspace.json`/`obsidian.log` preventing clean startup.

### Fix

1. **Close Obsidian fully** (check Task Manager for lingering `Obsidian.exe` processes).

2. **Clear all Electron/Chromium cache folders:**

   ```powershell
   Remove-Item -Recurse -Force "$env:APPDATA\obsidian\Cache" -ErrorAction SilentlyContinue
   Remove-Item -Recurse -Force "$env:APPDATA\obsidian\GPUCache" -ErrorAction SilentlyContinue
   Remove-Item -Recurse -Force "$env:APPDATA\obsidian\Code Cache" -ErrorAction SilentlyContinue
   Remove-Item -Recurse -Force "$env:APPDATA\obsidian\DawnGraphiteCache" -ErrorAction SilentlyContinue
   Remove-Item -Recurse -Force "$env:APPDATA\obsidian\DawnWebGPUCache" -ErrorAction SilentlyContinue
   Remove-Item "$env:APPDATA\obsidian\obsidian.log" -ErrorAction SilentlyContinue
   Remove-Item "$env:APPDATA\obsidian\workspace.json" -ErrorAction SilentlyContinue
   ```

3. **Reopen Obsidian.** It will rebuild all caches fresh on first launch.

### If still stuck

- Disable GPU acceleration as in the blank-screen fix above (create `obsidian-flags.json` with `{"disable-gpu": true}`).
- Check `obsidian.log` after a failed launch attempt for error clues.
- Temporarily disable community plugins by setting `<vault>/.obsidian/community-plugins.json` to `[]`.

## Wrong vault registered in obsidian.json

**Symptom:** Obsidian hangs on "Loading cache..." but the vault shown on the splash or in the vault switcher is not the intended vault — e.g. it shows the Hermes config folder, a OneDrive folder, or some other directory that isn't a real vault.

**Root cause:** The vault registry at `%APPDATA%\Obsidian\obsidian.json` has only a wrong folder registered (or is missing the correct vault entirely). Obsidian tries to index whatever is in that folder and chokes on non-note files (config, binaries, caches).

### Diagnosis

Check the vault registry:
```bash
cat "$APPDATA/Obsidian/obsidian.json"
```
If it shows a path like `C:\Users\<user>\AppData\Local\hermes` (or any non-vault path) and does **not** show the intended vault (e.g. `C:\Users\<user>\Desktop\Vault`), the registry is wrong.

Also check if a spurious `.obsidian` folder was created inside the wrong path:
```bash
ls -la <wrong-path>/.obsidian
```
Obsidian auto-creates `.obsidian/` inside any folder it treats as a vault — seeing this outside the real vault confirms the registry issue.

### Fix

1. **Close Obsidian fully** (check Task Manager for lingering `Obsidian.exe`).

2. **Edit `obsidian.json`** to replace the wrong vault path with the correct one. Use Python for properly escaped JSON on Windows:

   ```bash
   python -c "
   import json
   config = json.load(open('$APPDATA/Obsidian/obsidian.json'))
   vault_id = list(config['vaults'].keys())[0]
   config['vaults'][vault_id]['path'] = r'C:\Users\<user>\Desktop\Vault'
   json.dump(config, open('$APPDATA/Obsidian/obsidian.json', 'w'), separators=(',', ':'))
   "
   ```

3. **Remove the spurious `.obsidian`** that Obsidian created inside the wrong path:

   ```bash
   rm -rf "<wrong-path>/.obsidian"
   ```

4. **Reopen Obsidian** — it should open straight into the correct vault without the cache hang.
