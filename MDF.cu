#include <iostream>
#include <fstream>
#include <algorithm>
#include <vector>
#include "gnuplot-iostream.h"
#include <omp.h>
#include <chrono>
#include <stdio.h>
#include <cuda.h>

using namespace std;

// initial variables
int nc, nr, L, tmax, nx;
int nt = 10000;
int size = 0;
bool lleno = false;
double temp;
double dx, dt, alpha, r, r2, tempIzq, tempDer;

double t = 0;

double *u, *u_parallel;


__global__ void MDF_elem_op(double *uold, double *u, int nc_d, int nx_d, double r_d, double r2_d)
{
    int ar = threadIdx.x + blockIdx.x * blockDim.x;
    if(ar == 0){
        return;
    }
    if (ar + 1 < nx_d)
    {
        u[ar] = r_d * uold[ar - 1] + r2_d * uold[ar] + r_d * uold[ar + 1];
    }
    else
    {
        printf("ar: %d nx: %d \n", ar, nx_d);
    }
}

void MDF_parallel_cuda()
{
    long N = (nx-1);
    for (int m = 0; m < nt; m++)
    {
        t = t + dt;
        double *uold;
        double *u_d, *u_h;
        cudaMalloc((void **)&u_d, nx * sizeof(double));
        cudaMalloc((void **)&uold, nx * sizeof(double));
        cudaMemcpy(u_d, u, nx * sizeof(double), cudaMemcpyHostToDevice);
        cudaMemcpy(uold, u, nx * sizeof(double), cudaMemcpyHostToDevice);

        u_h = (double *)malloc(nx * sizeof(double));
        MDF_elem_op<<<(N) / 256, 256>>>(uold, u_d, nc, nx, r, r2);
        cudaMemcpy(u_h, u_d, nx * sizeof(double), cudaMemcpyDeviceToHost);

        memcpy(u, u_h, nx * sizeof(double));
        cudaFree(u_d);
        cudaFree(uold);
        free(u_h);
    }
}

// Finite differences method
void MDF()
{
    // cout << u[nx - 1] << endl;
    // #pragma omp parallel for
    for (int m = 0; m < nt; m++)
    {
        // Create a copy of u array using memcpy (from C)
        double uold[nx];
        memcpy(uold, u, nx * sizeof(double));
        t = t + dt;

        for (int j = 0; j < nr; j++)
        {
            int ar = (j * nc);
            for (int i = 1; i < nc - 1; i++)
            {

                if (ar + 1 < nx)
                {
                    u[ar + i] = r * uold[ar + i - 1] + r2 * uold[ar + i] + r * uold[ar + i + 1];
                }
                else
                {
                    cout << "i: " << i << "  j: " << j << endl;
                }
            }
        }
    }
}

void MDF_parallel()
{
    // cout << u_parallel[nx - 1] << endl;

    for (int m = 0; m < nt; m++)
    {
        // Create a copy of u array using memcpy (from C)
        double uold[nx];
        memcpy(uold, u_parallel, nx * sizeof(double));
        t = t + dt;
#pragma omp parallel for
        for (int j = 0; j < nr; j++)
        {
            int ar = (j * nc);
            for (int i = 1; i < nc - 1; i++)
            {

                if (ar + 1 < nx)
                {
                    u_parallel[ar + i] = r * uold[ar + i - 1] + r2 * uold[ar + i] + r * uold[ar + i + 1];
                }
                else
                {
                    cout << "i: " << i << "  j: " << j << endl;
                }
            }
        }
    }
}

double *split(string s, int size)
{
    double *arr = new double[size];
    int occ = -1;
    int occ2 = 0;
#pragma omp parallel for
    for (int i = 1; i < size - 1; i++)
    {
        if (i % nc == 0)
        {
            arr[i] = tempIzq;
        }
        else
        {
            if (i % nc - 1 == 0)
            {
                arr[i] = tempDer;
            }
            else
            {
                occ2 = s.find(",", occ + 1);

                if (occ2 != string::npos)
                {
                    arr[i] = stod(s.substr(occ + 1, occ2));
                }
                else
                {
                    arr[i] = stod(s.substr(occ + 1, s.length() - 1));
                }
                occ = occ2;
            }
        }
    }
    lleno = true;

    return arr;
}

double *llenado(double temp, int size)
{
    double *arr = new double[size];

    for (int j = 0; j < nr; j++)
    {
        int ar = (j * nc);
        arr[ar] = tempIzq;
        if (!lleno)
        {
            for (int i = 1; i < nc - 1; i++)
            {

                arr[ar + i] = temp;
            }
        }
        else
        {
            for (int i = 1; i < nc - 1; i++)
            {

                arr[ar + i] = u[ar + i];
            }
        }
        arr[ar + nc - 1] = tempDer;
    }
    lleno = true;
    return arr;
}

void graph(string filename, string title)
{
    Gnuplot gp;
    ofstream salida(filename);

    // std::vector<double> pts_X;
    // std::vector<double> pts_Y;
    // std::vector<double> pts_Z;

    for (int j = 0; j < nr; j++)
    {
        int ar = (j * nc);
        for (int i = 0; i < nc; i++)
        {
            // pts_X.push_back(i);
            // pts_Y.push_back(j);
            // pts_Z.push_back(u[ar + i]);
            salida << i << " " << j << " " << u[ar + i] << endl;
        }
    }

    salida.close();

    // gp << "set xrang[0:" << max(nr,nc) << "]" << "\n set yrang[0:" << max(nr,nc) << "]" << endl;
    // gp << "plot '-' with image title '" << title << "'" << endl;
    // gp.send1d(make_tuple(pts_X, pts_Y, pts_Z));
    // gp.clearTmpfiles();
}

int main(int argc, char *argv[])
{
    if (argc > 1)
    {
        ifstream inputFile(argv[1]);
        string line;
        int nline = 1;
        double *arr;

        if (!inputFile)
        {
            cout << "Please use $ ./MDA <file> or verify filename" << endl;
            cout << "File format:\n     nrows\n     ncolumns\n     dt\n     dx\n     u\n     alpha(or k)" << endl;
        }
        else
        {

            while (getline(inputFile, line))
            {
                switch (nline)
                {
                case 1:
                    try
                    {
                        nr = stoi(line);
                    }
                    catch (invalid_argument e)
                    {
                        cout << "Please provide a valid file format: error in number of rows, provide a int" << endl;
                        exit(1);
                    }

                    break;
                case 2:
                    try
                    {
                        nc = stoi(line);
                    }
                    catch (invalid_argument e)
                    {
                        cout << "Please provide a valid file format: error in number of columns, provide a int" << endl;
                        exit(1);
                    }

                    break;
                case 3:
                    try
                    {
                        dt = stod(line);
                    }
                    catch (invalid_argument e)
                    {
                        cout << "Please provide a valid file format: error in number of columns, provide a int" << endl;
                        exit(1);
                    }

                    break;
                case 4:
                    try
                    {
                        dx = stod(line);
                    }
                    catch (invalid_argument e)
                    {
                        cout << "Please provide a valid file format: error in number of columns, provide a int" << endl;
                        exit(1);
                    }

                    break;
                case 5:
                    if (argc > 2)
                    {
                        if (!strcmp(argv[2], "--array"))
                        {
                            size = std::count(line.begin(), line.end(), ',') + 3;
                            if (size > 0)
                            {
                                arr = split(line, size);
                                u = arr;
                                nx = size;
                            }
                            else
                            {
                                cout << "Please provide a valid file format: error in U vector" << endl;
                            }
                        }
                    }
                    else
                    {
                        try
                        {
                            size = nr * nc;
                            nx = size;
                            temp = stod(line);
                        }
                        catch (invalid_argument e)
                        {
                            cout << "Please provide a valid file format: error in initial temperature, provide a float" << endl;
                            exit(1);
                        }
                    }
                    break;
                case 6:
                    try
                    {
                        tempIzq = stod(line);
                    }
                    catch (invalid_argument e)
                    {
                        cout << "Please provide a valid file format: error in number of columns, provide a int" << endl;
                        exit(1);
                    }

                    break;
                case 7:
                    try
                    {
                        tempDer = stod(line);
                    }
                    catch (invalid_argument e)
                    {
                        cout << "Please provide a valid file format: error in number of columns, provide a int" << endl;
                        exit(1);
                    }

                    break;
                case 8:
                    try
                    {
                        alpha = stod(line);
                    }
                    catch (invalid_argument e)
                    {
                        cout << "Please provide a valid file format: error in number of columns, provide a int" << endl;
                        exit(1);
                    }
                    break;
                }
                nline++;
            }
            u = llenado(temp, size);
            u[0] = tempIzq;
            u[nx - 1] = tempDer;
            u_parallel = new double[nx];
            memcpy(u_parallel, u, nx * sizeof(double));
            r = alpha * dt / (dx * dx);
            r2 = 1 - 2 * r;
            inputFile.close();
            cout << "nc: " << nc << "  nr: " << nr << "  nx: " << nx << "  dt: " << dt << "  dx: " << dx << "  alpha: " << alpha << endl;
            graph("input", "Estado Inicial");
            auto start = std::chrono::high_resolution_clock::now();
            MDF();
            auto stop = std::chrono::high_resolution_clock::now();
            auto duration = std::chrono::duration_cast<std::chrono::microseconds>(stop - start);
            // // graph("output", "Estado Final");
            std::cout << "Duracion Single-Core: " << duration.count() << std::endl;

            auto start1 = std::chrono::high_resolution_clock::now();
            MDF_parallel();
            auto stop1 = std::chrono::high_resolution_clock::now();
            auto duration1 = std::chrono::duration_cast<std::chrono::microseconds>(stop1 - start1);
            std::cout << "Duracion "<< omp_get_max_threads() << " Cores: " << duration1.count() << std::endl;

            auto startCuda = std::chrono::high_resolution_clock::now();
            MDF_parallel_cuda();
            auto stopCuda = std::chrono::high_resolution_clock::now();
            auto durationCuda = std::chrono::duration_cast<std::chrono::microseconds>(stopCuda - startCuda);
            std::cout << "Duracion CUDA: " << durationCuda.count() << std::endl;
            graph("output", "Estado Final");
            // std::cout << "Duracion " << omp_get_max_threads() << " cores: " << duration1.count() << std::endl;

            cout << "Finished :D" << endl;
        }
    }
    else
    {

        cout << "Please use $ ./MDA <file> " << endl;
        cout << "File format:\n     nrows\n     ncolumns\n     dt\n     dx\n     u\n     alpha(or k)" << endl;
    }

    return 0;
}