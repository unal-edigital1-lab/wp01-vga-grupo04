`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:46:19 11/04/2020
// Design Name: 
// Module Name:    test_VGA
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module test_VGA(
    input wire clk,           // board clock: 32 MHz quacho 100 MHz nexys4 
    input wire rst,         	// reset button

	// VGA input/output  
    output wire VGA_Hsync_n,  // horizontal sync output
    output wire VGA_Vsync_n,  // vertical sync output
    output wire VGA_R,	// 4-bit VGA red output
    output wire VGA_G,  // 4-bit VGA green output
    output wire VGA_B,  // 4-bit VGA blue output
    output reg clkout,  
 	
	// input/output
	
	
	input wire bntr,
	input wire bntl,
	input wire init,
	output wire outPrueba
		
);

// TAMAÑO DE visualización 
parameter CAM_SCREEN_X = 160; //160
parameter CAM_SCREEN_Y = 128; //120

localparam AW = 15; // LOG2(CAM_SCREEN_X*CAM_SCREEN_Y)
localparam DW = 3;

// El color es RGB 444
localparam RED_VGA =   12'b111100000000;
localparam GREEN_VGA = 12'b000011110000;
localparam BLUE_VGA =  12'b000000001111;


// Clk 
wire clk50M;
wire clk108M;
reg clk25M=0;
reg clk2Hz=0;

// Conexión dual por ram

wire  [AW-1: 0] DP_RAM_addr_in;  
wire  [DW-1: 0] DP_RAM_data_in;
wire DP_RAM_regW;
wire  [AW-1: 0] DP_RAM_addr_in2;  
wire  [DW-1: 0] DP_RAM_data_in2;
wire DP_RAM_regW2;

reg  [AW-1: 0] DP_RAM_addr_out;  
	
// Conexión VGA Driver
wire [DW-1:0]data_mem;	   // Salida de dp_ram al driver VGA
wire [DW-1:0]data_RGB444;  // salida del driver VGA al puerto
wire [10:0]VGA_posX;		   // Determinar la pos de memoria que viene del VGA
wire [10:0]VGA_posY;		   // Determinar la pos de memoria que viene del VGA


/* ****************************************************************************
la pantalla VGA es RGB 444, pero el almacenamiento en memoria se hace 332
por lo tanto, los bits menos significactivos deben ser cero
**************************************************************************** */
	assign VGA_R = data_RGB444[2];
	assign VGA_G = data_RGB444[1];
	assign VGA_B = data_RGB444[0];





/* ****************************************************************************
  Este bloque se debe modificar según sea le caso. El ejemplo esta dado para
  fpga Spartan6 lx9 a 32MHz.
  usar "tools -> IP Generator ..."  y general el ip con Clocking Wizard
  el bloque genera un reloj de 25Mhz usado para el VGA , a partir de una frecuencia de 12 Mhz
**************************************************************************** */
assign clk50M =clk;


clk50to108_2 clk108(
	.inclk0(clk50M),
	.c0(clk108M)
	
);

always @(posedge clk)begin
	clk25M=~clk25M;
end

//clk2Hz
reg [24:0] cont_clk2Hz=0;
always @(posedge clk50M)begin
	cont_clk2Hz=cont_clk2Hz+1;
	if (cont_clk2Hz == 50000)begin  //en realidad de 1kHz
		clk2Hz = ~clk2Hz;
		cont_clk2Hz=0;
	end
end
assign outPrueba = clk2Hz;


reg [26:0] contador=0;

always @(posedge clk108M) begin
	contador=contador+1;
	if (contador==108000000)begin
		clkout = ~clkout;
		contador=0;
	end
end



//assign clk25M=clk;
//assign clkout=clk25M;

/* ****************************************************************************
buffer_ram_dp buffer memoria dual port y reloj de lectura y escritura separados
Se debe configurar AW  según los calculos realizados en el Wp01
se recomiendia dejar DW a 8, con el fin de optimizar recursos  y hacer RGB 332
**************************************************************************** */
buffer_ram_dp #( AW,DW,"C:/Users/difao/OneDrive/Documents/Digital I/Laboratorio/wp01-vga-grupo04/hdl/quartus/scr/prueba3.men")
	DP_RAM(  
	.clk_w(clk108M), //clk25M
	.addr_in(DP_RAM_addr_in), 
	.data_in(DP_RAM_data_in),
	.regwrite(DP_RAM_regW),

	.clk_w2(clk108M),
	.addr_in2(DP_RAM_addr_in2), 
	.data_in2(DP_RAM_data_in2),
	.regwrite2(DP_RAM_regW2),
	
	.clk_r(clk108M), 
	.addr_out(DP_RAM_addr_out),
	.data_out(data_mem)
	);
	

/* ****************************************************************************
VGA_Driver640x480
**************************************************************************** */
VGA_Driver640x480 VGA640x480
(
	.rst(~rst),
	.clk(clk108M), 				// 25MHz  para 60 hz de 640x480
	.pixelIn(data_mem), 		// entrada del valor de color  pixel RGB 444 
//	.pixelIn(RED_VGA), 		// entrada del valor de color  pixel RGB 444 
	.pixelOut(data_RGB444), // salida del valor pixel a la VGA 
	.Hsync_n(VGA_Hsync_n),	// señal de sincronizaciÓn en horizontal negada
	.Vsync_n(VGA_Vsync_n),	// señal de sincronizaciÓn en vertical negada 
	.posX(VGA_posX), 			// posición en horizontal del pixel siguiente
	.posY(VGA_posY) 			// posición en vertical  del pixel siguiente

);

 
/* ****************************************************************************
LÓgica para actualizar el pixel acorde con la buffer de memoria y el pixel de 
VGA si la imagen de la camara es menor que el display  VGA, los pixeles 
adicionales seran iguales al color del último pixel de memoria 
**************************************************************************** */

reg [10:0] tempx;
reg [10:0] tempy;

always @ (VGA_posX, VGA_posY) begin
//		if ((VGA_posX>CAM_SCREEN_X-1) || (VGA_posY>CAM_SCREEN_Y-1))
//			DP_RAM_addr_out=20500; //19212 12300
//		else
//			DP_RAM_addr_out=VGA_posX+VGA_posY*CAM_SCREEN_X;

		tempx = VGA_posX/8;
		tempy = VGA_posY/8;	
		DP_RAM_addr_out=tempx+tempy*CAM_SCREEN_X;
		
end


//assign DP_RAM_addr_out=10000;

/*****************************************************************************

este bloque debe crear un nuevo archivo 
**************************************************************************** */
 FSM_game  juego(
	 	.clk(clk2Hz),  //clk108M
		.rst(~rst),
		.in1(~bntr),
		.in2(~bntl),
		.in3(~init),
		
		.mem_px_addr2(DP_RAM_addr_in2),
		.mem_px_data2(DP_RAM_data_in2),
		.px_wr2(DP_RAM_regW2),
		
		.mem_px_addr(DP_RAM_addr_in),
		.mem_px_data(DP_RAM_data_in),
		.px_wr(DP_RAM_regW)
		
		
   );
endmodule
