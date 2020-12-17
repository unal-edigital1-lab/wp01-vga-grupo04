# WP01
# Proyecto - Diseño de un videojuego con implementación en VGA 
Nombres:
* Sergio Armando Romero Quevedo
* Diego Fabian Osorio Fonseca
## Planteamiento del juego 

Para la realización de este proyecto se plantea desarrollar un videojuego Ping Pong primitivo, esto es: una única persona juega a mover una barra horizontalmente, de tal manera que la pelota que va rebotando por los lados de la pantalla no caiga.

## Desarrollo

Consideraciones:
* Para empezar, debido a las limitaciones de la tarjeta, la cual solo tiene 414 Kb de memoria y sabiendo por el plantemaiento del problema que solo podemos usar hasta el 50% de esta, se plantea el siguiente uso de memoria:
Tamaño de juego de 160x128 usando un bit de cada color por pixel 
Memoria total = (160x128x3)/1024= 60 kbits.
* La pantalla que se va a utulizar tiene una configuración de 1280x1024 y se debe usar una frecuencia de 108 MHz, por lo que hay que implementar un multiplicador de frecuencias debido a que el clk de la tarjeta es de 50 MHz. Lo anterior también hace necesario cambiar algunos parámetros en el driver del VGA, ya que estaba pensado para una pantalla de 640x480.
* Debido a que el cuadrado en el que se va a generar en el juego es muy pequeño a comparación del tamaño de la pantalla, se propone realizar una ampliación del cuadrado.
* Como se va a realizar el movimiento simultáneo de una bola y una barra en la pantala, se plantea modificar el archivo del buffer para poder ingresar dos direcciones y datos para escribir simultáneamente.

###### Driagrama de cajas
Dado las anteriores consideraciones, se plantea el siguiente diagrama de cajas:
![Imagen](https://github.com/unal-edigital1-lab/wp01-vga-grupo04/blob/main/Imagenes/Diagrama_cajas.PNG)




## Juego
 

###### Máquinas de estados 

###### Código del juego 


## Resultados
 
 
