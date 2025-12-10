# Docker image y CI/CD con Quay

## Objetivos

- Crear una imagen con un Dockerfile

- Crear un pipeline de CI/CD para que suba la imagen a quay.io sólo si es cibersegura.

- Corregir un error de SBOM para que pasen todos los tests

## Contenido

En el repo hay 2 carpetas:
- `/.github/workflows`: donde están los workflows de CI/CD de Github.
- `/docker`: donde están los archivos Docker.


## Explicación: por qué falla el scan con SBOM
El archivo `Dockerbasic` que se usa para construir la imagen no tiene vulns. Sin embargo, al añadir un escaneo con SBOM, este nos reporta una vulnerabilidad. Esto es porque se está usando el tag `:latest`, el cual no garantiza una estabilidad. Para ello, hemos buscado un `tag` más estable y se lo hemos indicado en la imagen que usa para escanear. De esta manera, ya pasan los tests.

## EXTRAS

### CI/CD Workflow
Para hacer más modular el repositorio y el uso del CI/CD, se ha planteado utilizar _**workflow calls**_. Esto es una manera de ejecutar workflows de Github Actions de forma dinámica, pasándole unos parámetros de entrada según el archivo que se haya modificado. Para este ejercicio entregable no era necesario, pues con un _workflow_ que se ejecute en cada `push` del repo es más que suficiente. Sin embargo, me ha parecido interesante explorar esto porque lo he encontrado útil cuando he querido ejecutar un mismo _workflow_ para 2 imagenes diferentes y generar 2 resultados diferentes. Así, he evitando crear otro repo a parte y he podido tener varios `Dockerfile` con nombres adaptados a lo que necesito.

### `build_and_push.yml`
En un _workflow_ habitual, se dispone de un archivo `.yml` immutable: se ejecuta siempre lo mismo. Sin embargo, con la aproximación del _workflow calls_, se ejecuta el workflow principal pasándole unos parámetros de entrada a través de otro archivo.yml. En mi caso, tengo varios `Dockerfile`:
- `Dockerfile_jboss_lab`: quiero construir la imagen, pasarle un scan y subirla a quay.io al repo `quay.io/mguzman98/jboss_lab`.
- `Dockerfilebasic`: una imagen muy sencilla que también quiero pasarle un scan y subirla a quay.io (quay.io/mguzman98/shiftleft_lab) 

Como ves, el proceso es idéntico y lo único que cambia es el registro de la imagen y el nombre del `Dockerfile` que la construye. Con lo cual, he creado 2 archivos:
- `build-Dockerfile_jboss` 
- `build-Dockerfilebasic`

La única función que tienen es contener el nombre de su `Dockerfile` asociado y el nombre del _workflow principal_ que tienen que ejecutar. 

Con los eventos añadidos y alguna que otra modificación, cuando se hace alguna modificación en alguno de los Dockerfile, se ejecuta el `build-Dockerfile` correspondiente que, a su vez, ejecutará el `build_and_push.yml` con los parámetros que le de el `build-Dockerfile`.

### `build_fix_push.yml`

De acuerdo con la dinámica del _workflow_ de Github Actions, si la imagen tiene vulnerabilidades catalogadas como _High_ o _Critical_, la imagen no se sube a quay.io y el _workflow_ falla. Con lo cual, hay que mirar qué vulns tiene, corregirlas y volverla a subir. 

Para automatizar un poco esto, se ha creado un segundo _workflow_ en el cual, si el scan de Grype detecta vulns High o Critical, las corrige, genera una imagen fixeada y es esta imagen la que se sube y firma a Quay.io. Para ello, se han adaptado los job _scan_ y _push_ y se ha añadido el job _remediate_. A continuación, se explica el cómo con más detalle:

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

    

## Referencias

Los archivos de Github Actions se han hecho utilizando de referencia el repo https://github.com/Josep-Andreu/segur_cloud/blob/main/build-and-push.yaml  


