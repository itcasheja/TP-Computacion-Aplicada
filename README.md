# TP Integrador Grupal – Computación Aplicada

## Integrantes
- Danuvio Heredia
- Mia Fernandez
- Valentina Alvarez

## Contenido
| Archivo | Directorio |
|---|---|
| `root.tar.gz` | /root |
| `etc.tar.gz` | /etc |
| `opt.tar.gz` | /opt |
| `www_dir.tar.gz` | /www_dir |
| `backup_dir.tar.gz` | /backup_dir |
| `var.tar.gz.part_00` a `var.tar.gz.part_03` | /var (dividido en partes) |

El documento `TP_Computacion_Aplicada_Material_de_Estudio.pdf` desarrolla cada punto de la consigna: conceptos, comandos, archivos de configuración y verificación.

Para reconstruir /var:
```
cat var.tar.gz.part_* > var.tar.gz
```
