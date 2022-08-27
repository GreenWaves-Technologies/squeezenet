import numpy as np

def preprocess(img_data):
    IMAGE_MEAN = 127.5
    IMAGE_STD = 127.5
    norm_img_data = (img_data.astype(np.float32) - IMAGE_MEAN) / IMAGE_STD
    return norm_img_data
