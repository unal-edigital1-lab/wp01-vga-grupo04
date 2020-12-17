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
**Máquina de estados de la barra**
![Maquina de estados barra](https://github.com/unal-edigital1-lab/wp01-vga-grupo04/blob/main/Imagenes/Estados_barra.PNG)
Las señales init, left y right corresponden están asignados a pulsadores de la tarjeta. Por lo que, al oprimir init, el juego empieza a funcionar; al oprimir left la barra actualiza sus posiciones una más a la izquierda y al oprimir right se actualizan las posiciones una más a la derecha, luego de esto, se dibuja la barra en sus nuevas posiciones. 

**Máquina de estados de la bola**
![Maquina de estados bola](https://github.com/unal-edigital1-lab/wp01-vga-grupo04/blob/main/Imagenes/Estados_bola.PNG)
Al oprimir el botón init, la bola se empieza a mover. Este movimiento no es simultáneo en la dirección X y Y, primero se mueve un pixel en dirección vertical y luego uno en dirección horizontal. Los registros dirX y dirY determinan si hay que aumentar o disminuir estas posiciones en cada dirección, para luego, de igual manera, pasar a dibujar la bola en las nuevas posiciones. El registro rebota, determina si la posición en vertical de la bola y la barra es la misma, es decir, si la bola llega a la línea donde debería haber choque con la barra, en caso de que sea así, este verifica que la posición en X (horizontal) de los dos tambien sea la misma. Si no es así, el juego termina y se muestra un punto rojo en el centro que indica que ha perdido.

El botón reiniciar, para los dos casos, dibuja la bola y la barra en sus posiciones iniciales, y vuelve a poner los estados de los dos objetos en START
###### Código del juego 
**Definición de la caja, registros y parámetros**
````
`timescale 1ns / 1ps
module FSM_game #(
		parameter AW = 15,
		parameter DW = 3)(
	 	input clk,
		input rst,
		input in1,
		input in2,
		input in3,
		
		output reg [AW-1: 0] mem_px_addr2,
		output reg [DW-1: 0] mem_px_data2,
		output reg px_wr2,
		
		output reg [AW-1: 0] mem_px_addr,
		output reg [DW-1: 0] mem_px_data,
		output reg px_wr
   );
	//Pantalla de 160x128
	localparam COLOR_BARRA = 3'b010;//verde
	localparam COLOR_BOLA = 3'b111;//blanco
	localparam COLOR_FONDO = 3'b001;//azul
	localparam ROJO = 3'b100;//rojo
	
	localparam tamano_X = 160;
	localparam tamano_Y = 128;
	
	reg [3:0] status = 0;
	reg [3:0] status_bola = 0;
	
	wire init;
	wire right;
	wire left;
	assign right = in1;
	assign left = in2;
	assign init = in3;
	
	//dirección de la pelota
	reg dirX=0;
	reg dirY=0;
	
	reg [7:0] posX_barra;
	reg [7:0] posY_barra=96;
	
	reg [7:0] posX_bola;
	reg [7:0] posY_bola;
	
	//Estados de la barra
	parameter START=0, PLAY=2, MOVL=3, MOVR=4;
	//Estados de la pelota 
	parameter MOVE_V=1, RIGHT=2, LEFT=3, UP=4, DOWN=5, MOVE_H=6, FIN=9;
````
**Movimiento de la barra**
````
	/* *********************************************
		Movimiento de la barra 
	
	**********************************************/
	reg done_barrax=0;
	reg [2:0] count_Tam;
	parameter TAM_X_BARRA =5;
  	reg pallet_draw=0;
	
	
	always @(posedge clk) begin
		if (rst) begin
			count_Tam<=0;
			px_wr<=0;
			posY_barra = 96;
		end

		if(pallet_draw)begin	

			done_barrax=0;
			px_wr <= 1;
			count_Tam<=count_Tam+1;
			case(count_Tam)
				(TAM_X_BARRA+2): begin
						mem_px_addr <= (posX_barra+posY_barra*tamano_X)+(count_Tam-1);
						mem_px_data <= COLOR_FONDO;
	     				done_barrax=1;
			   	   count_Tam<=0;
						pallet_draw=0;
					end	
				(TAM_X_BARRA+1): begin
						mem_px_addr <= (posX_barra-1+posY_barra*tamano_X);
						mem_px_data <= COLOR_FONDO;
					end
				default: begin
						mem_px_addr <= (posX_barra+posY_barra*tamano_X)+count_Tam;
						mem_px_data <= COLOR_BARRA;
				end
			endcase
		end
		
		// Máquina de estados de la barra
		case(status)
		
			START:begin
				posX_barra = 80;
				pallet_draw=1;
				if(init && done_barrax)begin
					pallet_draw=0;
					status<=PLAY;
				end
			end
			PLAY: begin
				if(done_barrax)begin
					pallet_draw=0;
					if(left)begin
						status<=MOVL;
					end
					if(right)begin
						status<=MOVR;
					end
				end
			end
			
			
			MOVL: begin
				if(posX_barra>3)begin
					posX_barra = posX_barra-1;
				end
				pallet_draw=1;
				status<=PLAY;
			end
			
			MOVR: begin
				if(posX_barra<(tamano_X-TAM_X_BARRA-4))begin
					posX_barra = posX_barra+1;
				end
				pallet_draw=1;
				status<=PLAY;
			end
			
		endcase
		
	end
````
**Movimiento de la bola**
 ````
 	/*********************************
	Movimiento de la bola
	
	*******************************/	
	reg [3:0] count_Tam_ball;
	reg done_ball=0;
	reg ball_draw=0;
	reg lost;
	reg red_point_draw;
	reg borrar_punto=0;
	
	always @(posedge clk)begin
		if (rst) begin
			count_Tam_ball<=0;
			px_wr2<=0;
			lost=0;
			red_point_draw=0;
			borrar_punto=1;
		end
		
		if(borrar_punto)begin
			px_wr2<=1;
			mem_px_addr2 <= ((posX_bola)+(posY_bola)*tamano_X);
			mem_px_data2 <= COLOR_FONDO;
			borrar_punto=0;
			status_bola=START;
		end
		
		
		if(ball_draw)begin
			done_ball=0;
			px_wr2<=1;
			count_Tam_ball<=count_Tam_ball+1;
			case(count_Tam_ball)
				1:begin
					mem_px_addr2 <= ((posX_bola-1)+(posY_bola)*tamano_X);
					mem_px_data2 <= COLOR_FONDO;
				end
				2:begin
					mem_px_addr2 <= ((posX_bola)+(posY_bola)*tamano_X);
					mem_px_data2 <= COLOR_BOLA;
				end
				3:begin
					mem_px_addr2 <= ((posX_bola+1)+(posY_bola)*tamano_X);
					mem_px_data2 <= COLOR_FONDO;
				end
				4:begin
					mem_px_addr2 <= ((posX_bola)+(posY_bola-1)*tamano_X);
					mem_px_data2 <= COLOR_FONDO;
				end
				5:begin
					mem_px_addr2 <= ((posX_bola)+(posY_bola+1)*tamano_X);
					mem_px_data2 <= COLOR_FONDO;
					done_ball=1;
					count_Tam_ball<=0;
					ball_draw=0;
				end
			endcase	
		end
		
		if(red_point_draw)begin
			px_wr2 <=1;
			mem_px_addr2 <= 10320;
			mem_px_data2 <= ROJO;
		end
		
		// Máquina de estados de la bola
		case(status_bola) 
		
				START: begin
					posX_bola=80;
					posY_bola=64;
					ball_draw=1;
					if(init && done_ball)begin
						ball_draw=0;
						status_bola=MOVE_V;
					end
				end
				
				MOVE_V: begin
					if(done_ball)begin
						ball_draw=0;
						if(dirY)begin
							status_bola<=DOWN;
						end else begin
							status_bola<=UP;
						end
					end
				end
				
				UP: begin
					if(posY_bola>4)begin
						posY_bola = posY_bola-1;
					end else begin
						dirY=~dirY;
					end
					ball_draw=1;
					status_bola<=MOVE_H;
				end
				
				DOWN: begin
					if(posY_bola<posY_barra-2)begin
						posY_bola = posY_bola+1;
					end else begin
						if((posX_bola>=(posX_barra-1))&&(posX_bola<=(posX_barra+TAM_X_BARRA+1)))begin
							dirY=~dirY;
						end else begin
							lost=1;
						end
					end
					if(lost)begin
						status_bola=FIN;
					end else begin
						ball_draw=1;
						status_bola<=MOVE_H;
					end
					
				end
				
				MOVE_H: begin
					if(done_ball)begin
						ball_draw=0;
						if(dirX)begin
							status_bola<=RIGHT;
						end else begin
							status_bola<=LEFT;
						end
					end
				end
				
				RIGHT:begin
					if(posX_bola<tamano_X-3)begin
						posX_bola=posX_bola+1;
					end else begin
						dirX=~dirX;
					end
					ball_draw=1;
					status_bola<=MOVE_V;
				end
				
				LEFT:begin
					if(posX_bola>4)begin
						posX_bola=posX_bola-1;
					end else begin
						dirX=~dirX;
					end
					ball_draw=1;
					status_bola<=MOVE_V;
				end	
				
				FIN:begin
					red_point_draw=1;
				end
		endcase	
	end
endmodule
 ````

## Resultados

 
