
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module gpu(

	//////////// CLOCK //////////
	CLOCK_125_p,
	CLOCK_50_B5B,
	CLOCK_50_B6A,
	CLOCK_50_B7A,
	CLOCK_50_B8A,

	//////////// LED //////////
	LEDG,
	LEDR,

	//////////// KEY //////////
	CPU_RESET_n,
	KEY,

	//////////// SW //////////
	SW,

	//////////// SEG7 //////////
	HEX0,
	HEX1,
	HEX2,
	HEX3,

	//////////// HDMI-TX //////////
	HDMI_TX_CLK,
	HDMI_TX_D,
	HDMI_TX_DE,
	HDMI_TX_HS,
	HDMI_TX_INT,
	HDMI_TX_VS,

	//////////// I2C for Audio/HDMI-TX/Si5338/HSMC //////////
	I2C_SCL,
	I2C_SDA 
);

//=======================================================
//  PARAMETER declarations
//=======================================================


//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input 		          		CLOCK_125_p;
input 		          		CLOCK_50_B5B;
input 		          		CLOCK_50_B6A;
input 		          		CLOCK_50_B7A;
input 		          		CLOCK_50_B8A;

//////////// LED //////////
output		     [7:0]		LEDG;
output		     [9:0]		LEDR;

//////////// KEY //////////
input 		          		CPU_RESET_n;
input 		     [3:0]		KEY;

//////////// SW //////////
input 		     [9:0]		SW;

//////////// SEG7 //////////
output		     [6:0]		HEX0;
output		     [6:0]		HEX1;
output		     [6:0]		HEX2;
output		     [6:0]		HEX3;

//////////// HDMI-TX //////////
output		          		HDMI_TX_CLK;
output		    [23:0]		HDMI_TX_D;
output		          		HDMI_TX_DE;
output		          		HDMI_TX_HS;
input 		          		HDMI_TX_INT;
output		          		HDMI_TX_VS;

//////////// I2C for Audio/HDMI-TX/Si5338/HSMC //////////
output		          		I2C_SCL;
inout 		          		I2C_SDA;


//=======================================================
//  REG/WIRE declarations
//=======================================================

	// PLL for HDMI
	wire CLOCK_25;
	wire locked;
	
	// current HDMI coordinates
	wire [11:0] raw_x, raw_y;
	wire hdmi_ready;
	
	// memory wires for the renderer
	reg [7:0] next_fb_address[79:0];
	reg [7:0] next_fb_data[79:0];
	wire [7:0] fb_data[79:0];
	reg next_fb_we[79:0];
	
	// memory wires for the rasterizer
	reg [7:0] next_bg_address[79:0];
	reg [7:0] next_bg_data[79:0];
	wire [7:0] bg_data[79:0];
	reg next_bg_we[79:0];
	
	// memory wires from the shader cores to the framebuffer
	wire [7:0] core_address[79:0];
	wire [7:0] core_data[79:0];
	wire core_we[79:0];
	wire core_ready[79:0];
	
	// memory wires 
	wire [5:0] core_frag_pc[79:0];
	wire [15:0] core_frag_ir[79:0];
	wire [5:0] core_frag_addr[79:0];
	wire core_frag_we[79:0];
	wire [15:0] core_frag_out[79:0], core_frag_data[79:0];
	
	reg [7:0] next_r, next_g, next_b;
	
	// temporary wires used for calculations
	reg [9:0] x, y;
	reg [9:0] block_id_long, cell_id_long;
	reg [6:0] block_id;
	reg [7:0] cell_id;
	reg [4:0] block_id_x, block_id_y;
	
	// variables that renderer can pass to rasterizer
	reg [7:0] center_x, next_center_x, center_y, next_center_y;
	
	// input buttons that change the variables
	wire key0, key1, key2, key3;
	
	// keep track of which framebuffer is for rendering and
	// which is for rasterizing
	reg restart;
	reg render_mode, next_render_mode;
	
	// global counter
	integer i;
	

//=======================================================
//  Structural coding
//=======================================================

	// wire together 25 MHz clock (from PLL) and hdmi driver
	pll clock25gen(CLOCK_50_B5B, ~CPU_RESET_n, CLOCK_25, locked);
	hdmi driver(CLOCK_25 & locked, CPU_RESET_n, raw_x, raw_y, next_r, next_g, next_b, hdmi_ready, HDMI_TX_CLK, HDMI_TX_D, HDMI_TX_DE, HDMI_TX_HS, HDMI_TX_INT, HDMI_TX_VS);
	
	// generate and wire all the shader cores!
	generate
		genvar gen_i;
		
		for(gen_i = 0; gen_i <= 79; gen_i = gen_i + 1) begin : fb
			fb_block mem (next_fb_address[gen_i], CLOCK_25, next_fb_data[gen_i], next_fb_we[gen_i], fb_data[gen_i]);
			fb_block mem2(next_bg_address[gen_i], CLOCK_25, next_bg_data[gen_i], next_bg_we[gen_i], bg_data[gen_i]);
			frag_block prog(core_frag_pc[gen_i], core_frag_addr[gen_i], CLOCK_25, 16'h0000, core_frag_out[gen_i] , 1'b0, core_frag_we[gen_i], core_frag_ir[gen_i], core_frag_data[gen_i]);
			core comp(CLOCK_25, restart, gen_i[6:0], gen_i[6:0] % 6'd10, gen_i[6:0] / 6'd10, core_address[gen_i], core_we[gen_i], core_data[gen_i], core_ready[gen_i],
					  core_frag_pc[gen_i], core_frag_ir[gen_i], core_frag_addr[gen_i], core_frag_we[gen_i], core_frag_data[gen_i], center_x, center_y);
		end
	endgenerate
	
	initial begin
		center_x = 8'd50;
		center_y = 8'd50;
	end
	
	// combinational logic
	always @(*) begin
		// default conditions for framebuffer wires
		for(i = 0; i <= 79; i = i + 1) begin
			next_fb_we[i] = 1'b0;
			next_fb_data[i] = 8'h00;
			next_fb_address[i] = 8'h00;
			
			next_bg_we[i] = 1'b0;
			next_bg_data[i] = 8'h00;
			next_bg_address[i] = 8'h00;
		end
		
		// update variables that are sent to fragment shaders
		next_center_x = center_x;
		next_center_y = center_y;
		
		if(key3 == 1'b1) begin
			next_center_x = center_x - 8'h05;
		end else if(key2 == 1'b1) begin
			next_center_y = center_y + 8'h05;
		end else if(key1 == 1'b1) begin
			next_center_x = center_x + 8'h05;
		end else if(key0 == 1'b1) begin
			next_center_y = center_y - 8'h05;
		end
		
		// synchronize framebuffer swapping 
		restart = 1'b1;
		for(i = 0; i <= 79; i = i + 1) begin
			restart = restart & core_ready[i];
		end
		next_render_mode = render_mode ^ (restart);
		
		// calculate which framebuffer block to use based on position
		// of scan line
		x = raw_x[11:2];
		y = raw_y[11:2];
		
		block_id_long = (x >> 4) + ((y >> 4) << 3) + ((y >> 4) << 1);
		block_id = block_id_long[6:0];
		cell_id_long = (x & 10'h00F) + ((y & 10'h00F) << 4);
		cell_id = cell_id_long[7:0];
		
		// change behavior based on which framebuffer is being used for
		// rendering and rasterizing
		if(render_mode == 1'b0) begin
			next_fb_address[block_id] = cell_id;
			next_r =  fb_data[block_id] & 8'hE0;
			next_g = (fb_data[block_id] & 8'h1C) << 3;
			next_b = (fb_data[block_id] & 8'h03) << 6;
			
			for(i = 0; i <= 79; i = i + 1) begin
				next_bg_we[i] = core_we[i];
				next_bg_data[i] = core_data[i];
				next_bg_address[i] = core_address[i];
			end
		end else begin
			next_bg_address[block_id] = cell_id;
			next_r =  bg_data[block_id] & 8'hE0;
			next_g = (bg_data[block_id] & 8'h1C) << 3;
			next_b = (bg_data[block_id] & 8'h03) << 6;
			
			for(i = 0; i <= 79; i = i + 1) begin
				next_fb_we[i] = core_we[i];
				next_fb_data[i] = core_data[i];
				next_fb_address[i] = core_address[i];
			end
		end
	end
	
	// update the internal registers
	always @(posedge CLOCK_25) begin
		center_x <= next_center_x;
		center_y <= next_center_y;
		render_mode <= next_render_mode;
	end
	
	// debounces and single pulses inputs from keys
	DBSP dbsp1(CLOCK_25, KEY[0], key0);
	DBSP dbsp2(CLOCK_25, KEY[1], key1);
	DBSP dbsp3(CLOCK_25, KEY[2], key2);
	DBSP dbsp4(CLOCK_25, KEY[3], key3);
	
	// debugging output
	assign LEDG = 8'h00;
	assign LEDR = 10'h000;
	assign HEX0 = 6'h00;
	assign HEX1 = 6'h00;
	assign HEX2 = 6'h00;
	assign HEX3 = 6'h00;
	assign I2C_SCL = 1'b0;
	assign I2C_SDA = 1'b0;

endmodule

// takes in a keypress and clock, and generates a smooth single
// pulse when the key is pressed
module DBSP(clk, press, sp);
 	input clk, press;
 	output sp;
 
	reg [7:0] count;
	reg debounced;
	wire Qa;
	
	initial begin
	  count <= 8'h00;
	  debounced <= 1'b0;
	end
	
	always @ (posedge clk) 
	begin
		// use shift register to keep track of last 8 states
		// when the values in the shift register are the same,
		// the key is said to be done bouncing
		count <= {count[6:0], press};
		if(count[7:0] == 8'b00000000) begin
			debounced <= 1'b0;
		end else if(count[7:0] == 8'b11111111) begin
			debounced <= 1'b1;
		end else begin
			debounced <= debounced;
		end
	end 

	// put a single flip flop in the way to single pulse the output
	flop a(clk, debounced, Qa);
	and(sp, debounced, ~Qa);
	
endmodule

// basic flip flop used for single pulsing
module flop(clk, D, Q);
  input clk, D;
  output Q;
  
  reg Q;
  
  always @(posedge clk) begin
    Q <= D;
  end
endmodule

// a single shader core
module core(
	clk, restart,
	block_id, block_x, block_y,
	address, we, data,
	ready,
	next_pc, d_ir, next_m_addr, next_m_we, mem_data,
	center_x, center_y
);
	
	input clk, restart;
	input [6:0] block_id;
	input [4:0] block_x, block_y;
	output [7:0] address, data;
	output we, ready;
	output [5:0] next_pc, next_m_addr;
	output next_m_we;
	input [15:0] d_ir, mem_data;
	input [7:0] center_x, center_y;

	reg we;
	reg [7:0] address, data;
	
	reg [7:0] index, next_index;
	reg ready, next_ready;
	
	reg [7:0] pixel_x, pixel_y;
	
	wire pipe_ready;
	wire [7:0] fragment;
	
	wire [5:0] next_pc, next_m_addr;
	wire [15:0] d_ir, mem_data;
	wire next_m_we;
	
	// the core's main piece of hardware. the pipeline takes in the current pixel location, the memory mapped I/O
	pipeline shader(clk, pixel_x, pixel_y, center_x, center_y, next_pc, d_ir, next_m_addr, next_m_we, mem_data, pipe_ready, fragment);
	
	always @(*) begin
		// compute the pixel's coordinates based on block_id and current
		// pixel that is being oeprated on
		pixel_x = (block_x << 4) + (index & 8'h0F);
		pixel_y = (block_y << 4) + (index >> 4);
		
		next_index = index;
		
		// write the pipeline's output when it announces that it has computed
		// the value of a single pixel
		address = index;
		data = fragment;
		we = pipe_ready;
		
		if(restart == 1'b1) begin
			// once the core has completed it's block, it must wait for 
			// the HDMI driver to relase the rasterization framebuffer
			// then it begins working on the block again
			next_index = 8'h00;
			next_ready = 1'b0;
		end else begin
			if(pipe_ready == 1'b1) begin
				// move onto the next pixel if the pipeline has finished with
				// the current one
				next_index = index + 1'b1;
			end
			next_ready = index == 8'hFF;
		end
	end
	
	always @(posedge clk) begin
		if(ready == 1'b0) begin
			index <= next_index;
		end
		
		ready <= next_ready;
	end
endmodule

// simple pipeline
module pipeline(
	clk,
	pixel_x, pixel_y,
	center_x, center_y,
	next_pc, d_ir,
	next_m_addr, next_m_we, mem_data,
	done, color
);

	input clk;
	input [7:0] pixel_x, pixel_y;
	input [7:0] center_x, center_y;
	output [5:0] next_pc, next_m_addr;
	output next_m_we;
	input [15:0] d_ir, mem_data;
	output done;
	output [7:0] color;
	
	// only supports loads and stores :(
	`define LD 4'b0100
	`define ST 4'b0101
	
	reg [7:0] regs[7:0];
	
	reg [5:0] pc, next_pc;
	
	wire [15:0] d_ir;
	reg [5:0] d_pc, next_d_pc;
	
	reg [7:0] e_sr1, next_e_sr1;
	reg [2:0] e_drid, next_e_drid;
	reg [15:0] e_ir, next_e_ir;
	reg [5:0] e_pc, next_e_pc;
	
	reg [5:0] m_addr, next_m_addr;
	reg m_done, next_m_done;
	reg next_m_we;
	reg [7:0] m_res, next_m_res;
	reg [2:0] m_drid, next_m_drid;
	reg [15:0] m_ir, next_m_ir;
	
	wire [15:0] mem_data;
	reg [7:0] wb_data, next_wb_data;
	reg [7:0] wb_res, next_wb_res;
	reg [2:0] wb_drid, next_wb_drid;
	reg wb_done, next_wb_done;
	reg [5:0] wb_addr, next_wb_addr;
	reg [15:0] wb_ir, next_wb_ir;
	reg wb_mmap, next_wb_mmap;
	
	reg done;
	reg [1:0] pc_mux;
	reg reg_we;
	reg [7:0] color;
	reg [7:0] next_reg_data;
	
	reg init;
	
	initial begin
		init <= 1'b1;
	end
	
	always @(*) begin
		////////////////////////////////////// fetch
		next_d_pc = pc + 6'h01;
		
		case(pc_mux)
			2'b00:   next_pc = pc + 6'h01;
			2'b01:   next_pc = 6'h00;
			default: next_pc = pc + 6'h01;
		endcase
		
		////////////////////////////////////// decode
		next_e_sr1 = regs[d_ir[10:8]];
		next_e_drid = d_ir[6:4];
		next_e_ir = d_ir;
		next_e_pc = d_pc;
		
		if(d_ir[15:12] == `LD) begin
			next_e_drid = d_ir[10:8];
		end
		
		////////////////////////////////////// execute
		next_m_done = 1'b0;
		next_m_we = 1'b0;
		next_m_addr = e_pc + e_ir[5:0];
		next_m_res = e_sr1;
		next_m_drid = e_drid;
		next_m_ir = e_ir;
		
		if(e_ir[15:12] == `ST) begin
			next_m_we = 1'b1;
			
			// check if writing to memory mapped I/O
			if(next_m_addr[5] == 1'b1) begin
				next_m_done = 1'b1;
				next_m_we = 1'b0;
			end
		end
		
		/////////////////////////////////////// memory
		next_wb_data = 8'h03;
		next_wb_mmap = 1'b0;
		next_wb_res = m_res;
		next_wb_drid = m_drid;
		next_wb_done = m_done;
		next_wb_ir = m_ir;
		
		if(m_ir[15:12] == `LD && m_addr[5] == 1'b1) begin
			// handle memory mapped reads
			case(m_addr[4:0])
				6'h00:   next_wb_data = pixel_x;
				6'h01:   next_wb_data = pixel_y;
				6'h02:   next_wb_data = center_x;
				6'h03:   next_wb_data = center_y;
				default: next_wb_data = 8'h00;
			endcase
			
			next_wb_mmap = 1'b1;
		end
		
		/////////////////////////////////////// writeback
		pc_mux = 2'b00;
		done = wb_done;
		color = 8'h03;
		next_reg_data = wb_res;
		reg_we = 1'b0;
		
		if(wb_done == 1'b1) begin
			pc_mux = 2'b01;
			done = 1'b1;
			color = wb_res;
		end
		
		if(wb_ir[15:12] == `LD) begin
			next_reg_data = (wb_mmap == 1'b1) ? wb_data : mem_data[7:0];
			reg_we = 1'b1;
		end
	end
	
	always @(posedge clk) begin
		if(init == 1'b0) begin
			pc <= next_pc;
		end
		
		init <= 1'b0;
		
		d_pc <= next_d_pc;
		
		e_sr1 <= next_e_sr1;
		e_drid <= next_e_drid;
		e_ir <= next_e_ir;
		e_pc <= next_e_pc;
		
		m_addr <= next_m_addr;
		m_done <= next_m_done;
		m_res <= next_m_res;
		m_drid <= next_m_drid;
		m_ir <= next_m_ir;
		
		wb_data <= next_wb_data;
		wb_res <= next_wb_res;
		wb_drid <= next_wb_drid;
		wb_done <= next_wb_done;
		wb_ir <= next_wb_ir;
		wb_mmap <= next_wb_mmap;
		
		if(reg_we) begin
			regs[wb_drid] <= next_reg_data;
		end
	end
endmodule

	
// Chris Haster's HDMI driver, thank you Chris!
module hdmi(
    clock25mhz, resetn,
    x, y,
    r, g, b,
	ready,
    
	//////////// HDMI-TX //////////
	HDMI_TX_CLK,
	HDMI_TX_D,
	HDMI_TX_DE,
	HDMI_TX_HS,
	HDMI_TX_INT,
	HDMI_TX_VS
);

parameter CYCLE_DELAY = 2;

parameter WIDTH = 640;
parameter HEIGHT = 480;
parameter XDIV = 1;
parameter YDIV = 1;
parameter XSTART = 0;
parameter XEND = XSTART + XDIV*WIDTH;
parameter YSTART = 0;
parameter YEND = YSTART + YDIV*HEIGHT;

parameter HSIZE = 640;
parameter VSIZE = 480;
parameter HTOTAL = 800;
parameter VTOTAL = 525;
parameter HSYNC = 96;
parameter VSYNC = 2;
parameter HSTART = 144;
parameter VSTART = 34;
parameter HEND = HSTART + HSIZE;
parameter VEND = VSTART + VSIZE;


input clock25mhz;
input resetn;
output reg [11:0] x;
output reg [11:0] y;
input [7:0] r;
input [7:0] g;
input [7:0] b;
output wire ready;

output HDMI_TX_CLK = ~clock25mhz;
output [23:0] HDMI_TX_D = hdmi_data;
output HDMI_TX_DE = hdmi_de[1];
output HDMI_TX_HS = hdmi_hsync[1];
output HDMI_TX_VS = hdmi_vsync[1];
input HDMI_TX_INT;


reg [23:0] hdmi_data;
reg hdmi_de [2];
reg hdmi_hsync [2];
reg hdmi_vsync [2];

reg [11:0] hdmi_hprecount;
reg [11:0] hdmi_vprecount;
reg [11:0] hdmi_hcount;
reg [11:0] hdmi_vcount;
wire hdmi_hactive = hdmi_hcount >= HSTART && hdmi_hcount < HEND;
wire hdmi_vactive = hdmi_vcount >= VSTART && hdmi_vcount < VEND;
wire hdmi_active = hdmi_hactive && hdmi_vactive;
wire hdmi_hpresync = ~(hdmi_hcount < HSYNC);
wire hdmi_vpresync = ~(hdmi_vcount < VSYNC);

always @(posedge clock25mhz or negedge resetn) begin
    if (!resetn) begin
        hdmi_de[0] <= 0; 
        hdmi_de[1] <= 0;
        hdmi_hsync[0] <= 0;
        hdmi_hsync[1] <= 0;
        hdmi_vsync[0] <= 0;
        hdmi_vsync[1] <= 0;
        hdmi_hcount <= 0;
        hdmi_vcount <= 0;
    end else begin
        hdmi_de[0] <= hdmi_active;
        hdmi_de[1] <= hdmi_de[0];
        hdmi_hsync[0] <= hdmi_hpresync;
        hdmi_hsync[1] <= hdmi_hsync[0];
        hdmi_vsync[0] <= hdmi_vpresync;
        hdmi_vsync[1] <= hdmi_vsync[0];
    
        if (hdmi_hcount + 1'b1 == HTOTAL) begin
            hdmi_hcount <= 0;
            
            if (hdmi_vcount + 1'b1 == VTOTAL) begin
                hdmi_vcount <= 0;
            end else begin
                hdmi_vcount <= hdmi_vcount + 1'b1;
            end
        end else begin
            hdmi_hcount <= hdmi_hcount + 1'b1;
        end
    end
end


wire xactive = hdmi_hcount >= HSTART+XSTART && hdmi_hcount < HSTART+XEND;
wire yactive = hdmi_vcount >= VSTART+YSTART && hdmi_vcount < VSTART+YEND;
wire xsetup = hdmi_hcount >= HSTART+XSTART-CYCLE_DELAY && hdmi_hcount < HSTART+XEND-CYCLE_DELAY;
wire ysetup = hdmi_vcount >= VSTART+YSTART && hdmi_vcount < VSTART+YEND;
assign ready = ((x + 1'b1) == WIDTH) && ((y + 1'b1) == HEIGHT);

reg [$clog2(XDIV)-1:0] xcount;
reg [$clog2(YDIV)-1:0] ycount;

always @(posedge clock25mhz or negedge resetn) begin
    if (!resetn) begin
        hdmi_data <= 0;
        xcount <= 0;
        x <= 0;
        ycount <= 0;
        y <= 0;
    end else begin
        if (xactive && yactive) begin
            hdmi_data <= {r, g, b};
        end else begin
            hdmi_data <= 0;
        end
    
        if (xsetup && ysetup) begin
            if (xcount + 1'b1 == XDIV) begin
                xcount <= 0;
                if (x + 1'b1 == WIDTH) begin
                    x <= 0;
                    if (ycount + 1'b1 == YDIV) begin
                        ycount <= 0;
                        if (y + 1'b1 == HEIGHT) begin
                            y <= 0;
                        end else begin
                            y <= y + 1'b1;
                        end
                    end else begin
                        ycount <= ycount + 1'b1;
                    end
                end else begin
                    x <= x + 1'b1;
                end
            end else begin
                xcount <= xcount + 1'b1;
            end
        end
    end 
end

endmodule