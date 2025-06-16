import numpy as np
import random

#inputs
img_size = 128 # 128x128
template = [] # 3x3 , 8 bit unsigned
# numpy array
img = []  # 128x128, 8 bit unsigned (r,g,b)
num_of_actions = 0
IMG_LOWER_BOUND = 0
IMG_UPPER_BOUND = 255
MV_INTGER_LOWER_BOUND = 0
MV_INTGER_UPPER_BOUND = 117
MV_FRACTION_LOWER_BOUND = 0
MV_FRACTION_UPPER_BOUND = 15
PATTERN_NUM = 100
BIT_WIDTH = 8

random.seed(1234)

if __name__ == '__main__':
    with open('input.txt', 'w') as f:
        f.write(f"{PATTERN_NUM}\n\n")
        for i in range(PATTERN_NUM):

            img = np.zeros((2,img_size,img_size),dtype=np.uint8)

            # With each image size, generates L0 L1
            for img_num in range(2):
                for x in range(img_size):
                    for y in range(img_size):
                        img_pixel = random.randint(IMG_LOWER_BOUND,IMG_UPPER_BOUND)
                        f.write(f"{img_pixel} ")
                        img[img_num][x][y] = img_pixel

                    f.write("\n")

                f.write("\n")


            
            mv_set_integer = np.zeros((64,8),dtype=np.uint8)
            mv_set_fraction = np.zeros((64,8),dtype=np.uint8)

            # Repeats these actions 64 times for each pattern
            for num_of_act in range(64):
                for count_l0 in range(4):
                    mv_integer = random.randint(MV_INTGER_LOWER_BOUND, MV_INTGER_UPPER_BOUND)
                    f.write(f"{mv_integer} ")

                    if(mv_integer == 117):
                        mv_fraction = 0
                    else:
                        mv_fraction = random.randint(MV_INTGER_LOWER_BOUND, MV_FRACTION_UPPER_BOUND)
                    
                    f.write(f"{mv_fraction}\n")
                    mv_set_integer[num_of_act][count_l0] = mv_integer
                    mv_set_fraction[num_of_act][count_l0] = mv_fraction
                
                for count_l1 in range(4):
                    plus_or_minus = random.randint(0,1)
                    bias = random.randint(0,5)
                    
                    if(plus_or_minus):
                        if(mv_set_integer[num_of_act][count_l1] + bias > 117):
                            mv_integer = 117
                        else:
                            mv_integer = mv_set_integer[num_of_act][count_l1] + bias
                    else:
                        if(mv_set_integer[num_of_act][count_l1] - bias < 0):
                            mv_integer = 0
                        else:
                            mv_integer = mv_set_integer[num_of_act][count_l1] - bias

                    f.write(f"{mv_integer} ")

                    if(mv_integer == 117):
                        mv_fraction = 0
                    else:
                        mv_fraction = random.randint(MV_INTGER_LOWER_BOUND, MV_FRACTION_UPPER_BOUND)
                    
                    f.write(f"{mv_fraction}\n")
                    mv_set_integer[num_of_act][count_l1 + 4] = mv_integer
                    mv_set_fraction[num_of_act][count_l1 + 4] = mv_fraction

                f.write("\n")

            f.write("\n")
                    