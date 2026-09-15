#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <string>

#define KERNEL_SIZE 3
#define IMAGE_SIZE 5
#define NUM_ITERATIONS 100

int main(void) {
  int kernel[KERNEL_SIZE][KERNEL_SIZE];

  // kernel initialisation
  kernel[0][0] = 5;
  kernel[0][1] = 6;
  kernel[0][2] = 8;
  kernel[1][0] = 3;
  kernel[1][1] = 4;
  kernel[1][2] = 1;
  kernel[2][0] = 9;
  kernel[2][1] = 1;
  kernel[2][2] = 12;

  // Image generation

  std::random_device rd;
  unsigned int seed = rd();
  std::mt19937 rng(seed);
  std::uniform_int_distribution<int> pixelDist(0, 255);  // PIXEL_WIDTH = 8 bits

  std::cout << "seed: " << seed << std::endl;

  int outputSize = IMAGE_SIZE - KERNEL_SIZE + 1;

  for (int iter = 0; iter < NUM_ITERATIONS; iter++) {
    int image[IMAGE_SIZE][IMAGE_SIZE];

    // randomize the image
    for (int row = 0; row < IMAGE_SIZE; row++) {
      for (int col = 0; col < IMAGE_SIZE; col++) {
        image[row][col] = pixelDist(rng);
      }
    }

    // convolution
    int convSum[outputSize * outputSize];
    int kernelSum = 0;
    int convNum = 0;
    for (int rowShift = 0; rowShift < IMAGE_SIZE - KERNEL_SIZE + 1;
         rowShift++) {
      for (int colShift = 0; colShift < IMAGE_SIZE - KERNEL_SIZE + 1;
           colShift++) {
        for (int row = 0; row < KERNEL_SIZE; row++) {
          for (int col = 0; col < KERNEL_SIZE; col++) {
            kernelSum +=
                image[row + rowShift][col + colShift] * kernel[row][col];
          }
        }
        convSum[convNum] = kernelSum;
        kernelSum = 0;
        convNum++;
      }
    }

    // print sum
    for (int i = 0; i < convNum; i++) {
      printf("%d\n", convSum[i]);
    }

    // indexed files for iteration
    std::string imageFileName = "image" + std::to_string(iter) + ".hex";
    std::string goldenFileName = "golden" + std::to_string(iter) + ".hex";

    std::ofstream imageFile(imageFileName);
    std::ofstream goldenFile(goldenFileName);

    for (int row = 0; row < IMAGE_SIZE; row++) {
      for (int col = 0; col < IMAGE_SIZE; col++) {
        imageFile << std::setw(2) << std::setfill('0') << std::hex
                  << image[row][col] << '\n';
      }
    }

    for (int i = 0; i < convNum; i++) {
      uint32_t masked = static_cast<uint32_t>(convSum[i]) & 0xFFFFF;
      goldenFile << std::setw(5) << std::setfill('0') << std::hex << masked
                 << '\n';
    }
  }

  return 0;
}