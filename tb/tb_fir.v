`timescale 1ns / 1ps

module tb_fir;

    // 1. KHAI BÁO TÍN HIỆU
    reg clk;
    reg reset;
    reg signed [15:0] x_in;
    
    wire signed [35:0] y_out_dir;
    wire signed [35:0] y_out_trans;

    // 2. BIẾN QUẢN LÝ FILE
    integer in_file;
    integer out_file_dir;
    integer out_file_trans;
    integer scan_status;

    // 3. NHÚNG MẠCH DIRECT FORM VÀO TESTBENCH
    fir_direct dut_direct (
        .clk(clk),
        .reset(reset),
        .x_in(x_in),
        .y_out(y_out_dir)
    );

    // 4. NHÚNG MẠCH TRANSPOSED FORM VÀO TESTBENCH
    fir_transposed dut_transposed (
        .clk(clk),
        .reset(reset),
        .x_in(x_in),
        .y_out(y_out_trans)
    );

    // 5. TẠO XUNG ĐỒNG HỒ CLOCK (Tần số 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // BONUS: XUẤT FILE VCD ĐỂ ĐO CÔNG SUẤT ĐỘNG (QUARTUS)
    initial begin
        $dumpfile("fir_power_v1.vcd");
        $dumpvars(0, tb_fir); 
    end

    // 6. KỊCH BẢN CHẠY CHÍNH
    initial begin
        // Mở file đọc dữ liệu đầu vào (cùng thư mục)
        in_file = $fopen("input_data.txt", "r");
        
        // Tạo file mới để ghi kết quả đầu ra
        out_file_dir   = $fopen("output_direct.txt", "w");
        out_file_trans = $fopen("output_transposed.txt", "w");

        if (in_file == 0) begin
            $display("LỖI: Không tìm thấy file input_data.txt!");
            $finish;
        end

        // Khởi tạo trạng thái ban đầu (Reset mạch)
        reset = 1;
        x_in = 0;
        #20; 
        reset = 0; // Tắt reset, mạch bắt đầu chạy
        #10;

        // Vòng lặp: Đọc từng dòng file input_data.txt nhét vào mạch
        while (!$feof(in_file)) begin
            scan_status = $fscanf(in_file, "%d\n", x_in);
            @(posedge clk); // Đợi 1 nhịp đồng hồ
        end

        // Đợi thêm 16 nhịp Clock để toàn bộ dữ liệu trôi hết ra khỏi mạch
        repeat(16) @(posedge clk);

        // Đóng toàn bộ file và kết thúc mô phỏng
        $fclose(in_file);
        $fclose(out_file_dir);
        $fclose(out_file_trans);
        $display("MO PHONG HOAN TAT THANH CONG!");
        $finish;
    end

    // 7. GHI NHẬN KẾT QUẢ ĐẦU RA VÀO FILE TXT
    // Dùng sườn âm (negedge) để lấy mẫu tín hiệu đã ổn định
    always @(negedge clk) begin
        if (!reset) begin
            $fdisplay(out_file_dir, "%d", y_out_dir);
            $fdisplay(out_file_trans, "%d", y_out_trans);
        end
    end

endmodule