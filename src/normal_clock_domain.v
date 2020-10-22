`timescale 1ns / 1ps

module normal_clock_domain(
    input clk,
    input rst,
    output miso,
    input mosi,
    input ss,
    input sclk,
    output led_out,
    output acq_enable,
    output acq_reset,
    output clock_select,
    output [7:0] clock_divisor,
    output [15:0] channel_enable,
    input fifo_overflow,
    input clklock
);

   wire [6:0] reg_num;
   wire reg_write;
   reg  [7:0] reg_data_read;
   wire [7:0] reg_data_write;

   regaccess reg_file
     (
      .clk(clk),
      .rst(rst),
      .ss(ss),
      .mosi(mosi),
      .miso(miso),
      .sck(sclk),
      .regnum(reg_num),
      .regdata_read(reg_data_read),
      .regdata_write(reg_data_write),
      .read(),
      .write(reg_write)
      );


   localparam VERSION = 8'h13;

   // Registers

   localparam REG_VERSION = 'h07;
   localparam REG_STATUS_CONTROL = 'h0F;
   localparam REG_CHANNEL_SELECT_LOW = 'h01;
   localparam REG_CHANNEL_SELECT_HIGH = 'h06;
   localparam REG_SAMPLE_RATE_DIVISOR = 'h0B;
   localparam REG_LED_BRIGHTNESS = 'h05;
   localparam REG_PRIMER_DATA1 = 'h0E;
   localparam REG_PRIMER_CONTROL = 'h02;
   localparam REG_MODE = 'h04;
   localparam REG_PRIMER_DATA2 = 'h03;

   reg [7:0]  led_brightness_d, led_brightness_q;
   reg        sc_unknown_2_d, sc_unknown_2_q;
   reg        acq_enable_d, acq_enable_q;
   reg        acq_reset_d, acq_reset_q;
   reg        clock_select_d, clock_select_q;
   reg [7:0]  clock_divisor_d, clock_divisor_q;
   reg [7:0]  channel_select_low_d, channel_select_low_q;
   reg [7:0]  channel_select_high_d, channel_select_high_q;

   always @(*) begin

      led_brightness_d = led_brightness_q;
      sc_unknown_2_d = sc_unknown_2_q;
      acq_enable_d = acq_enable_q;
      acq_reset_d = acq_reset_q;
      clock_select_d = clock_select_q;
      clock_divisor_d = clock_divisor_q;
      channel_select_low_d = channel_select_low_q;
      channel_select_high_d = channel_select_high_q;

      case (reg_num)
	REG_VERSION: reg_data_read = VERSION;
	REG_STATUS_CONTROL: begin
	   reg_data_read = {1'b0, 1'b0, acq_enable_q, clklock, 
			    acq_reset_q, sc_unknown_2_q, 1'b0, fifo_overflow};
	   if (reg_write) begin
	      sc_unknown_2_d = reg_data_write[2];
	      acq_enable_d = reg_data_write[5];
	      acq_reset_d = reg_data_write[3];
	   end
	end
	REG_CHANNEL_SELECT_LOW: begin
	   reg_data_read = channel_select_low_q;
	   if (reg_write) channel_select_low_d = reg_data_write;
	end
	REG_CHANNEL_SELECT_HIGH: begin
	   reg_data_read = channel_select_high_q;
	   if (reg_write) channel_select_high_d = reg_data_write;
	end
	REG_SAMPLE_RATE_DIVISOR: begin
	   reg_data_read = clock_divisor_q;
	   if (reg_write) clock_divisor_d = reg_data_write;
	end
	REG_LED_BRIGHTNESS: begin
	   reg_data_read = led_brightness_q;
	   if (reg_write) led_brightness_d = reg_data_write;
	end
	REG_MODE: begin
	   reg_data_read = { 7'b0000000, clock_select_q };
	   if (reg_write) begin
	      clock_select_d = reg_data_write[2];
	   end
	end
	default: reg_data_read = 8'b00000000;
      endcase

   end

   always @(posedge clk) begin
      if (rst) begin
	 led_brightness_q <= 8'h00;
	 sc_unknown_2_q <= 1'b0;
	 acq_enable_q <= 1'b0;
	 acq_reset_q <= 1'b0;
	 clock_select_q <= 1'b0;
	 clock_divisor_q <= 8'h00;
	 channel_select_low_q <= 8'h00;
	 channel_select_high_q <= 8'h00;
      end else begin
	 led_brightness_q <= led_brightness_d;
	 sc_unknown_2_q <= sc_unknown_2_d;
	 acq_enable_q <= acq_enable_d;
	 acq_reset_q <= acq_reset_d;
	 clock_select_q <= clock_select_d;
	 clock_divisor_q <= clock_divisor_d;
	 channel_select_low_q <= channel_select_low_d;
	 channel_select_high_q <= channel_select_high_d;
      end
   end


   // LED

   wire led_pwm_out;

   pwm #(18, 8) led_pwm(.clk(clk), .rst(rst), .pulse_width(led_brightness_q),
			.out(led_pwm_out));

   assign led_out = ~led_pwm_out;
   assign acq_enable = acq_enable_q;
   assign acq_reset = acq_reset_q | rst;
   assign clock_select = clock_select_q;
   assign clock_divisor = clock_divisor_q;
   assign channel_enable = { channel_select_high_q, channel_select_low_q };

endmodule
