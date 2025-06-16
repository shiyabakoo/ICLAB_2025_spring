import numpy as np

def four_bit_to_fraction(bits_4bit: int) -> float:

    if not (0 <= bits_4bit <= 15):
        raise ValueError("輸入值必須是 0 到 15 的整數（4-bit）")

    return bits_4bit / 16.0

def bilinear_interpolation_block(mvx: int, mvy: int, ref_frame: np.ndarray) -> np.ndarray:
    # 取得起始座標（整數位元）
    x_int = (mvx >> 4)  # MVx[11:4]
    y_int = (mvy >> 4)  # MVy[11:4]

    # 取得小數位元（比例）
    x_frac = four_bit_to_fraction(mvx & 0b1111)  # MVx[3:0]
    y_frac = four_bit_to_fraction(mvy & 0b1111)  # MVy[3:0]

    bi_block = np.zeros((8, 8), dtype=np.float32)

    for i in range(8):
        for j in range(8):
            # 每一個 BI(i,j) 的實際參考位置 = 起始座標 + i, j
            y = y_int + i
            x = x_int + j

            # 取得 4 個鄰近像素
            top_left     = ref_frame[y][x]
            top_right    = ref_frame[y][x + 1]
            bottom_left  = ref_frame[y + 1][x]
            bottom_right = ref_frame[y + 1][x + 1]

            # 水平插值
            a1 = top_left + (top_right - top_left) * x_frac
            a2 = bottom_left + (bottom_right - bottom_left) * x_frac

            # 垂直插值
            b = a1 + (a2 - a1) * y_frac

            # 存入 BI 區塊
            bi_block[i][j] = b

    return bi_block

def compute_sad_int(block1: np.ndarray, block2: np.ndarray) -> int:
    return np.sum(np.abs(block1.astype(np.int16) - block2.astype(np.int16)))
def compute_sad_float(block1: np.ndarray, block2: np.ndarray) -> float:
    return np.sum(np.abs(block1.astype(np.float32) - block2.astype(np.float32)))

def mirror_mvd_matching(L0: np.ndarray, L1: np.ndarray,
                        mvx_l0: int, mvy_l0: int,
                        mvx_l1: int, mvy_l1: int, option: bool) -> list:
    SAD_list = []
    for idx in range(9):
        dy = idx % 3   # 0, 1, 2
        dx = idx // 3    # 0, 1, 2

        # L0: 向右下偏移 (dx, dy)
        y0 = mvy_l0 + (dy << 4)
        x0 = mvx_l0 + (dx << 4)

        # L1: 對稱鏡射，從 (x+2, y+2) 向左上偏移 (2-dx, 2-dy)
        y1 = mvy_l1 + ((2 - dy) << 4)
        x1 = mvx_l1 + ((2 - dx) << 4)

        block_l0 = bilinear_interpolation_block(x0, y0, L0)
        block_l1 = bilinear_interpolation_block(x1, y1, L1)

        if block_l0.shape != (8, 8) or block_l1.shape != (8, 8):
            # 避免邊界錯誤
            SAD_list.append(np.inf)
            continue

        #sad = compute_sad_int(block_l0, block_l1)
        sad_float = compute_sad_float(block_l0, block_l1)
        sad_int = float_to_fixed_hex(sad_float,8,24)
        if(option):
            SAD_list.append(sad_float)
        else:
            SAD_list.append(sad_int)

    return SAD_list

def float_to_fixed_hex(val: float, frac_bits: int = 4, total_bits: int = 16) -> hex:
    """
    將浮點數轉為 fixed-point 格式的十六進位字串
    預設為 Q(16-frac_bits).(frac_bits)，例如 Q12.4
    """
    scale = 1 << frac_bits  # = 2^frac_bits
    int_val = int(round(val * scale))

    # 飽和處理
    max_val = (1 << total_bits) - 1
    int_val = max(0, min(int_val, max_val))

    hex_str = int_val # 每4位bit一個hex位
    return hex_str



