
---

# ❄️ My_NixOS

> Configuración declarativa, modular y reproducible para NixOS basada en Flakes y Home Manager. Orientada a la seguridad, virtualización, alto rendimiento y una experiencia de escritorio ligera con **Qtile**.

---

## 📑 Tabla de Contenidos

1. [Características Principales](#-características-principales)
2. [Arquitectura de Hosts](#arquitectura)
3. [Estructura del Proyecto](#-estructura-del-proyecto)
4. [Entorno de Escritorio y Tematización](#-entorno-de-escritorio-y-tematización)
5. [Seguridad y Hardening](#seguridad)
6. [Laboratorio de Ciberseguridad (Virt-Lab)](#-laboratorio-de-ciberseguridad-virt-lab)
7. [Scripts Personalizados y Utilidades](#-scripts-personalizados-y-utilidades)
8. [Gestión de Credenciales y Backups](#-gestión-de-credenciales-y-backups)
9. [Manual de Instalación](#-manual-de-instalación)

---

## 🌟 Características Principales

Este repositorio centraliza la configuración del sistema operativo y el entorno de usuario bajo la arquitectura declarativa de **NixOS**. La infraestructura se gestiona a través de **Flakes** y el framework modular **flake-parts**, lo que permite desacoplar la definición del sistema (`nixosConfigurations`) del entorno de usuario (`homeConfigurations`).

* **Punto de entrada unificado (`flake.nix`)**: Declara las fuentes fijadas (*inputs*) del ecosistema Nix (ej: `nixpkgs`, `home-manager`, `lanzaboote`, `sops-nix`) e invoca dinámicamente las definiciones modulares en `parts/`.
* **Seguridad como Pilar Central**: Aplicación estricta del principio de mínimo privilegio mediante hardening del kernel, aislamiento de aplicaciones con Firejail, y privacidad de red con DNS cifrado (DNS-over-TLS vía Quad9).
* **Tematización Dinámica**: Integración de Stylix para generar paletas de colores globales (terminales, interfaces gráficas) basadas en el fondo de pantalla animado actual seleccionado desde Steam Workshop.
* **Aprovisionamiento de Host**: Configuración de gestores de arranque seguros (UEFI Secure Boot vía Lanzaboote), soporte TPM 2.0 y el window manager `Qtile`.
* **Entorno de Usuario Reproducible**: Home Manager gestiona el perfil del usuario estableciendo terminales optimizadas (Ghostty), Neovim modular con integración de IA, y multiplexación de ventanas con Tmux.
* **Automatización y Resiliencia**: Scripts propios que orquestan reconstrucciones del sistema, pruebas efímeras de configuración, y respaldos diarios y deduplicados hacia Cloudflare R2/S3 utilizando Restic y `sops-nix`.

---
<a id="arquitectura"></a>
## 🏗️ Arquitectura de Hosts

El proyecto instancia configuraciones específicas por equipo usando dependencias comunes:

* 🖥️ **`nixos-btw` (Base)**: Host principal optimizado para la portabilidad.
* Incluye una "Especialización" llamada `baremetal` (activable en arranque) orientada a máxima potencia: habilita control de ventiladores, *overclocking* de GPU (`amdgpu`), monitoreo avanzado de discos (SMART), y desactiva virtualización pesada de Hyper-V.


* 💻 **`laptop`**: Perfil diseñado para hardware Intel. Prioriza la seguridad física y la movilidad, soportando arranque cifrado LUKS (raiz y intercambio/swap), periféricos Thunderbolt y anclaje de llaves criptográficas TPM2.

---

## 📂 Estructura del Proyecto

```text
My_NixOS/
├── flake.nix                  # Definición global de dependencias (inputs) y salidas
├── parts/                     # Configuración de nivel superior vía flake-parts
│   ├── devshell.nix           # Herramientas de formateo y testing para el repositorio
│   └── nixos.nix              # Lógica de construcción (mkHost) que ensambla equipos
├── hosts/                     # Perfiles de hardware e inicialización por equipo
│   ├── nixos-btw/
│   │   ├── hardware-configuration.nix
│   │   └── nixos-btw.nix
│   └── laptop/
├── modules/                   # Capa base del sistema operativo (servicios, kernel, boot, UI)
│   ├── base.nix               # Configuración común, usuarios, gestor de paquetes
│   ├── desktop.nix            # Subsistema gráfico, audio (Pipewire), X11/Qtile
│   ├── hardening.nix          # Sysctls de seguridad, Firejail, auditoría
│   └── virt-lab.nix           # Laboratorio de redes y contenedores de análisis
├── specialisations/           # Perfiles de arranque alternativos (ej: baremetal.nix)
├── home/                      # Perfiles de entorno de usuario (dotfiles y CLI)
│   ├── home.nix               # Programas instalados y configuración general
│   ├── config/                # Dotfiles crudos (Neovim en Lua, Rofi, Qtile)
│   └── assets/                # Fondos de pantalla y metadatos persistentes
└── secrets/                   # Archivos cifrados (sops/age) con contraseñas y tokens
    ├── hosts/
    └── .sops.yaml             # Reglas de cifrado y llaves públicas de equipos

```

---

## 🎨 Entorno de Escritorio y Tematización

El entorno gráfico está construido sobre **X11** utilizando **Qtile** (escrito en Python) como gestor de ventanas, garantizando ligereza y total programabilidad.

* **Barra Superior Inteligente**: Widgets personalizados para monitoreo de hardware, batería y Wi-Fi. Incluye integración en tiempo real con Google Calendar, obteniendo próximos eventos de forma segura mediante credenciales OAuth inyectadas por SOPS.
* **Gestor de Fondos Animados (`change-theme`)**: Script propio que visualiza tu colección de *Steam Workshop* (`linux-wallpaperengine`). Al seleccionar uno, extrae un fotograma clave (`ffmpeg`), genera una paleta de colores del sistema (`Stylix`), reinicia el motor gráfico y recompila el perfil de NixOS al instante.
* **Entorno de Terminal**:
    * **Emulador**: `Ghostty`, configurado para cero sobrecarga visual (sin bordes, barra de pestañas ni difuminados).
    * **Multiplexador**: `Tmux` con atajos al estilo Vim y soporte True Color.
    * **Editor de Código**: `Neovim` estructurado en Lua (`lazy.nvim`). Incluye soporte LSP completo (Nix, C, Bash) y asistencia de IA nativa en el editor a través de CodeCompanion y Copilot.



---
<a id="seguridad"></a>
## 🛡️ Seguridad y Hardening

La infraestructura aplica múltiples capas defensivas tanto a nivel de núcleo como de usuario.

* **Restricciones del Kernel (`sysctl` & boot parameters)**:
* Eliminación de punteros en los registros de fallos (dmesg) y ocultación de acceso a depuradores (debugfs).
* Bloqueo estricto del trazado de procesos cruzados (Yama `ptrace_scope`).
* Desactivación de sistemas de archivos y protocolos de red propensos a exploits (cramfs, firewire, tipc).
* Prevención contra ataques TOCTOU mediante enlaces simbólicos y rígidos protegidos.
* Entre otros . . .

* **Entornos Aislados (Sandboxing con Firejail)**:
* Una función Nix personalizada (`wrapFirejail`) intercepta automáticamente binarios como Brave, Vesktop (Discord), Steam y LibreOffice.
* Los procesos son encapsulados con permisos de hardware delimitados y comunicaciones D-Bus estrictamente filtradas para evitar escaladas de privilegios gráficas.


* **Filtros de Red y Privacidad**: Bloqueo de redirecciones ICMP y resolución estricta a servidores DNS seguros (Quad9) a través de conexiones cifradas TLS, mitigando la interceptación de ISP.

---

## 🔬 Laboratorio de Ciberseguridad (Virt-Lab)

Para pruebas forenses y análisis de red, el sistema despliega dinámicamente un entorno de recolección de tráfico usando contenedores declarativos de NixOS.

* **Puente Virtual (`br-lab`)**: Una interfaz puente estática (aislada del gestor de red principal) que funciona como puerta de enlace (10.0.10.1). Un servicio `systemd` gestiona su ciclo de vida, levantándolo exclusivamente cuando el entorno de laboratorio está activo.
* **Sensor Aislado (`lab-sensor`)**: Un contenedor rootless (`systemd-nspawn`) configurado para monitoreo:
* Ejecuta **Suricata** como IDS, descargando automáticamente las últimas reglas de *Emerging Threats* durante el arranque.
* Ejecuta **Zeek** en paralelo para registrar metadatos de las conexiones, deshabilitando la validación de *checksums* para poder procesar correctamente el tráfico capturado en el puente de red.


* **Análisis de Paquetes Seguros**: Integración local con herramientas como Wireshark y Termshark.

---

## 💻 Scripts Personalizados y Utilidades

El entorno incluye utilidades de línea de comandos empaquetadas nativamente para agilizar el mantenimiento iterativo de NixOS:

> ⚠️ **Aviso:** Es necesario que el *hostname* sea idéntico al nombre de la configuración declarada en el flake (`flake.nixosConfigurations`) para que el reconocimiento automático de los scripts funcione.

* **`nos` (NixOS Switch & Sync):** Herramienta maestra de orquestación. Sincroniza el código remoto de Git (`pull --rebase`), solicita contraseña administrativa gráficamente vía `rofi`, reconstruye la generación del sistema actual de NixOS y, en caso de éxito, crea un *commit* y sube los cambios al servidor remoto.
* **`not` (NixOS Test):** Compila e inyecta los cambios en la sesión actual sin alterar el cargador de arranque permanente. Ideal para validar módulos riesgosos.
* **`nop` (NixOS Purge):** Llama a `nh clean all`, depurando los artefactos obsoletos de la tienda Nix, limitando el retroceso a un máximo de 5 generaciones pasadas.

---

## 🔑 Gestión de Credenciales y Backups

### Contraseñas e Identidad

* Los valores sensibles de la infraestructura en la nube y demas secretos se aseguran con **`sops-nix`**. El alias local **`better-sops`** descifra y edita estos archivos directamente en consola usando la llave de máquina SSH y `age`.
* La navegación web utiliza a **KeePassXC** como intermediario proxy, insertado como *Native Messaging Host* dentro del *sandbox* de Chromium/Brave para auto-completar credenciales de forma aislada.

### Copias de Seguridad (Restic)

Un módulo propio (`restic.nix`) establece un trabajo cron diario:

* Transfiere volcados incrementales del directorio `/home` y `/etc/ssh` a Cloudflare R2.
* Deduplica el almacenamiento de forma inteligente, con banderas rigurosas para excluir cosas innecesarias y pesadas como cachés de lenguajes (`node_modules`, `target`), rutinas Flatpak, librerías Steam y recursos de máquinas virtuales (`.qcow2`, imágenes ISO).
* Retención de snapshots conservadora controlada automáticamente: 3 versiones diarias, 2 semanales, 1 mensual.

---

## 🚀 Manual de Instalación

> ⚠️ **Aviso para terceros:** Esta configuración está diseñada en base a mis necesidades de hardware y flujo de trabajo (usuario `neo`). Para adoptarla, **NO EJECUTES EL BUILD DIRECTAMENTE**. Debes realizar un *fork*, renombrar variables, borrar mi árbol `sops-nix` y adaptar la capa de hardware (`hardware-configuration.nix`) para tu propia máquina.

### Requisitos Previos

1. Una instalación de NixOS mínima funcional.
2. Clave SSH del host generada en `/etc/ssh/ssh_host_ed25519_key` para `sops-nix`.
3. Ir a la BIOS y ingresar con "Setup Mode" (o borrar las keys) si planeas utilizar `lanzaboote` para Secure Boot.

### Despliegue Paso a Paso

1. **Clonar el Repositorio** (recomendado en `~/.dotfiles`):
```bash
git clone https://github.com/lucascirille/My_NixOS.git ~/.dotfiles
cd ~/.dotfiles

```


2. **Detección de Hardware Crítica**:
Vuelca la configuración de particiones (LUKS/UEFI) y hardware nativo del equipo destino para evitar fallos graves en el kernel:
```bash
nixos-generate-config --show-hardware-config > hosts/nixos-btw/hardware-configuration.nix

```


3. **Cifrado Físico (LUKS con TPM2) [Opcional]**:
Si tu placa cuenta con un chip TPM2 y tu raíz está encriptada, puedes automatizar el pase de contraseña en el arranque:
```bash
sudo systemd-cryptenroll --tpm2-device=auto /dev/(particion_luks)

```


4. **Regeneración de Secretos (Sops)**:
Extrae la llave pública del host destino:
```bash
nix-shell -p ssh-to-age --run 'ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub'

```

Agrega esta llave a `.sops.yaml` y asegúrate de definir o re-encriptar tus propios valores sensibles.


5. **Claves Secure Boot (Lanzaboote)**:
(Requiere que la BIOS esté en Setup Mode).
```bash
sudo nix-shell -p sbctl
sudo sbctl create-keys
sudo sbctl enroll-keys -m

```


6. **Compilación y Activación**:
Construimos el sistema con swtich y dado que la configuración utiliza flakes tenemos que activarlo:
```bash
sudo nixos-rebuild switch --flake .#nixos-btw --extra-experimental-features "nix-command flakes"

```
