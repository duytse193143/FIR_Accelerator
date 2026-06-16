module fir_direct (
    input  wire                 clk,
    input  wire                 reset,
    input  wire signed [15:0]   x_in,    
    output reg  signed [35:0]   y_out    
);

    // ==========================================================
    // 1. KHAI BÁO HỆ SỐ BỘ LỌC (Đã lấy từ file coeffs.txt)
    // ==========================================================
    localparam signed [15:0] H0  = -16'sd114;
    localparam signed [15:0] H1  = -16'sd159;
    localparam signed [15:0] H2  = -16'sd139;
    localparam signed [15:0] H3  =  16'sd291;
    localparam signed [15:0] H4  =  16'sd1450;
    localparam signed [15:0] H5  =  16'sd3284;
    localparam signed [15:0] H6  =  16'sd5246;
    localparam signed [15:0] H7  =  16'sd6524;
    localparam signed [15:0] H8  =  16'sd6524;
    localparam signed [15:0] H9  =  16'sd5246;
    localparam signed [15:0] H10 =  16'sd3284;
    localparam signed [15:0] H11 =  16'sd1450;
    localparam signed [15:0] H12 =  16'sd291;
    localparam signed [15:0] H13 = -16'sd139;
    localparam signed [15:0] H14 = -16'sd159;
    localparam signed [15:0] H15 = -16'sd114;

    // ==========================================================
    // 2. MẠNG THANH GHI DỊCH (Shift Registers / Delay Line)
    // ==========================================================
    reg signed [15:0] delay_line [0:15];
    integer i;

    // ==========================================================
    // 3. KHỐI TÍNH TOÁN (Đồng bộ theo xung nhịp Clock)
    // ==========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                delay_line[i] <= 16'd0;
            end
            y_out <= 36'd0;
        end else begin
            // A. DỊCH DỮ LIỆU
            delay_line[0] <= x_in;
            for (i = 1; i < 16; i = i + 1) begin
                delay_line[i] <= delay_line[i-1];
            end

            // B. NHÂN VÀ CỘNG DỒN (MAC)
            y_out <= (delay_line[0]  * H0)  +
                     (delay_line[1]  * H1)  +
                     (delay_line[2]  * H2)  +
                     (delay_line[3]  * H3)  +
                     (delay_line[4]  * H4)  +
                     (delay_line[5]  * H5)  +
                     (delay_line[6]  * H6)  +
                     (delay_line[7]  * H7)  +
                     (delay_line[8]  * H8)  +
                     (delay_line[9]  * H9)  +
                     (delay_line[10] * H10) +
                     (delay_line[11] * H11) +
                     (delay_line[12] * H12) +
                     (delay_line[13] * H13) +
                     (delay_line[14] * H14) +
                     (delay_line[15] * H15);
        end
    end

endmodule