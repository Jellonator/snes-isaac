## Building

You must have Python 3 installed and in your PATH. Python is required for certain pre-processing steps, such as transforming image files into a format readable by the SNES.

You must also have the WLA-DX toolchain (https://github.com/vhelin/wla-dx) installed and in your PATH.

Finally, you just have the python libraries Pillow and pytiled_parser installed.

To build:

```
python scripts/assetimport.py
python scripts/roomimport.py
make
```

This will output a rom that can be executed in the bin directory

## Running

The game should be able to be run in any SNES emulator
