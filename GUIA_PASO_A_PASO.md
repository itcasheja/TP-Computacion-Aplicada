# TP Integrador – Computación Aplicada – Guía paso a paso

Todos los comandos se ejecutan como **root** dentro de la máquina virtual (Debian).
Los archivos de configuración ya armados están en la carpeta `config/` y el script en `scripts/`.

Datos de red usados (red de la máquina física):
- IP de la VM: **192.168.0.200** (libre en la red)
- Máscara: **255.255.255.0**
- Gateway: **192.168.0.1**

---

## 1) Configuración del entorno

### 1.1 Armar la máquina virtual (YA HECHO)
- Las partes `.rar` tenían "(1)" en el nombre y por eso daba error. Se renombraron a `TPVMCA.part01.rar` ... `part09.rar` y se extrajo `TPVMCA.ova`.
- Se importó en VirtualBox (Archivo → Importar servicio virtualizado).
- Se cambió el adaptador puente de `wlp3s0` (placa del profe) a la placa WiFi de la PC.

### 1.2 Blanquear la clave de root y cambiarla a "palermo"
1. Reiniciar la VM y, mientras arranca, apretar flecha ↑ para que aparezca el menú de GRUB.
2. Con "Debian GNU/Linux" seleccionado, apretar **e**.
3. Bajar hasta la línea que empieza con `linux /boot/vmlinuz...`, apretar **Fin** y agregar al final:
   ```
    rw init=/bin/bash
   ```
4. Apretar **Ctrl+X** para arrancar. Aparece una consola de root sin pedir clave.
5. Cambiar la clave:
   ```
   passwd
   ```
   (escribir `palermo` dos veces)
6. Seguir con el arranque normal:
   ```
   exec /sbin/init
   ```
**Para la defensa:** `init=/bin/bash` le dice al kernel que en vez de arrancar el sistema normal (systemd) abra directamente una consola bash como root, sin login. `rw` monta el disco con escritura para poder guardar la nueva clave en `/etc/shadow`.

### 1.3 Hostname TPServer
```
hostnamectl set-hostname TPServer
nano /etc/hosts        # cambiar "debian" por "TPServer" en la línea 127.0.1.1
```
Verificar: `hostname`

---

## 2) Servicios

### 2.1 Actualizar a Debian 12 (bookworm)
```
apt update && apt full-upgrade -y                 # dejar Debian 11 al día
sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list
apt update
apt upgrade --without-new-pkgs -y
apt full-upgrade -y
reboot
```
Verificar: `cat /etc/debian_version` (tiene que decir 12.x)

**Para la defensa:** se cambian los repositorios de `bullseye` (Debian 11) a `bookworm` (Debian 12) en `sources.list` y se actualiza todo el sistema.

### 2.2 SSH con clave pública/privada para root
```
apt install -y openssh-server
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""       # par de claves en el Home de root
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys
nano /etc/ssh/sshd_config
```
En `sshd_config` dejar:
```
PermitRootLogin prohibit-password
PubkeyAuthentication yes
```
```
systemctl restart ssh
systemctl enable ssh
```
Probar desde la PC (Windows, PowerShell), copiando antes la clave privada `/root/.ssh/id_rsa`:
```
ssh -i id_rsa root@192.168.0.200
```
**Para la defensa:** `prohibit-password` permite que root entre solo con clave pública/privada, no con contraseña.

### 2.3 Apache + PHP
```
apt install -y apache2 php libapache2-mod-php php-mysql
php -v                       # en Debian 12 instala PHP 8.2 (cumple ">= 7.3")
systemctl enable --now apache2
```
(La configuración para servir `index.php` y `logo.png` desde `/www_dir` está en el punto 4.3.)

### 2.4 MariaDB y carga de db.sql
```
apt install -y mariadb-server
systemctl enable --now mariadb
mysql -u root < /root/db.sql
mysql -u root -e "SHOW DATABASES;"
```
Si `db.sql` no crea la base, primero crearla: `mysql -u root -e "CREATE DATABASE nombre;"` y después `mysql -u root nombre < /root/db.sql`.

Prueba desde la PC física: abrir en el navegador `http://192.168.0.200`

---

## 3) Configuración de red (IP estática)
Ver el nombre de la interfaz con `ip a` (en VirtualBox suele ser `enp0s3`).
Reemplazar `/etc/network/interfaces` con el contenido de `config/interfaces`:
```
allow-hotplug enp0s3
iface enp0s3 inet static
    address 192.168.0.200
    netmask 255.255.255.0
    gateway 192.168.0.1
```
```
systemctl restart networking
ip a
ping -c 3 192.168.0.1
```
**Para la defensa:** la IP está en el mismo rango que la PC física (192.168.0.x/24), por eso la VM usa adaptador "puente" y se puede acceder desde la PC.

---

## 4) Almacenamiento

### 4.1 Agregar disco de 10 GB (con la VM apagada, desde Windows)
VirtualBox → seleccionar TPVMCA → Configuración → Almacenamiento → Controlador SATA → "Agregar disco duro" → Crear → VDI → 10 GB.

Dentro de la VM el disco nuevo aparece como `/dev/sdc` (verificar con `lsblk`, es el de 10 GB sin particiones).

### 4.2 Dos particiones tipo 83 (3 GB y 6 GB)
```
fdisk /dev/sdc
  n  p  1  (Enter)  +3G       -> partición 1 de 3 GB
  n  p  2  (Enter)  +6G       -> partición 2 de 6 GB
  p                           -> verificar que las dos son tipo 83 "Linux"
  w                           -> guardar
mkfs.ext4 /dev/sdc1
mkfs.ext4 /dev/sdc2
mkdir /www_dir /backup_dir
cat /proc/partitions > /opt/particion          # nota del enunciado
```

### 4.3 /www_dir con index.php y logo.png + Apache apuntando ahí
```
mount /dev/sdc1 /www_dir
cp /root/index.php /root/logo.png /www_dir/
chown -R www-data:www-data /www_dir
```
- Reemplazar `/etc/apache2/sites-available/000-default.conf` con `config/000-default.conf` (`DocumentRoot /www_dir`).
- Agregar en `/etc/apache2/apache2.conf` el bloque de `config/apache2.conf_agregar.txt`.
```
apache2ctl configtest
systemctl restart apache2
```

### 4.4 y 4.5 Montaje automático (/etc/fstab)
```
blkid /dev/sdc1 /dev/sdc2        # copiar los UUID
nano /etc/fstab                  # agregar las líneas de config/fstab_agregar.txt con los UUID reales
mount -a
df -h                            # deben aparecer /www_dir y /backup_dir
```
**Para la defensa:** `/etc/fstab` lista qué particiones se montan al iniciar. Se usa UUID porque el nombre `/dev/sdX` puede cambiar.

---

## 5) Backup
```
mkdir -p /opt/scripts
# copiar scripts/backup_full.sh a /opt/scripts/backup_full.sh
chmod +x /opt/scripts/backup_full.sh
/opt/scripts/backup_full.sh -help
/opt/scripts/backup_full.sh /var/log /backup_dir      # genera log_bkp_YYYYMMDD.tar.gz
ls -lh /backup_dir
```
Qué hace el script:
- `-help` muestra la ayuda.
- Recibe **origen** y **destino** como argumentos.
- Valida que el origen exista y su sistema de archivos esté montado (`findmnt`), y que el destino exista, se pueda escribir y sea un punto de montaje (`mountpoint`).
- Genera `<nombre>_bkp_<YYYYMMDD>.tar.gz` con `date +%Y%m%d`.

Programación con cron (`crontab -e`, contenido en `config/crontab_root.txt`):
```
0 0 * * *      /opt/scripts/backup_full.sh /var/log /backup_dir
0 23 * * 1,3,5 /opt/scripts/backup_full.sh /www_dir /backup_dir
```
Nota: el enunciado dice "/var/logs" pero en Debian el directorio real es **/var/log** (y el propio ejemplo del enunciado usa /var/log).

**Para la defensa:** los 5 campos de cron son minuto, hora, día del mes, mes y día de la semana (1=lunes, 3=miércoles, 5=viernes).

---

## 6) Entregables (GitHub)
Dentro de la VM, generar los comprimidos:
```
mkdir /root/entrega && cd /root/entrega
tar -czf root.tar.gz --exclude=/root/entrega /root
tar -czf etc.tar.gz /etc
tar -czf opt.tar.gz /opt
tar -czf www_dir.tar.gz /www_dir
tar -czf backup_dir.tar.gz /backup_dir
tar -czf - /var | split -b 20M - var.tar.gz.part_     # /var en partes de 20 MB
```
Para volver a unir /var: `cat var.tar.gz.part_* > var.tar.gz`

Subir todo al repositorio de GitHub junto con el `README.md` (con los nombres del grupo).
