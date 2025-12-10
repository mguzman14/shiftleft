# Docker image y CI/CD con Quay

## Objetivos

- Crear una imagen con un Dockerfile

- Crear un pipeline de CI/CD para que suba la imagen a quay.io sólo si es cibersegura.

- Corregir un error de SBOM para que pasen todos los tests

## Explicación

En el repo hay 2 carpetas:
- `/.github/workflows`: donde están los workflows de CI/CD de Github.
- `/docker`: donde están los archivos Docker.

El archivo `Dockerbasic` que se usa para construir la imagen no tiene vulns. Sin embargo, al añadir un escaneo con SBOM, este nos reporta una vulnerabilidad. Esto es porque se está usando el tag `:latest`, el cual no garantiza una estabilidad. Para ello, hemos buscado un `tag` más estable y se lo hemos indicado en la imagen que usa para escanear. De esta manera, ya pasan los tests.




--




La imagen `Dockerfile` se ha creado siguiendo las instrucciones de las diapos 63 y 64 del pwp (_Crear imatges amb Dockerfile - Layering d’imatges_).

Los archivos de Github Actions se han hecho utilizando de referencia el repo https://github.com/Josep-Andreu/segur_cloud/blob/main/build-and-push.yaml y siguiendo las instrucciones de las diapos a continuación de la 64. 

Se han hecho 2 workflows de Github Actions:

1. `build_and_push.yml`: se ejecuta cada vez que se hace un commit en la branch `main`. Si encuentra vulns que son High o Critical, no sube la imagen a Quay.io. Para ello, se ha utilizado el archivo del repo original, únicamente cambiando el registro de la imagen y el tag. 

2. `build_fix_push.yml` (extra): se ejecuta manualmente. Hace lo mismo que el anterior pero, si el scan de Grype detecta vulns High o Critical, las corrige, genera una imagen fixeada y la sube y firma a Quay.io. Para ello, se han adaptado los job _scan_ y _push_ y se ha añadido el job _remediate_. A continuación, se explica el cómo con más detalle:

En el job **scan**, después de hacer el scan con Grype, se hace lo siguiente: 
    
- Coge el output de Grype y se queda con las vulnerabilidades High y Critical
    
- Para cada uno de los registros, crea la sintaxis para hacer "yum update nombre-paquete fixed-version" de cada vulnerabilidad

- Esta sintaxis la guarda en un archivo `*.sh`  como un artifact (temporal) para usarlo a continuación.

A continuación, empieza el job **remediate**:

- Se descarga el archivo remediation.sh (que está como artifact) 

- Crea la imagen otra vez, pero importando dentro suyo el archivo `remediation.sh`
   
- Cuando se está creando la imagen, se ejecuta el archivo `remediation.sh`, que contiene las instrucciones de `yum update nombre-paquete fixed-version`. Ello resulta en que los paquetes que se instalan son de las versiones fixeadas.

Finalmente, como parte del job `push-and sign`, se determina cuál es la imagen que hay que subir a Quay.io (la normal o la fixeada) (a nivel de código, se puede mejorar). 

Cuando lo determina, continúa el proceso como lo hace para el `build_and_push.yml`.

    




