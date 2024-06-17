module fp
(
  input                 clk,
  input                 rst,
  input                 vld,
  input        [31 : 0] value,
  output logic [31 : 0] res,
  output logic          res_vld
);

  logic exception;
  logic [31 : 0] sum;

  Addition_Subtraction adder_inst 
  (
    .a              (value),
    .b              (res),
    .add_sub_signal (1'b0),
    .exception      (exception),
    .res            (sum)
  );

  always_ff @ (posedge clk)
      if (rst)
          res <= 32'b0;
      else if (vld)
          res <= sum;

  always_ff @ (posedge clk)
      if (vld)
          res_vld <= ~exception;
      else
          res_vld <= 1'b0;

endmodule
