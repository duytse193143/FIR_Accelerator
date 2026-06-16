module fir_transposed (
    input  wire                 clk,
    input  wire                 reset,
    input  wire signed [15:0]   x_in,
    output reg  signed [35:0]   y_out
);

    // ==========================================================
    // 1. KHAI BÁO HỆ SỐ (Đảo ngược: Đi lùi từ H15 về H0)
    // ==========================================================
    localparam signed [15:0] H15 = -16'sd114;
    localparam signed [15:0] H14 = -16'sd159;
    localparam signed [15:0] H13 = -16'sd139;
    localparam signed [15:0] H12 =  16'sd291;
    localparam signed [15:0] H11 =  16'sd1450;
    localparam signed [15:0] H10 =  16'sd3284;
    localparam signed [15:0] H9  =  16'sd5246;
    localparam signed [15:0] H8  =  16'sd6524;
    localparam signed [15:0] H7  =  16'sd6524;
    localparam signed [15:0] H6  =  16'sd5246;
    localparam signed [15:0] H5  =  16'sd3284;
    localparam signed [15:0] H4  =  16'sd1450;
    localparam signed [15:0] H3  =  16'sd291;
    localparam signed [15:0] H2  = -16'sd139;
    localparam signed [15:0] H1  = -16'sd159;
    localparam signed [15:0] H0  = -16'sd114;

    // ==========================================================
    // 2. TẠO CÁC THANH GHI CỘNG DỒN (Accumulators / Delay Registers)
    // ==========================================================
    // Cần 15 thanh ghi trung gian (từ acc_0 đến acc_14) đóng vai trò Z^-1
    reg signed [35:0] acc [0:14];
    integer i;

    // ==========================================================
    // 3. KHỐI TÍNH TOÁN TRANSPOSED (Tuyến đường dích dắc)
    // ==========================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 15; i = i + 1) begin
                acc[i] <= 36'd0;
            end
            y_out <= 36'd0;
        end else begin
            // Trạm đầu tiên bên trái (Chỉ có nhân, rót thẳng vào Z^-1)
            acc[0] <= x_in * H15;

            // Các trạm ở giữa: [Kết quả Z^-1 trạm trước] + [Nhân dội từ trên xuống]
            acc[1]  <= acc[0]  + (x_in * H14);
            acc[2]  <= acc[1]  + (x_in * H13);
            acc[3]  <= acc[2]  + (x_in * H12);
            acc[4]  <= acc[3]  + (x_in * H11);
            acc[5]  <= acc[4]  + (x_in * H10);
            acc[6]  <= acc[5]  + (x_in * H9);
            acc[7]  <= acc[6]  + (x_in * H8);
            acc[8]  <= acc[7]  + (x_in * H7);
            acc[9]  <= acc[8]  + (x_in * H6);
            acc[10] <= acc[9]  + (x_in * H5);
            acc[11] <= acc[10] + (x_in * H4);
            acc[12] <= acc[11] + (x_in * H3);
            acc[13] <= acc[12] + (x_in * H2);
            acc[14] <= acc[13] + (x_in * H1);

            // Trạm cuối cùng bên phải (Xuất thẳng ra y_out)
            y_out   <= acc[14] + (x_in * H0);
        end
    end

endmodule