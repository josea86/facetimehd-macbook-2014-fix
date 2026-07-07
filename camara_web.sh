#!/bin/bash

# Este script instala el driver facetimehd (bcwc_pcie) y el firmware
# para la cámara Broadcom/iSight en MacBook Pro Retina con Ubuntu/Debian.

# --- Configuración de rutas ---
# Guardamos el directorio actual desde donde se lanza el script
RUTA_TRABAJO=$(pwd)

BOOTCAMP_ZIP="bootcamp5.1.5769.zip"
BOOTCAMP_URL="https://download.info.apple.com/Mac_OS_X/031-30890-20150812-ea191174-4130-11e5-a125-930911ba098f/bootcamp5.1.5769.zip"
FW_REPO="https://github.com/patjak/facetimehd-firmware.git"
DRIVER_REPO="https://github.com/patjak/bcwc_pcie.git"

# Asegurarnos de que estamos en la ruta de trabajo inicial antes de limpiar
cd "$RUTA_TRABAJO"

# Limpieza de directorios antiguos antes de empezar en la ruta local
rm -rf facetimehd-firmware bcwc_pcie bootcamp_tmp "$BOOTCAMP_ZIP"

echo "=================================================="
echo "  INICIO DE LA INSTALACIÓN COMPLETA DE LA CÁMARA  "
echo "      (Usando descarga directa de Boot Camp)      "
echo "=================================================="

# --- 1. Instalar dependencias ---
echo -e "\n[PASO 1/7] Actualizando el sistema e instalando dependencias (curl, git, unrar, build-essential, mpv)..."
sudo apt update > /dev/null 2>&1
sudo apt install -y curl git unrar build-essential linux-headers-$(uname -r) mpv || {
    echo "Error al instalar dependencias. Comprueba la conexión a internet o los repositorios."
    exit 1
}
echo "Dependencias instaladas correctamente."

# --- 2. DESCARGA DEL ARCHIVO BOOTCAMP ---
echo -e "\n[PASO 2/7] Descargando el archivo de Boot Camp desde Apple..."
# Eliminado el cd ~ para mantenernos en la ruta local de trabajo
curl -L -o "$BOOTCAMP_ZIP" "$BOOTCAMP_URL" || {
    echo "ERROR: Falló la descarga del archivo ZIP de Boot Camp."
    echo "Comprueba la URL o la conexión. Saliendo."
    exit 1
}
echo "Archivo Boot Camp descargado correctamente como: $BOOTCAMP_ZIP"


# --- 3. INSTALACIÓN DE FIRMWARE ---
echo -e "\n[PASO 3/7] Instalando el firmware (facetimehd-firmware)..."
git clone "$FW_REPO" || { echo "Error al clonar el firmware. Saliendo."; exit 1; }
cd facetimehd-firmware
make || { echo "Error en make del firmware. Saliendo."; exit 1; }
sudo make install || { echo "Error en make install del firmware. Saliendo."; exit 1; }
cd "$RUTA_TRABAJO" # Volvemos a la ruta raíz de trabajo de forma segura
echo "Firmware base instalado en /usr/lib/firmware/facetimehd."


# --- 4. EXTRACCIÓN Y COPIA DE ARCHIVOS DE CALIBRACIÓN (.dat) ---
echo -e "\n[PASO 4/7] Extrayendo archivos de calibración del archivo descargado..."

unzip "$BOOTCAMP_ZIP" -d bootcamp_tmp || { echo "Error al descomprimir el ZIP descargado. Saliendo."; exit 1; }
echo "Archivo ZIP descomprimido correctamente."

cd bootcamp_tmp/BootCamp/Drivers/Apple/
echo "Archivo AppleCamera.sys extraído."

# Aquí se usa 'unrar' para extraer el .sys del .exe
unrar x AppleCamera64.exe || { echo "Error al extraer AppleCamera.sys. Saliendo."; exit 1; }

# Extracción de los archivos .dat del .sys (usamos dd)
echo "Extrayendo archivos .dat (calibración del sensor)..."
dd bs=1 skip=1663920 count=33060 if=AppleCamera.sys of=9112_01XX.dat 2> /dev/null
dd bs=1 skip=1644880 count=19040 if=AppleCamera.sys of=1771_01XX.dat 2> /dev/null
dd bs=1 skip=1606800 count=19040 if=AppleCamera.sys of=1871_01XX.dat 2> /dev/null
dd bs=1 skip=1625840 count=19040 if=AppleCamera.sys of=1874_01XX.dat 2> /dev/null

# Copiar los .dat a la carpeta de firmware
sudo cp *.dat /usr/lib/firmware/facetimehd/ || { echo "Error al copiar archivos .dat a /usr/lib/firmware/facetimehd/. Saliendo."; exit 1; }
cd "$RUTA_TRABAJO" # Volvemos a la ruta raíz de trabajo
echo "Archivos .dat de calibración copiados."


# --- 5. INSTALACIÓN DEL DRIVER (bcwc_pcie) ---
echo -e "\n[PASO 5/7] Instalando el driver (bcwc_pcie)..."
git clone "$DRIVER_REPO" || { echo "Error al clonar el driver. Saliendo."; exit 1; }
cd bcwc_pcie
make || { echo "Error en make del driver. Saliendo."; exit 1; }
sudo make install || { echo "Error en make install del driver. Saliendo."; exit 1; }
cd "$RUTA_TRABAJO" # Volvemos a la ruta raíz de trabajo
echo "Driver bcwc_pcie compilado e instalado."


# --- 6. Cargar el Módulo y Persistencia ---
echo -e "\n[PASO 6/7] Cargando el módulo y configurando para la persistencia..."
sudo depmod
sudo modprobe -r bdc_pci 2> /dev/null # Descarga el driver erróneo si está cargado
sudo modprobe facetimehd
# Configurar para que el módulo se cargue en el inicio
if ! grep -q "facetimehd" /etc/modules; then
    echo "facetimehd" | sudo tee -a /etc/modules > /dev/null
fi
echo "Módulo facetimehd cargado y configurado para el inicio."


# --- 7. Limpieza ---
echo -e "\n[PASO 7/7] Limpiando archivos temporales y probando la cámara..."
rm -rf facetimehd-firmware bcwc_pcie bootcamp_tmp "$BOOTCAMP_ZIP"
echo "Limpieza finalizada."

# Verificar y probar
if [ -e /dev/video0 ]; then
    echo "✅ ¡Éxito! La cámara ha sido detectada como /dev/video0."
    echo "Iniciando mpv para probar la cámara (ciérralo tras la prueba):"
    nohup mpv av://v4l2:/dev/video0 --profile=low-latency --untimed > /dev/null 2>&1 &
else
    echo "❌ La cámara NO fue detectada inmediatamente. DEBES REINICIAR EL SISTEMA AHORA."
fi

echo -e "\n=================================================="
echo "    FIN DEL SCRIPT. ¡POR FAVOR, REINICIA AHORA!   "
echo "=================================================="
