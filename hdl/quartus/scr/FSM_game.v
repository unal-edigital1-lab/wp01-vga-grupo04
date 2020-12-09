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
	
	localparam COLOR_BARRA = 3'b010;
	localparam COLOR_BOLA = 3'b111;
	
	reg [7:0] tamano_X = 128;
	reg [7:0] tamano_Y = 96;
	
	reg [3:0] status=0;
	reg init;
	reg right;
	reg left;
	assign right = in1;
	assign left = in2;
	assign init = in3;
	
	reg pos_ini;
	reg movr;
	reg movl;
	
	//8 bits para la posicion vertical y 9 para la horizonal
	
	reg [7:0] posX_barra;
	reg [6:0] posY_barra;
	
	reg [7:0] posX_bola;
	reg [6:0] posY_bola;
	
	
	//Posiciones iniciales
	always @(posedge clk)begin
		if(pos_ini)begin
			posX_barra = 64;
			posY_barra = 90;
			
			posX_bola = 64;
			posY_bola = 48;
			
			//Poner posiciones en memoria
			
			mem_px_addr = posX_barra+(posX_barra-1)*posY_barra;
			mem_px_data = COLOR_BARRA;
			
			px_wr = 1;
			#1 px_wr = 0;
			mem_px_addr = mem_px_addr+1;
			px_wr = 1;
			#1 px_wr = 0;
			mem_px_addr = mem_px_addr-2;
			px_wr = 1;
			#1 px_wr = 0;
			
			mem_px_addr = posX_bola+(posX_bola-1)*posY_bola;
			mem_px_data = COLOR_BOLA;
			px_wr = 1;
			#1 px_wr = 0;
			
			
		end
	end
	
	//Mover a la derecha la barra
	always @(posedge clk)begin
		if(movr)begin
			posX_barra = posX_barra+1;
			
			mem_px_addr = posX_barra+(posX_barra-1)*posY_barra;
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
	
	//Mover a la izquierda la barra
	always @(posedge clk)begin
		if(movl)begin
			posX_barra = posX_barra-1;
			
			mem_px_addr = posX_barra+(posX_barra-1)*posY_barra;
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
	
	
	parameter START=0, CHKL=1, CHKR=2, MOVL=3, MOVR=4;
	always @(posedge clk) begin
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
				pos_ini=0;
				movl=1;
				movr=0;
				status=CHKR;
			end
			
			MOVR: begin
				pos_ini=0;
				movl=0;
				movr=1;
				status=CHKL;
			end
			
		endcase
	end
	
	/**aca va el codigo de cada grupo**/
endmodule
