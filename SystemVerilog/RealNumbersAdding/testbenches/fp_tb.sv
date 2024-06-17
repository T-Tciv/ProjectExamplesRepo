module testbench;
  logic          clk;
  logic          rst;
  logic          vld;
  logic [31 : 0] value;
  logic [31 : 0] res;
  logic          res_vld;

  fp inst
  (
    .clk     (clk),
    .rst     (rst),
    .vld     (vld),
    .value   (value),
    .res     (res),
    .res_vld (res_vld)
  );

  initial
    begin
      clk = 1;   
      # 1;
      rst <= '1;
      repeat (1) @ (posedge clk);
      rst <= '0;
      repeat (1) @ (posedge clk);

      vld <= '1;
      value <= 32'b01000000000000000000000000000000; // 2
      repeat (1) @ (posedge clk);
      value <= 32'b00111111000000000000000000000000; // 0.5
      repeat (1) @ (posedge clk);
      value <= 32'b00111110100000000000000000000000; // 0.25
      repeat (1) @ (posedge clk);
      value <= 32'b00111111000000000000000000000000; // 0.5
      repeat (1) @ (posedge clk);
      value <= 32'b00111111000000000000000000000000; // 0.5

      repeat (1) @ (posedge clk);
      vld <= '0;

      # 500;

      // 2 + 0.5 + 0.25 + 0.5 + 0.5 = 3.75

      $stop;
    end

  always 
    begin
		# 50;
		clk = ~clk;
	end

endmodule