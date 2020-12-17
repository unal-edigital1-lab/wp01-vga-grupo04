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

El cual es muy similar al dado en el planteamiento del problema, pero con las siguientes modificaciones principales en el código:
* Para hacer la ampliación de la pantalla por 8 veces la caja de Conv_addr se modifica de la siguiente manera:
````
reg [10:0] tempx;
reg [10:0] tempy;

always @ (VGA_posX, VGA_posY) begin
		tempx = VGA_posX/8;
		tempy = VGA_posY/8;	
		DP_RAM_addr_out=tempx+tempy*CAM_SCREEN_X;	
end
````
* Para poder recibir dos direcciones y datos distintos para escribir en la memoria, el buffer_ram_dp se modifica de la siguiente manera:
````
always @(posedge clk_w) begin 
		 mux=~mux;
		 if(mux)begin
			if (regwrite == 1) begin
             ram[addr_in] <= data_in;
			end
		 end else begin
			if (regwrite2 == 1) begin
				 ram[addr_in2] <=data_in2;
			end
		 end	 
end
````
con lo cual, se va alternando la dirección y dato que escribe.

## Juego
Para hacer el desarrollo del juego, se van a plantear dos procesos diferentes, uno correspondiente al movimiento de la barra y otro al movimiento de la pelota, cada uno haciendo uso de un campo para escribir en la memoria. Así, se plantean las siguientes máquinas de estados

###### Máquinas de estados 

###### Código del juego 


## Resultados

 
