import numpy as np
from scipy import signal

# ==========================================
# 1. THÔNG SỐ CƠ BẢN
# ==========================================
N_TAPS = 16
FS = 1000  # Tần số lấy mẫu (Hz)
FC = 100   # Tần số cắt tần số thấp (Hz)

# ==========================================
# 2. THIẾT KẾ BỘ LỌC FIR (FLOATING-POINT)
# ==========================================
# Sử dụng cửa sổ Hamming để tạo hệ số h[n] lý tưởng
h_float = signal.firwin(N_TAPS, FC, fs=FS, window='hamming')

# ==========================================
# 3. LƯỢNG TỬ HÓA SANG SỐ NGUYÊN (FIXED-POINT 16-BIT)
# ==========================================
# Tỷ lệ với 2^15 - 1 để dùng hết dải động của số nguyên có dấu 16-bit
SCALE_FACTOR = 32767 
h_fixed = np.round(h_float * SCALE_FACTOR).astype(int)

# ==========================================
# 4. TẠO TÍN HIỆU ĐẦU VÀO (TEST VECTORS)
# ==========================================
# Tạo 200 mẫu dữ liệu
t = np.arange(200) / FS

# Tín hiệu sạch (20Hz) cần giữ lại + Nhiễu tần số cao (300Hz) cần lọc bỏ
signal_clean = 0.5 * np.sin(2 * np.pi * 20 * t) 
signal_noise = 0.5 * np.sin(2 * np.pi * 300 * t)
x_float = signal_clean + signal_noise

# Lượng tử hóa tín hiệu đầu vào
x_fixed = np.round(x_float * SCALE_FACTOR).astype(int)

# ==========================================
# 5. MÔ PHỎNG PHẦN CỨNG (TẠO GOLDEN OUTPUT)
# ==========================================
# Dùng hàm lfilter để cho tín hiệu đi qua bộ lọc
# Mảng y_fixed này chính là kết quả lý tưởng mà Verilog bắt buộc phải tính ra được
y_fixed = signal.lfilter(h_fixed, 1.0, x_fixed).astype(np.int64)

# ==========================================
# 6. XUẤT DỮ LIỆU RA TỆP TIN (FILE I/O)
# ==========================================
def write_to_file(filename, data):
    with open(filename, 'w') as f:
        for val in data:
            f.write(f"{val}\n")

write_to_file('input_data.txt', x_fixed)
write_to_file('coeffs.txt', h_fixed)
write_to_file('golden_output.txt', y_fixed)

print("Đã tạo thành công: input_data.txt, coeffs.txt, golden_output.txt")