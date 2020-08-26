module Ligt_Sensor_Master
	(input i_Clk,
	 input i_Switch_1,

   output o_Segment1_A,
   output o_Segment1_B,
   output o_Segment1_C,
   output o_Segment1_D,
   output o_Segment1_E,
   output o_Segment1_F,
   output o_Segment1_G,
   output o_Segment2_A,
   output o_Segment2_B,
   output o_Segment2_C,
   output o_Segment2_D, 
   output o_Segment2_E,
   output o_Segment2_F,
   output o_Segment2_G, 
	 

	 output o_SPI_Clk,
	 output o_MOSI,
	 output o_CS,
	 input i_SPI_MISO,

	 output o_LED_1
	 );


//localparam CYCLES_PER_CLK = 10;

//localparam CYCLES_PER_HALF_CLOCK = 5;

localparam CPOL = 1;

localparam IDLE = 4'b0000;

localparam SETUP_BEFORE_FALLING_EDGE = 4'b0001;

localparam DATA_BITS = 4'b0010;

localparam QUIET = 4'b0011;


reg r_LED_1 = 1'b0;

reg r_SPI_Clk = CPOL;

reg r_CS_Active_Low = 1'b1;

reg r_MOSI_DATA = 1'b0;

reg r_Start_Reading_Data = 1'b0;

reg [3:0] r_SM_SPI_MASTER = IDLE;

reg [30:0] r_Count = 1'b0;

reg r_Falling_Edge = 1'b1;

reg r_Is_Posedge = 1'b0;

reg [8:0] r_Posedge_Count = 0; 

reg [15:0] r_Data_Bits = 0;

reg [3:0] r_Cursor = 4'b1111;
 
reg r_Ok_To_Write_Data = 1'b0;

reg r_Switch_1 = 1'b0;

wire w_Switch_1;


Debounce_Switch Instance
    (.i_Clk(i_Clk),
     .i_Switch(i_Switch_1),
     .o_Switch(w_Switch_1));

always @(posedge i_Clk)
	begin
	case (r_SM_SPI_MASTER)      
      IDLE:
        begin

        	

    		if((r_Start_Reading_Data == 1'b1) )
				begin
					//CPOL is what the clock idles at 
					//so before we start a transaction let's set it 
					//to the proper idle state
					r_SPI_Clk <= CPOL;
				//	r_Start_Reading_Data <= 1'b0;
					r_CS_Active_Low <= 1'b0;
					r_SM_SPI_MASTER <= SETUP_BEFORE_FALLING_EDGE;
				end   
			else
				begin
					r_SM_SPI_MASTER <= IDLE;
				end	 	
      	end
      SETUP_BEFORE_FALLING_EDGE:
      	begin
      		//minimum setup time is 10 nanoseconds
      		//at 25 MHz each clock cycle is 40 nanoseconds..
      		//we will only wait 1 clock cycle before we start to cycle the SPI_CLk
      		//to do that we simply transition to LEADING_BITS

      		r_SM_SPI_MASTER <= DATA_BITS;

      	end 		
      DATA_BITS:
      	begin

      		//technically this if block also creates rising edges but it's easier to leave it as falling edge
      		if(r_Falling_Edge == 1'b1 && r_Count < 4)
      			begin
      				r_SPI_Clk <= ~r_SPI_Clk;
      				r_Falling_Edge <= 1'b0;
      				if(r_Is_Posedge == 1'b1)
      					begin
      						r_Posedge_Count <= r_Posedge_Count + 1;
      						r_Is_Posedge <= ~r_Is_Posedge;
      						r_Data_Bits[r_Cursor] <= i_SPI_MISO;
      						if(r_Posedge_Count + 1 == 16)
      							begin
      								r_CS_Active_Low <= 1'b1;
      								r_Count <= 0;
      								r_Posedge_Count <= 0;
      								r_SM_SPI_MASTER <= QUIET;
      								r_Cursor <= 4'b1111;
      								r_SPI_Clk <= CPOL;
      							end
      						else
      							begin
      								r_Count <= r_Count + 1;
      								r_SM_SPI_MASTER <= DATA_BITS;
      								r_Cursor <= r_Cursor - 1;
      							end	
      					end
      				else
      					begin
      						r_Count <= r_Count + 1;
      						r_Is_Posedge <= ~r_Is_Posedge;
      						r_SM_SPI_MASTER <= DATA_BITS;
      					end	
      			end
      		else if(r_Falling_Edge == 1'b0 && r_Count == 4)
      			begin
      				r_Falling_Edge <= 1'b1;
      				r_Count <= 0;
      				r_SM_SPI_MASTER <= DATA_BITS;
      			end	
      		else
      			begin
      				r_Count <= r_Count + 1;
      				r_SM_SPI_MASTER <= DATA_BITS;
      			end	
      		
      	end
      QUIET:
      	begin
      		r_Count <= r_Count + 1;
    
      		r_Ok_To_Write_Data <= 1'b1;

      		if(r_Count == 6)
      			begin
      				r_CS_Active_Low <= 1'b0;
      				r_Count <= 0;
      				r_SPI_Clk <= CPOL;
      				r_Falling_Edge <= 1'b1;
      				r_Ok_To_Write_Data <= 1'b0;
      				r_SM_SPI_MASTER <= SETUP_BEFORE_FALLING_EDGE;
      			end	
      		else
      			begin
      				r_SM_SPI_MASTER <= QUIET;
      			end
      	end				
      default:
        begin
			r_SM_SPI_MASTER <= IDLE;          
        end
      endcase




	end


wire [7:0] w_Important_Data;

reg [7:0] r_Important_Data;

always @(posedge i_Clk)
	begin
		if(r_Ok_To_Write_Data == 1'b1)
			begin
				r_Important_Data <= r_Data_Bits[12:5];
			end
	end

assign w_Important_Data = r_Important_Data;



always @(posedge i_Clk)
	begin
			r_Switch_1 <= w_Switch_1; //Creates a register


														//if last cycle the switch was high
														//and this cycle it's low then
														//we released the switch

		if(w_Switch_1 == 1'b0 && r_Switch_1 == 1'b1) 
			begin
				r_LED_1 <= 1'b1;
				r_Start_Reading_Data <= 1'b1;
			end

	end


reg r_LED_Enable;

reg [7:0] r_LED_Counter;

always @(posedge i_Clk)
	begin
		r_LED_Enable <= (r_LED_Counter < w_Important_Data);
		if(r_LED_Counter + 1 == 255)
			begin
				r_LED_Counter <= 0;
			end
		else
			begin
				r_LED_Counter <= r_LED_Counter + 1;
			end
	end



  assign o_Segment1_A = !r_LED_Enable;
  assign o_Segment1_B = !r_LED_Enable;
  assign o_Segment1_C = !r_LED_Enable;
  assign o_Segment1_D = !r_LED_Enable;
  assign o_Segment1_E = !r_LED_Enable;
  assign o_Segment1_F = !r_LED_Enable;
  assign o_Segment1_G = !r_LED_Enable;
  assign o_Segment2_A = !r_LED_Enable;
  assign o_Segment2_B = !r_LED_Enable;
  assign o_Segment2_C = !r_LED_Enable;
  assign o_Segment2_D = !r_LED_Enable;
  assign o_Segment2_E = !r_LED_Enable;
  assign o_Segment2_F = !r_LED_Enable;
  assign o_Segment2_G = !r_LED_Enable;


assign o_LED_1 = r_LED_1;

assign o_SPI_Clk = r_SPI_Clk;

assign o_CS = r_CS_Active_Low;

assign o_MOSI = r_MOSI_DATA; 

endmodule