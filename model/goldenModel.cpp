#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>

#define KERNEL_SIZE 3
#define IMAGE_SIZE 5

int main(void) {
  int image[IMAGE_SIZE][IMAGE_SIZE];
  int kernel[KERNEL_SIZE][KERNEL_SIZE];

  // image initialisation
  image[0][0] = 2;
  image[0][1] = 0;
  image[0][2] = 3;
  image[0][3] = 2;
  image[0][4] = 4;
  image[1][0] = 1;
  image[1][1] = 2;
  image[1][2] = 5;
  image[1][3] = 4;
  image[1][4] = 2;
  image[2][0] = 1;
  image[2][1] = 5;
  image[2][2] = 2;
  image[2][3] = 4;
  image[2][4] = 3;
  image[3][0] = 1;
  image[3][1] = 2;
  image[3][2] = 3;
  image[3][3] = 5;
  image[3][4] = 2;
  image[4][0] = 4;
  image[4][1] = 1;
  image[4][2] = 5;
  image[4][3] = 4;
  image[4][4] = 3;

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

  // convolution
  int outputSize = IMAGE_SIZE - KERNEL_SIZE + 1;
  int convSum[outputSize * outputSize];
  int kernelSum = 0;
  int convNum = 0;
  for (int rowShift = 0; rowShift < IMAGE_SIZE - KERNEL_SIZE + 1; rowShift++) {
    for (int colShift = 0; colShift < IMAGE_SIZE - KERNEL_SIZE + 1;
         colShift++) {
      for (int row = 0; row < KERNEL_SIZE; row++) {
        for (int col = 0; col < KERNEL_SIZE; col++) {
          kernelSum += image[row + rowShift][col + colShift] * kernel[row][col];
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

  std::ofstream imageFile("image.hex");
  std::ofstream goldenFile("golden.hex");

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

  return 0;
}