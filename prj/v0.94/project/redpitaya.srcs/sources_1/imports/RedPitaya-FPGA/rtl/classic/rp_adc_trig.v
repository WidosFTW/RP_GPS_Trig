/**
 * $Id: rp_adc_trig.v 2024-03-15
 *
 * @brief Red Pitaya ADC trigger
 *
 * @Author Jure Trnovec
 *
 * (c) Red Pitaya  http://www.redpitaya.com
 *
 * This part of code is written in Verilog hardware description language (HDL).
 * Please visit http://en.wikipedia.org/wiki/Verilog
 * for more details on the language used herein.
 */

/*
GENERAL DESCRIPTION:
Within this module we create the ADC signal threshold triggers.
*/

module rp_adc_trig #(
  parameter DW  = 14
)(
  // ADC
  input                 adc_clk_i       ,  // ADC clock
  input                 adc_rstn_i      ,  // ADC reset - active low

  input      [ DW-1: 0] adc_dat_i       ,
  input                 adc_dv_i        ,
  input      [ DW-1: 0] set_tresh_i     ,
  input      [ DW-1: 0] set_hyst_i      ,
  input                 use_abs_i       ,  // <-- NEW: Flag to enable absolute mode

  output reg            adc_trig_p_o    ,
  output reg            adc_trig_n_o
);

reg  [  2-1: 0] adc_scht_p  ;
reg  [  2-1: 0] adc_scht_n  ;
reg  [ DW-1: 0] set_treshp ;
reg  [ DW-1: 0] set_treshm ;

// <-- NEW: Data processing logic
wire [ DW-1: 0] adc_dat_abs;
wire [ DW-1: 0] adc_dat_proc;

// Calculate absolute value (two's complement conversion for negative numbers)
assign adc_dat_abs = adc_dat_i[DW-1] ? (~adc_dat_i + 1'b1) : adc_dat_i;

// Mux: If use_abs_i is 1, use absolute data. Otherwise, use raw data.
assign adc_dat_proc = use_abs_i ? adc_dat_abs : adc_dat_i;

always @(posedge adc_clk_i)
if (adc_rstn_i == 1'b0) begin
   adc_scht_p   <=  2'h0 ;
   adc_scht_n   <=  2'h0 ;
   adc_trig_p_o <=  1'b0 ;
   adc_trig_n_o <=  1'b0 ;
end else begin
   set_treshp <= set_tresh_i + set_hyst_i ; // calculate positive
   set_treshm <= set_tresh_i - set_hyst_i ; // and negative treshold

   if (adc_dv_i) begin
           // <-- MODIFIED: Now comparing against adc_dat_proc instead of adc_dat_i
           if ($signed(adc_dat_proc) >= $signed(set_tresh_i ))      adc_scht_p[0] <= 1'b1 ;  // treshold reached
      else if ($signed(adc_dat_proc) <  $signed(set_treshm  ))      adc_scht_p[0] <= 1'b0 ;  // wait until it goes under hysteresis
           if ($signed(adc_dat_proc) <= $signed(set_tresh_i ))      adc_scht_n[0] <= 1'b1 ;  // treshold reached
      else if ($signed(adc_dat_proc) >  $signed(set_treshp  ))      adc_scht_n[0] <= 1'b0 ;  // wait until it goes over hysteresis
   end

   adc_scht_p[1] <= adc_scht_p[0] ;
   adc_scht_n[1] <= adc_scht_n[0] ;

   adc_trig_p_o <= adc_scht_p[0] && !adc_scht_p[1] ; // make 1 cyc pulse 
   adc_trig_n_o <= adc_scht_n[0] && !adc_scht_n[1] ;
end

endmodule