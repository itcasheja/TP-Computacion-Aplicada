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
| `var.tar.gz.part_00`, `var.tar.gz.part_01` | /var (dividido en partes) |

Para reconstruir /var:
```
cat var.tar.gz.part_* > var.tar.gz
```
