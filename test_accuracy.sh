#IMAGENET_PATH="/scratch/datasets/imagenet/val"
IMAGENET_PATH="/home/marco-gwt/Datasets/imagenet_val"

python model/test_imagenet_tflite.py model/squeezenet.tflite ${IMAGENET_PATH}
python model/test_imagenet_nntool.py model/squeezenet.tflite ${IMAGENET_PATH}
