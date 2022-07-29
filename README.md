# BenchmarkVINO

## 1. Install requirements

```bash
pip install -r requirements.txt
```

## 2. Run benchmark

The command to run benchmark:

```bash
bash run_benchmark.sh ${inference_dir}
```

About the above command, the The directory `${inference_model_dir}` should contain the Paddle Inference model files:

```
inference_std
├── model_list.txt
├── PPLCNet_x0_25
│   ├── inference.pdiparams
│   ├── inference.pdiparams.info
│   └── inference.pdmodel
├── PPLCNet_x0_35
│   ├── inference.pdiparams
│   ├── inference.pdiparams.info
│   └── inference.pdmodel
├── PPLCNet_x0_5
│   ├── inference.pdiparams
│   ├── inference.pdiparams.info
│   └── inference.pdmodel
└── PPLCNet_x0_75
    ├── inference.pdiparams
    ├── inference.pdiparams.info
    └── inference.pdmodel
```

And the `model_list.txt` should describe the models to be tested:

```
PPLCNet_x0_25
PPLCNet_x0_35
PPLCNet_x0_5
PPLCNet_x0_75
```

