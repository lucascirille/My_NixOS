
# ❄️ My_NixOS

> Configuración declarativa, modular y reproducible para NixOS basada en Flakes y Home Manager. Orientada a la seguridad, virtualización, alto rendimiento y una experiencia de escritorio ligera con **Qtile**.

---

## 📑 Tabla de Contenidos

1. [Características Principales](#-características-principales)
2. [Tecnologías Empleadas](#️-tecnologías-empleadas)
3. [Estructura del Proyecto](#-estructura-del-proyecto)
4. [Manual de Instalación](#-manual-de-instalación)
5. [Gestión de Credenciales](#-gestión-de-credenciales-y-secretos)

---

## 🌟 Características Principales

Este repositorio centraliza la configuración del sistema operativo y el entorno de usuario bajo la arquitectura declarativa de **NixOS**. La infraestructura se gestiona a través de **Flakes** y el framework modular **flake-parts**, lo que permite desacoplar la definición del sistema (`nixosConfigurations`) del entorno de usuario (`homeConfigurations`).

* **Punto de entrada unificado (`flake.nix`)**: Declara las fuentes fijadas (*inputs*) del ecosistema Nix (`nixpkgs`, `home-manager`, `lanzaboote`, `sops-nix`) e invoca dinámicamente las definiciones modulares en `parts/`.
* **Aprovisionamiento de Host (`nixos-btw`)**: Define el perfil de la máquina principal, configurando un gestor de arranque seguro (UEFI Secure Boot), soporte TPM 2.0, el display manager minimalista `ly`, y el window manager `Qtile`.
* **Gestión de Secretos Segura**: Los valores sensibles se cifran mediante `sops-nix`, utilizando la clave SSH ED25519 del host para un descifrado seguro en tiempo de compilación y arranque.
* **Entorno de Usuario Reproducible**: Home Manager gestiona el perfil del usuario `neo`, estableciendo variables de entorno, herramientas de terminal, Neovim (con LSP) y utilidades de indexación rápida.

---

## 🛠️ Tecnologías Empleadas

### 🐧 Sistema Base
* **OS**: [NixOS](https://nixos.org/) (`nixos-26.05`)
* **Entorno de Usuario**: [Home Manager](https://github.com/nix-community/home-manager) (`release-26.05`)
* **Arquitectura**: [flake-parts](https://flake.parts/)

### 🔐 Seguridad y Criptografía
* **Arranque**: [Lanzaboote](https://github.com/nix-community/lanzaboote) (Soporte para UEFI Secure Boot)
* **Hardware**: Soporte para TPM 2.0 (`security.tpm2`)
* **Secretos**: [sops-nix](https://github.com/Mic92/sops-nix) (Gestión y descifrado con age/ssh)

### 🖥️ Entorno Gráfico
* **Display Manager**: [Ly](https://github.com/fairyglade/ly)
* **Window Manager**: [Qtile](https://qtile.org/)
* **Estética y Temas**: [Stylix](https://github.com/danth/stylix)

### 📦 Virtualización, Multimedia y Gaming
* **Virtualización**: QEMU / KVM / `libvirtd` con soporte para TPM emulado (`swtpm`) y Docker (rootless, con poda automática).
* **Audio**: PipeWire (ALSA, PulseAudio, JACK) y Blueman.
* **Gaming**: Steam, GameMode y `nix-ld` (para ejecución de binarios dinámicos no empaquetados para Nix).
* **Paquetería adicional**: Integración con [nix-flatpak](https://github.com/gmodena/nix-flatpak) y Flathub / Flatseal.

---

## 📂 Estructura del Proyecto

```text
My_NixOS/
├── flake.nix                  # Definición global de inputs, salidas y orquestación con flake-parts
├── flake.lock                 # Hash de versiones exactas de las dependencias externas
├── parts/                     # Módulos de flake-parts que ensamblan configuraciones
│   └── nixos.nix              # Declaración de la máquina 'nixos-btw' y su enlace con Home Manager
├── hosts/                     # Configuraciones específicas por equipo/hardware
│   └── nixos-btw/
│       ├── default.nix        # Módulo raíz del host
│       ├── hardware.nix       # Detección y parámetros de hardware del equipo
│       └── nixos-btw.nix      # Configuración del sistema base (servicios, kernel, boot, UI)
├── home/                      # Perfiles y dotfiles de Home Manager
│   └── home.nix               # Paquetes de usuario, variables de entorno y shells para 'neo'
├── modules/                   # Módulos NixOS o Home Manager personalizados y reutilizables
├── specialisations/           # Configuraciones alternativas de arranque (ej. perfiles para VM)
└── secrets/                   # Archivos cifrados con sops/age para variables y credenciales
    └── hosts/
        └── nixos-btw.yaml

```

---

## 🚀 Manual de Instalación

> ⚠️ **Aviso para terceros:** Esta configuración está hecha a medida para mi hardware y mi usuario personal (`neo`). Si querés usar esta configuración como base, **NO ejecutes el build directamente**. Deberás hacer un fork, cambiar el nombre de usuario, remover/adaptar mis archivos de `sops-nix` (secretos) y ajustar los drivers (en caso de ser necesario) en `nixos-btw.nix` a tu propio hardware.

### Requisitos Previos

1. Una instalación funcional de NixOS con soporte para Flakes habilitado:
   ```nix
   nix.settings.experimental-features = [ "nix-command" "flakes" ];

2. Clave SSH del host generada en `/etc/ssh/ssh_host_ed25519_key` (requerida por `sops-nix`).
3. Para Secure Boot (`lanzaboote`): Debes tener UEFI habilitado y las llaves generadas con `sbctl` en `/etc/secureboot`.

### Despliegue Paso a Paso

1. **Clonar el repositorio** (recomendado en `~/.dotfiles`):
```bash
git clone [https://github.com/lucascirille/My_NixOS.git](https://github.com/lucascirille/My_NixOS.git) ~/.dotfiles
cd ~/.dotfiles

```


2. **Generar la configuración de hardware**:
Es obligatorio volcar la configuración de particiones y hardware del equipo destino para evitar kernel panics:
```bash
nixos-generate-config --show-hardware-config > hosts/nixos-btw/hardware.nix

```


3. **Configurar Secure Boot (Lanzaboote)**:
Si es la primera vez que instalás en este equipo, generá las claves de Secure Boot (asegurate de estar en Setup Mode en la BIOS):
```bash
sudo nix-shell -p sbctl
sudo sbctl create-keys
sudo sbctl enroll-keys -m  # para Microsoft
```


4. **Gestión de Secretos (`sops`)**:
Obtené la clave pública (age) de la máquina destino:
```bash
nix-shell -p ssh-to-age --run 'ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub'

```


*Nota: Deberás agregar esta clave devuelta al archivo `.sops.yaml` y re-encriptar los secretos con `sops updatekeys secrets/hosts/nixos-btw.yaml`.*
5. **Compilar y activar el sistema**:
* Usando el comando estándar de NixOS:
```bash
sudo nixos-rebuild switch --flake .#nixos-btw

```


* O mediante `nh` (Nix Helper) si ya lo tenés instalado en tu entorno:
```bash
nh os switch

```



---

## 🔑 Gestión de Credenciales y Secretos

El sistema utiliza **KeePassXC** no solo como administrador de contraseñas tradicional, sino como backend universal del estándar **FreeDesktop Secret Service API** (`org.freedesktop.secrets`) y pasarela de credenciales para navegadores web:

* **Llavero del Sistema (VS Code, Git, etc.)**: KeePassXC expone una interfaz D-Bus nativa que reemplaza a GNOME Keyring o KWallet. Gestiona los tokens de inicio de sesión de VS Code (GitHub, Microsoft Sync) y credenciales del sistema de forma cifrada en la base de datos principal (`.kdbx`).
* **Navegadores Chromium / Brave**: La configuración de Home Manager aprovisiona automáticamente el archivo de manifiesto en `~/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts/org.keepassxc.keepassxc_browser.json`, permitiendo la conexión segura mediante `keepassxc-proxy` con la [extensión oficial](https://chromewebstore.google.com/detail/keepassxc-browser/oboonakemofpalcgghocfoadofidjkkk).

