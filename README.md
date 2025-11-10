Lo que tendría que hacer es:

Por ahora, creo una carpeta "Wollen Labs Data Engineer Challenge" donde está "scrapping", "jobs" y "transformation",

- Ya tengo andando el container (**wollenlabsdataengineerchallenge-postgres-1**) ofical de postgres para **crar la DB local PostgreSQL**.

![image.png](attachment:11356430-9856-4900-a5ac-330529a2ca01:image.png)

Por ahora, cree un Docker-Compose con el contenedor postgre y me conecte a èl con Outerbase Studio para administrarlo

- En docker creo un contenedor oficial de Airflow (2) donde le meto mi codigo que roba la tabla de la wiki y le instalo todo lo necesario(**Pandas, Poetry, request,**dbt, SQLAlchemy para Airflow  **etc**) y que el dag de airflow ejecute ese codigio y dentro del dag escribir el codigo que ejecute la carga de los datos crudos a mi DB local de PostgreSQL inicial de los datos crudos a tu DB de PostgreSQL y posteriormente la transformacion con DBT (Ver qué podría hacerle, cambiar los nombres, y comprobaciones basicas boludas).

(en el “Cómo Ejecutar Localmente” del Readme voy a tener que explicar cómo crear un .env.example: ) 

```jsx
POSTGRES_USER=”POSTGRES_USER”
POSTGRES_PASSWORD=”POSTGRES_PASSWORD”
AIRFLOW_SECRET_KEY= “AIRFLOW_SECRET_KEY”
AIRFLOW_USER=”AIRFLOW_USER”
AIRFLOW_PASSWORD=”AIRFLOW_PASSWORD”
```

Iba a usar pgadmin pero me está dando mil problemas, mejor Outerbase Studio

Saqué la adaptación de pip a poetry en el dockerfile de esta pagina https://stackoverflow.com/questions/53835198/integrating-python-poetry-with-docker?utm_source=chatgpt.com 

Tambien tengo que hacer un dockerfile donde defino la version de airflow, python y las dependencias necesarias para el proyecto, además del user airflow.

TRANFORMACION:
Considere que había que sacar de la tabla el 2026 ya que afectaría a las metricas al ser valores NULL
-En transformacion pasé todo a minuscula y con _
-considero que Ref. propio de wikipedia era innecesario
-Dividir score en GOALS_WINNER y GOALS_RUNNER_UP e info extra del partido
-Dividir "location" ej: "Montevideo, Uruguay" a host_city:Montevideo y host_country: Uruguay

![image.png](attachment:361e7b22-5d7b-4ad7-bb24-3552576a49a8:image.png)

En lugar de pip, utilizaré poetry, al ser mas completo y darle los requerimientos

![image.png](attachment:60e73dc2-8dd8-4d49-9326-aaa5a101cd7d:image.png)

Diez mil errores, razón? no me toma los datos del .env, así que a especificar en todos los servicios.

![image.png](attachment:9710641b-019f-4092-ab26-a0f0d8a74c83:image.png)

Poetry supusetamente ya debería estar bien (el avast me lo había borrado 🙂)

tengo como 100 mensajes de error de que `FATAL: database "admin" does not exist` 

![image.png](attachment:8a5370c2-c372-411e-9d14-a27cb1dc5f26:image.png)

Funciona!

![image.png](attachment:10da9e8d-f6eb-4d56-b37e-25439f093404:image.png)

Errores en este caso por usar intentar iniciar el proyeco dbt usando python 1.14 cuando debí haber usado algo como 1.11 o 1.13.

![image.png](attachment:819b65b2-f072-4125-b26f-a372cbff9c85:image.png)

https://docs.getdbt.com/faqs/Core/install-python-compatibility

Me siguió dando error el dbt, así que voy a usar python 3.10.

![image.png](attachment:58ea1e6d-e25d-4090-b3c6-f1b009c19087:image.png)

Para qué init.sql? para guardar logs y demás info de airflow por las dudas.

- En el código robo la tabla de wiki (✅)
- Cargarlo en mi DataWarehouse o base de datos local (Esto será jodido) (Por ahora es un pandas DataFrame voy de manera local instalar **psycopg2** para mandar el df a la db del container postgres)
- No sé en qué etapa vendría esta parte: (- Tiene que ser "indempondent" y "reproducibility": " si ejecutas 2 veces el mismo job no sobre escribas datos ya existentes, preferiblemente no proceses datos innecesarios y no termines con duplicados": Para lo cual usaré

Aunque me suena mas a DeltaLoad

**Full Refresh (Truncate and Load)**, porque:

Cumple con **Idempotencia** al borrar (TRUNCATE) y volver a cargar (INSERT) todos los datos en cada ejecución, garantizando que la tabla final siempre reflejará la exacta tabla de Wikipedia, sin riesgo de duplicados o datos obsoletos por ejecuciones fallidas o similar.

**La tabla es pequeña**, no le veo sentido a complejizarlo con *Delta Load* (es decir, comprobar qué filas son nuevas, cuáles cambiaron, etc). Además La tabla **solo cambia una vez cada cuatro años**, cuando se añade una nueva fila. No hay actualizaciones intermedias de filas existentes).

Hacer la **Transformacion** con la DB usando DBT [dbt-postgres] (porque está diseñado específicamente para la **transformacion de datos** elegí DBT por sobre SQLAlchemy ya que este ultimo es más general) y voy a usar PostgreSQL.

- Que la tabla final para su análisis sea: year, host, finalists,

and result y los que sienta que tambien son importantes. (Con pandas y DBT).

- Llamarlo fifa_world_cup_finals

- Un reporte ligerito (notebook/SQL or a minimal dashboard)) con algunos ejemplos de consultas en el modelo analítico (hecho con los datos obtenidos del codigo final pandas).
- Preparar un repositorio (por ahora oculto) donde el README explique todo (por ahora nada porque no hice nada), poner esquema ya sea una estructura de estrella o copo de nieve."# fifa_world_cup_pipeline" 
