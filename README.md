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
