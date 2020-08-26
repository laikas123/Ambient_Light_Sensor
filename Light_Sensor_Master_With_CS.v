module Light_Sensor_Master_With_CS
	(input i_Clk,
	 input i_TX_DV,
	 input i_RST_L,
	 input i_CPHA,
	 input i_CPOL,
	 output o_SPI_Clk);


localparam CYCLES_PER_CLK = 10;

localparam CYCLES_PER_HALF_CLOCK = 5;

reg r_SPI_Clk;

reg r_CS;

always @(posedge i_Clk)
	begin

	end





always @(posedge i_Clk)
	begin
		if(~i_RST_L)
		begin
			//CPOL is what the clock idles at 
			//so before we start a transaction let's set it 
			//to the proper idle state
			r_SPI_Clk <= i_CPOL;
			r_CS <= 1'b0;
		end
	end


assign o_SPI_Clk = r_SPI_Clk;



endmodule



