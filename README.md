# Squeezenet


This repository implements Squeezenet NN taken from TFLite Hosted Model Page:

https://www.tensorflow.org/lite/guide/hosted_models


The build command is:

```
make clean all
```

To run on GVSOC

```
make run platform=gvsoc
```

And on a connected GAPUINO or other GAP development board:

```
make run
```

## Accuracy run on NNTool

| Quant Type | Calibration    | Top-1 Accuracy, % | Top-5 Accuracy, % |
|------------|----------------|-------------------|-------------------|
| TFLITE fp32| None           | 32.67             | 55.39             |
| NE16       | quant_data_ppm | 33.27             | 56.31             |
