import functions
import numpy as np
import utils
#%%

#inputs
img_size = 128 # 128x128
template = [] # 3x3 , 8 bit unsigned
# numpy array
img = []  # 128x128, 8 bit unsigned (r,g,b)
mv_set_integer = []
mv_set_fraction = []
num_of_set = 64
PAT_NUM = 0

num_of_actions_list = []
opt_list = []

# delete output.txt
open('output_float.txt', 'w').close()
open('output_int.txt', 'w').close()

def run(img, mv_set_integer, mv_set_fraction):
    L0 = img[0,:,:]
    L1 = img[1,:,:]

    sad_p1 = []
    sad_p2 = []
    # Perform the actions on the image
    with open('output_float.txt', 'a') as file ,open('output_int.txt', 'a') as file1:
        for idx in range(64):
            # L0
            mvx_l0 = utils.reconstruct_mv(mv_set_integer[idx][0], mv_set_fraction[idx][0])  # MVx
            mvy_l0 = utils.reconstruct_mv(mv_set_integer[idx][1], mv_set_fraction[idx][1])  # MVy
            
            # L1
            mvx_l1 = utils.reconstruct_mv(mv_set_integer[idx][2], mv_set_fraction[idx][2])  # MVx
            mvy_l1 = utils.reconstruct_mv(mv_set_integer[idx][3], mv_set_fraction[idx][3])  # MVy

            sad_p1 = functions.mirror_mvd_matching(L0, L1, mvx_l0, mvy_l0, mvx_l1, mvy_l1, 1)
            
            
            min_sad = min(sad_p1)
            min_idx = sad_p1.index(min_sad)
            file.write(f"{min_idx} {min_sad} ")
            
            sad_p1 = functions.mirror_mvd_matching(L0, L1, mvx_l0, mvy_l0, mvx_l1, mvy_l1, 0)
            
            min_sad = min(sad_p1)
            min_idx = sad_p1.index(min_sad)
            file1.write(f"{min_idx} {min_sad} ")
                
            mvx_l0 = utils.reconstruct_mv(mv_set_integer[idx][4], mv_set_fraction[idx][4])  # MVx
            mvy_l0 = utils.reconstruct_mv(mv_set_integer[idx][5], mv_set_fraction[idx][5])  # MVy
            
            # L1
            mvx_l1 = utils.reconstruct_mv(mv_set_integer[idx][6], mv_set_fraction[idx][6])  # MVx
            mvy_l1 = utils.reconstruct_mv(mv_set_integer[idx][7], mv_set_fraction[idx][7])  # MVy

            sad_p2 = functions.mirror_mvd_matching(L0, L1, mvx_l0, mvy_l0, mvx_l1, mvy_l1, 1)

            min_sad = min(sad_p2)
            min_idx = sad_p2.index(min_sad)
            file.write(f"{min_idx} {min_sad}\n")
            
            sad_p2 = functions.mirror_mvd_matching(L0, L1, mvx_l0, mvy_l0, mvx_l1, mvy_l1, 0)

            min_sad = min(sad_p2)
            min_idx = sad_p2.index(min_sad)
            file1.write(f"{min_idx} {min_sad}\n")
                
            
        file.write("\n")
        file1.write("\n")
            

# Read the input file into a list of strings
with open('input.txt', 'r') as file1:
    # read in pattern number and convert to integer then jump over empty line
    PAT_NUM = int(file1.readline())
    file1.readline()

    for _ in range(PAT_NUM):
        img = np.zeros((2, img_size, img_size), dtype=int)
        for img_num in range(2):
            for x in range(img_size):
                line = file1.readline().strip()  # 讀一行並去掉換行符號
                values = list(map(int, line.split()))  # 把每個 pixel 字串轉成整數
                for y in range(img_size):
                    img[img_num][x][y] = values[y]
            file1.readline()  # 讀掉每張影像之間的空行

        mv_set_integer = np.zeros((64, 8), dtype=np.uint8)
        mv_set_fraction = np.zeros((64, 8), dtype=np.uint8)

        for num_of_act in range(64):
            for i in range(8):  # 8 entries per group
                line = file1.readline().strip()  # 例如 "42 7"
                values = list(map(int, line.split()))
                mv_set_integer[num_of_act][i] = values[0]
                mv_set_fraction[num_of_act][i] = values[1]

            file1.readline()  # 跳過每組之間的空行

        file1.readline()

        run(img, mv_set_integer, mv_set_fraction)


#%%
