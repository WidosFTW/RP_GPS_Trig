module gps_ts_engine (
    input wire clk,           // 125MHz ADC clock
    input wire rst_n,
    input wire pps_in,        // Physical PPS pin from GPS
    input wire [31:0] set_sec,// From AXI Register (The "Next Second")
    output reg [31:0] cur_sec,
    output reg [26:0] cur_subsec, // Counts up to 125,000,000
    input wire trigger_in,
    output reg [58:0] latched_ts  // Full timestamp when trigger hits
);

    reg pps_d;
    wire pps_edge = pps_in && !pps_d; // Rising edge detect

    always @(posedge clk) begin
        if (!rst_n) begin
            cur_sec <= 0;
            cur_subsec <= 0;
        end else begin
            pps_d <= pps_in;

if (pps_edge) begin
                cur_sec <= set_sec;    // Sync to true GPS Second
                cur_subsec <= 0;       // Reset sub-second counter
            end else begin
                // ALLOW OVERSHOOT! 
                // 137,499,999 gives us a massive 10% tolerance for a fast clock.
                // It will only auto-reset here if the physical PPS pulse is completely dead/missing.
                if (cur_subsec >= 137499999) begin
                    cur_subsec <= 0;
                    cur_sec <= cur_sec + 1; // Freewheel increment since PPS is lost
                end else begin
                    cur_subsec <= cur_subsec + 1;
                end
            end
            // Latch logic for your ADC trigger
            if (trigger_in) begin
                latched_ts <= {cur_sec, cur_subsec};
            end
        end
    end
endmodule