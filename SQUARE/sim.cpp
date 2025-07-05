#include "Vgpu.h"
#include "verilated.h"
#include <fstream>
#include <iostream>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vgpu* gpu = new Vgpu;

    // Reset
    gpu->clk = 0;
    gpu->eval();
    gpu->clk = 1;
    gpu->eval();

    // Write phase
    int cycles = 0;
    while (!gpu->write_done && cycles < 200000) {
        gpu->clk = 0;
        gpu->eval();
        gpu->clk = 1;
        gpu->eval();
        cycles++;
        if (cycles % 1000 == 0) {
            std::cout << "Cycle " << cycles << ": counterX=" << gpu->counterX
                      << ", counterY=" << gpu->counterY
                      << ", pixel=" << std::hex << gpu->pixel << std::dec
                      << ", write_done=" << gpu->write_done << std::endl;
        }
    }
    std::cout << "Write phase completed after " << cycles << " cycles, write_done=" << gpu->write_done << std::endl;

    // Extra cycles to ensure writes settle
    for (int i = 0; i < 1000; i++) {
        gpu->clk = 0;
        gpu->eval();
        gpu->clk = 1;
        gpu->eval();
    }

    // Write BMP
    std::ofstream bmp("output.bmp", std::ios::binary);
    char header[54] = {
        'B', 'M',
        (char)(54 + 640 * 480 * 3), (char)((54 + 640 * 480 * 3) >> 8), (char)((54 + 640 * 480 * 3) >> 16), (char)((54 + 640 * 480 * 3) >> 24),
        0, 0, 0, 0,
        54, 0, 0, 0,
        40, 0, 0, 0,
        (char)640, (char)(640 >> 8), 0, 0,
        (char)480, (char)(480 >> 8), 0, 0,
        1, 0,
        24, 0,
        0, 0, 0, 0,
        (char)(640 * 480 * 3), (char)((640 * 480 * 3) >> 8), (char)((640 * 480 * 3) >> 16), (char)((640 * 480 * 3) >> 24),
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
    };
    bmp.write(header, 54);

    for (int y = 479; y >= 0; y--) {
        for (int x = 0; x < 640; x++) {
            gpu->counterX = x;
            gpu->counterY = y;
            gpu->clk = 0;
            gpu->eval();
            gpu->clk = 1;
            gpu->eval();
            char pixel[3] = {
                (char)(gpu->pixel & 0xFF),
                (char)((gpu->pixel >> 8) & 0xFF),
                (char)((gpu->pixel >> 16) & 0xFF)
            };
            bmp.write(pixel, 3);
            if (x >= 270 && x < 370 && y >= 190 && y < 290 && pixel[2] != (char)0xFF) {
                std::cout << "Pixel at (" << x << ", " << y << ") not red, got RGB("
                          << (unsigned int)(unsigned char)pixel[2] << ","
                          << (unsigned int)(unsigned char)pixel[1] << ","
                          << (unsigned int)(unsigned char)pixel[0] << ")" << std::endl;
            }
        }
    }
    gpu->counterX = 270;
    gpu->counterY = 190;
    gpu->clk = 0;
    gpu->eval();
    gpu->clk = 1;
    gpu->eval();
    std::cout << "Final pixel (270,190) = " << std::hex << gpu->pixel << std::dec << std::endl;
    bmp.close();
    delete gpu;
    return 0;
}