`timescale 1ns / 1ps

module testbench();

reg clk;
reg cpu_resetn;
reg [4:0] btn;
reg [4:0] sw;
wire [15:0] led;

interface inst_interface (
            .CLK(clk),
            .CPU_RESETN(cpu_resetn),
            .BTN(btn),
            .SW(sw),
            .LED(led)
          );

initial
  begin
    clk = 0;
    forever
      #5 clk = ~clk;
  end

initial
  begin
    cpu_resetn = 1;
    btn = 5'b00000;
    sw = 5'b00000;
    #1000
     btn = 5'b00001; // C
    #1000
     btn = 5'b01000; // U
    #1000
     btn = 5'b00001; // C
    #1000
     btn = 5'b00010; // L
    #1000
     btn = 5'b00001; // C
    #1000
     btn = 5'b00100; // R
    #1000
     btn = 5'b00000;
     sw = 5'b00001; // 1
    #1000
     sw = 5'b00000; // 1
    #1000
     sw = 5'b00010; // 5
    #2000
     btn = 5'b00001; // C
    #1000
     btn = 5'b00000;
    #1000
     $stop;
  end

endmodule
