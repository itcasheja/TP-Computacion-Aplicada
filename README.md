# TP Integrador Grupal – Computación Aplicada

Universidad de Palermo – Ciberseguridad

## Integrantes
- COMPLETAR NOMBRE 1
- COMPLETAR NOMBRE 2
- COMPLETAR NOMBRE 3
- COMPLETAR NOMBRE 4
- COMPLETAR NOMBRE 5

## Entregables (carpeta `entregables/`)
| Archivo | Contenido |
|---|---|
| `root.tar.gz` | Directorio /root (index.php, logo.png, db.sql, par de claves SSH) |
| `etc.tar.gz` | Directorio /etc (configuración de red, SSH, Apache, fstab, hostname) |
| `opt.tar.gz` | Directorio /opt (`/opt/scripts/backup_full.sh` y `/opt/particion`) |
| `www_dir.tar.gz` | Directorio /www_dir (index.php y logo.png servidos por Apache) |
| `backup_dir.tar.gz` | Directorio /backup_dir (backups generados por el script) |
| `var.tar.gz.part_00`, `var.tar.gz.part_01` | Directorio /var dividido en partes de 20 MB |
| `SHA256SUMS` | Hash de cada archivo para verificar integridad |

Para reconstruir /var:
```
cat var.tar.gz.part_* > var.tar.gz
tar -xzf var.tar.gz
```

## Resumen de lo realizado

### 1) Configuración del entorno
- VM ensamblada desde las 9 partes `.rar` e importada en VirtualBox (`TPVMCA.ova`).
- Clave de root blanqueada desde GRUB (`rw init=/bin/bash` + `passwd`) y cambiada a `palermo`.
- Hostname: **TPServer** (`hostnamectl set-hostname TPServer` + `/etc/hosts`).

### 2) Servicios
- **SO**: actualizado de Debian 11 (bullseye) a **Debian 12.15 (bookworm)**, kernel 6.1.
- **SSH**: `openssh-server`; root accede solo con clave pública/privada (`PermitRootLogin prohibit-password`). La clave pública `/root/clave_publica.pub` está en `/root/.ssh/authorized_keys`; la privada es `/root/clave_privada.txt`.
- **Web**: Apache 2.4 + PHP 8.2 (`libapache2-mod-php`, `php-mysql`), sirviendo `index.php` y `logo.png`.
- **Base de datos**: MariaDB con `db.sql` cargado (base `ingenieria`, usuario `lcars`).

### 3) Red
`/etc/network/interfaces` con IP estática en la red de la máquina física:
```
auto enp0s3
iface enp0s3 inet static
	address 192.168.0.200
	netmask 255.255.255.0
	gateway 192.168.0.1
```
Probado desde la máquina física: `http://192.168.0.200` muestra la tabla de alumnos y notas.

### 4) Almacenamiento
- Disco nuevo de 10 GB (`/dev/sdc`) con 2 particiones tipo 83:
  - `/dev/sdc1` 3 GB → `/www_dir`
  - `/dev/sdc2` 6 GB → `/backup_dir`
- Montaje automático por UUID en `/etc/fstab`.
- Apache apunta a `/www_dir` (`000-default.conf` con `DocumentRoot /www_dir` y bloque `<Directory /www_dir/>` en `apache2.conf`).
- `cat /proc/partitions > /opt/particion`.

### 5) Backup
- Script `/opt/scripts/backup_full.sh <origen> <destino>` con opción `-help`.
- Valida que el origen exista y su sistema de archivos esté montado, y que el destino sea un punto de montaje con permiso de escritura.
- Genera `<nombre>_bkp_<YYYYMMDD>.tar.gz` (ej: `log_bkp_20261109.tar.gz`).
- Cron de root:
```
0 0 * * *      /opt/scripts/backup_full.sh /var/log /backup_dir
0 23 * * 1,3,5 /opt/scripts/backup_full.sh /www_dir /backup_dir
```
(El enunciado dice "/var/logs"; en Debian el directorio es `/var/log`.)

La guía completa con todos los comandos está en `GUIA_PASO_A_PASO.md`.
