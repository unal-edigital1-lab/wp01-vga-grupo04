`timescale 1ns / 1ps

module FSM_game #(
		parameter AW = 15,
		parameter DW = 3)(
	 	input clk,
		input rst,
		input in1,
		input in2,
		input in3, //No se ha asignado en los otros archivos
		output reg [AW-1: 0] mem_px_addr,
		output reg [DW-1: 0] mem_px_data,
		output reg px_wr
   );
	//Pantalla de 128x96
	
	localparam COLOR_BARRA = 3'b010;//verde
	localparam COLOR_BOLA = 3'b111;//blanco
	localparam COLOR_FONDO = 3'b001;//azul
	localparam COLOR_LOST = 3'b100;//rojo
	
	parameter tamano_X = 128;
	parameter tamano_Y = 96;
	
	reg [3:0] status=0;
	reg [3:0] status_bola=0;
	
	wire init;
	wire right;
	wire left;
	wire reset;
	assign right = in1;
	assign left = in2;
	assign init = in3;
	assign reset = rst;
	
	//variables control barra
	reg pos_ini;
	reg movr;
	reg movl;
	reg borrar_linea;
	
	//variables control bola
	reg cambY;
	reg movY;
	reg cambX;
	reg movX;
	reg lost;
	
	//dirección de la pelota
	reg dirX=0;
	reg dirY=0;
	
	
	//8 bits para la posicion vertical y 9 para la horizonal
	
	reg [7:0] posX_barra;
	reg [6:0] posY_barra;
	
	reg [7:0] posX_bola;
	reg [6:0] posY_bola;
	
	reg [7:0] i;
	
	//Estados de la barra
	parameter START=0, CHKL=1, CHKR=2, MOVL=3, MOVR=4;
	//Estados de la pelota 
	parameter CHKSUPINF=1, CHKINF=2, CHKCHOQUE=3, CHKX=4, CAMBY=5, MOVY=6, CAMBX=7, MOVX=8, FIN=9;
	
	

	always @(posedge clk)begin
	
		//Ir a posiciones iniciales
		if(pos_ini)begin
			posX_barra = 64;
			posY_barra = 80;
			
			posX_bola = 64;
			posY_bola = 48;
			
			//Poner posiciones en memoria
			
			mem_px_addr = posX_barra+(posY_barra-1)*tamano_X;
			mem_px_data = COLOR_BARRA;
			
			px_wr = 1;
			#1 px_wr = 0;
			mem_px_addr = mem_px_addr+1;
			px_wr = 1;
			#1 px_wr = 0;
			mem_px_addr = mem_px_addr-2;
			px_wr = 1;
			#1 px_wr = 0;
			
			mem_px_addr = posX_bola+(posY_bola-1)*tamano_X;
			mem_px_data = COLOR_BOLA;
			px_wr = 1;
			#1 px_wr = 0;			
		end
		
		
		//	Mover a la izquierda barra
		if(movl)begin
			if(!((posX_barra-1)==1))begin
			
				posX_barra = posX_barra-1;
				mem_px_addr = posX_barra+(posY_barra-1)*tamano_X;
				mem_px_data = COLOR_BARRA;
				px_wr = 1;
				#1 px_wr = 0;
				mem_px_addr = mem_px_addr+1;
				px_wr = 1;
				#1 px_wr = 0;
				mem_px_addr = mem_px_addr-2;
				px_wr = 1;
				#1 px_wr = 0;
			end
			
		end
		//	Mover a la derecha barra
		if(movr)begin
			if(!((posX_barra+1)==tamano_X))begin
			
				posX_barra = posX_barra+1;
				
				mem_px_addr = posX_barra+(posY_barra-1)*tamano_X;
				mem_px_data = COLOR_BARRA;
				px_wr = 1;
				#1 px_wr = 0;
				mem_px_addr = mem_px_addr+1;
				px_wr = 1;
				#1 px_wr = 0;
				mem_px_addr = mem_px_addr-2;
				px_wr = 1;
				#1 px_wr = 0;
			end

		end
		
		//Borrar la linea inferior donde se ubica la barra, para actualizar su posición
		if(borrar_linea)begin
			for(i=0;i<tamano_X;i=i+1)begin
				mem_px_addr = ((posY_barra-1)*tamano_X)+i;
				mem_px_data = COLOR_FONDO;
				px_wr = 1;
				#1 px_wr = 0;
			end
		end


		//Cambiar dirección de la pelota en Y
		if(cambY)begin
			dirY = ~dirY;
		end
		
		//Cambiar dirección de la pelota en X
		if(cambX)begin
			dirX = ~dirX;
		end
		
		//Mover la pelota en Y	
		if(movY)begin
			if(dirY)begin
				posY_bola=posY_bola+1;
			end else begin
				posY_bola=posY_bola-1;
			end
			
			//pos bola
			mem_px_addr = posX_bola+(posY_bola-1)*tamano_X;
			mem_px_data = COLOR_BOLA;
			px_wr = 1;
			#1 px_wr = 0;
			//borrar posicion encima de la bola
			mem_px_addr = posX_bola+((posY_bola-1)-1)*tamano_X;
			mem_px_data = COLOR_FONDO;
			px_wr = 1;
			#1 px_wr = 0;
			//borrar posicion debajo de la bola
			mem_px_addr = posX_bola+((posY_bola+1)-1)*tamano_X;
			mem_px_data = COLOR_FONDO;
			px_wr = 1;
			#1 px_wr = 0;
		end
		
		//Mover la pelota en X
		if(movX)begin
			if(dirX) begin
				posY_bola=posX_bola+1;
			end else begin
				posX_bola=posX_bola-1;
			end
				
			//pos bola
			mem_px_addr = posX_bola+(posY_bola-1)*tamano_X;
			mem_px_data = COLOR_BOLA;
			px_wr = 1;
			#1 px_wr = 0;
			//borrar posición a la derecha de la bola
			mem_px_addr = (posX_bola+1)+(posY_bola-1)*tamano_X;
			mem_px_data = COLOR_FONDO;
			px_wr = 1;
			#1 px_wr = 0;
			//borrar posición a la izquierda de la bola
			mem_px_addr = (posX_bola-1)+(posY_bola-1)*tamano_X;
			mem_px_data = COLOR_FONDO;
			px_wr = 1;
			#1 px_wr = 0;
		end
		
		//Acabar juego
		if(lost) begin //se hace un punto rojo en la mitad de la pantalla
			mem_px_addr = 64+(48-1)*tamano_X;
			mem_px_data = COLOR_LOST;
			px_wr = 1;
			#1 px_wr = 0;
		end
		
		//Resetear el juego
		if(reset)begin
			lost=0;
			status=START;
			status_bola=START;
		end
		
		
		
		
		//Maquina de estados de la barra
		case(status)
		
			START:begin
				pos_ini=1;
				movl=0;
				movr=0;
				if(init)begin
					status=CHKL;
				end
			end
			
			CHKL: begin
				if(left)begin
					status=MOVL;
				end else begin
					status=CHKR;
				end
			end
			
			CHKR: begin
				if(right)begin
					status=MOVR;
				end else begin
					status=CHKL;
				end
			end
			
			MOVL: begin
				borrar_linea =1;
				#130 borrar_linea =0;
				pos_ini=0;
				movl=1;
				movr=0;
				status=CHKR;
			end
			
			MOVR: begin
				borrar_linea =1;
				#130 borrar_linea =0;
				pos_ini=0;
				movl=0;
				movr=1;
				status=CHKL;
			end
			
		endcase
		
		
		
		//Maquina de estados de la bola
		case(status_bola)
			START:begin
				cambY=0;
				movY=0;
				cambX=0;
				movX=0;
				lost=0;
				if(init)
					status_bola=CHKSUPINF;
			end
			
			CHKSUPINF:begin
				if(((posY_bola==1)||(posY_bola==(posY_barra-1))))begin
					status_bola=CHKINF;
				end else begin
					status_bola=MOVY;
				end
			end
			
			CHKINF:begin
				if(posY_bola==(posY_barra-1)) begin 
					status_bola=CHKCHOQUE;
				end else begin
					status_bola=CAMBY;
				end
			end
			
			CHKCHOQUE:begin
				if((posX_bola==posX_barra)||(posX_bola==(posX_barra-1))||(posX_bola==(posX_barra+1))) begin
					status_bola=CAMBY;
				end else begin
					status_bola=FIN;
				end
			end
			
			CAMBY:begin
				cambY=1;
				movY=0;
				cambX=0;
				movX=0;
				lost=0;
				status_bola=MOVY;
			end
			
			MOVY:begin
				cambY=0;
				movY=1;
				cambX=0;
				movX=0;
				lost=0;
				status_bola=CHKX;
			end
			
			CHKX:begin
				if((posX_bola==1)||(posX_bola==(tamano_X-1)))begin 
					status_bola=CAMBX;
				end else begin
					status_bola=MOVX;
				end
			end
			
			CAMBX:begin
				cambY=0;
				movY=0;
				cambX=1;
				movX=0;
				lost=0;
				status_bola=MOVX;
			end
			
			MOVX:begin
				cambY=0;
				movY=0;
				cambX=0;
				movX=1;
				lost=0;
				status_bola=CHKSUPINF;
			end
			
			FIN:begin
				cambY=0;
				movY=0;
				cambX=0;
				movX=0;
				lost=1;
			end
			
		endcase
		
	end

endmodule
