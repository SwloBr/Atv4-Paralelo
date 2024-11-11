#include <iostream>
#include <vector>
#include <algorithm>
#include <cuda.h>

#define NTHREADS 256

// Função de kernel para calcular a contagem dos dígitos
__global__ void countDigitsKernel(int *d_arr, int *d_count, int n, int exp) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx < n) {
        int digit = (d_arr[idx] / exp) % 10;
        atomicAdd(&d_count[digit], 1);
    }
}

// Função de kernel para calcular a posição dos elementos (usando a contagem)
__global__ void prefixSumKernel(int *d_count) {
    for (int i = 1; i < 10; ++i) {
        d_count[i] += d_count[i - 1];
    }
}

// Função de kernel para ordenar os elementos
__global__ void reorderElementsKernel(int *d_arr, int *d_output, int *d_count, int n, int exp) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx < n) {
        int digit = (d_arr[idx] / exp) % 10;
        int pos = atomicSub(&d_count[digit], 1) - 1;
        d_output[pos] = d_arr[idx];
    }
}

// Função principal Radix Sort usando CUDA
void radixSortCUDA(std::vector<int>& arr) {
    int n = arr.size();
    int *d_arr, *d_output, *d_count;

    // Alocar memória na GPU
    cudaMalloc(&d_arr, n * sizeof(int));
    cudaMalloc(&d_output, n * sizeof(int));
    cudaMalloc(&d_count, 10 * sizeof(int));

    // Copiar os dados para a GPU
    cudaMemcpy(d_arr, arr.data(), n * sizeof(int), cudaMemcpyHostToDevice);

    // Encontrar o maior valor para determinar o número de dígitos
    int maxVal = *std::max_element(arr.begin(), arr.end());

    // Para cada dígito (unidade, dezena, centena, etc.)
    for (int exp = 1; maxVal / exp > 0; exp *= 10) {
        // Inicializar contagem
        cudaMemset(d_count, 0, 10 * sizeof(int));

        // Configurar número de blocos e threads
        int nBlocks = (n + NTHREADS - 1) / NTHREADS;

        // Contar os dígitos (Counting Sort)
        countDigitsKernel<<<nBlocks, NTHREADS>>>(d_arr, d_count, n, exp);
        cudaDeviceSynchronize();

        // Calcular prefix sum (exclusivo)
        prefixSumKernel<<<1, 1>>>(d_count);
        cudaDeviceSynchronize();

        // Reordenar os elementos
        reorderElementsKernel<<<nBlocks, NTHREADS>>>(d_arr, d_output, d_count, n, exp);
        cudaDeviceSynchronize();

        // Copiar o resultado temporário de volta para d_arr para a próxima iteração
        cudaMemcpy(d_arr, d_output, n * sizeof(int), cudaMemcpyDeviceToDevice);
    }

    // Copiar o resultado de volta para o host
    cudaMemcpy(arr.data(), d_arr, n * sizeof(int), cudaMemcpyDeviceToHost);

    // Liberar memória na GPU
    cudaFree(d_arr);
    cudaFree(d_output);
    cudaFree(d_count);
}

int main() {
    // Tamanhos dos arrays a serem testados
    std::vector<int> sizes = {100, 1000, 10000, 100000, 1000000};

    for (int size : sizes) {
        std::vector<int> arr(size);

        // Preencher o vetor com valores aleatórios
        srand(time(0));
        for (int i = 0; i < size; i++) {
            arr[i] = rand() % size;
        }

        // Medir o tempo de execução
        clock_t start = clock();
        radixSortCUDA(arr);
        clock_t end = clock();

        double elapsed = double(end - start) / CLOCKS_PER_SEC;
        std::cout << "Array de tamanho " << size << " ordenado em " << elapsed << " segundos (CUDA paralelo)." << std::endl;
    }

    return 0;
}
