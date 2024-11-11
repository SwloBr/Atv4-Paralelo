#include <iostream>
#include <vector>
#include <algorithm>
#include <ctime>
#include <cstdlib>

// Função Counting Sort para um dígito específico
void countingSort(std::vector<int>& arr, int exp) {
    int n = arr.size();
    std::vector<int> output(n);
    int count[10] = {0};

    // Contar a ocorrência de cada dígito
    for (int i = 0; i < n; i++) {
        int index = (arr[i] / exp) % 10;
        count[index]++;
    }

    // Atualizar count[i] para conter a posição do próximo elemento
    for (int i = 1; i < 10; i++) {
        count[i] += count[i - 1];
    }

    // Construir o array de saída
    for (int i = n - 1; i >= 0; i--) {
        int index = (arr[i] / exp) % 10;
        output[count[index] - 1] = arr[i];
        count[index]--;
    }

    // Copiar o resultado para o array original
    for (int i = 0; i < n; i++) {
        arr[i] = output[i];
    }
}

// Função principal Radix Sort
void radixSort(std::vector<int>& arr) {
    // Encontrar o maior número
    int maxVal = *std::max_element(arr.begin(), arr.end());

    // Aplicar counting sort para cada dígito
    for (int exp = 1; maxVal / exp > 0; exp *= 10) {
        countingSort(arr, exp);
    }
}

int main() {
    // Inicializar a semente do gerador de números aleatórios apenas uma vez
    srand(time(0));

    // Tamanhos dos arrays a serem testados
    std::vector<int> sizes = {100, 1000, 10000, 100000, 1000000, 10000000, 100000000};

    for (int size : sizes) {
        std::vector<int> arr(size);

        // Preencher o vetor com valores aleatórios positivos
        for (int i = 0; i < size; i++) {
            arr[i] = rand() % size; // Gera números entre 0 e (size - 1)
        }

        // Medir o tempo de execução
        clock_t start = clock();
        radixSort(arr);
        clock_t end = clock();

        double elapsed = double(end - start) / CLOCKS_PER_SEC;
        std::cout << "Array de tamanho " << size << " ordenado em " << elapsed << " segundos." << std::endl;
    }

    return 0;
}
