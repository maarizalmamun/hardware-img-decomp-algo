# Hardware Image Decompression Algorithm

## Introduction

This project utilizes a Verilog Register Transfer Level hardware implementation to convert compressed bitstream data to its original uncompressed 320x240 pixel image. This project involves interfacing with various controllers (eg. VGA, UART), developing a state table to establish Finite State Machines to load data, perform matrix multiplication, and reading/writing data back to RAM given finite resources (RAM, Multiplication units).
