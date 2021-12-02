#include <iostream>
//#include <Python.h>
using namespace std;

int L = 100;
int tmax = 100;
int nx = 401;
int nt = 5000;

double dx = (double)L / (nx - 1);
double dt = (double)tmax / (nt - 1);
double alpha = 0.001 / 1000;
double r = alpha * dt / (dx * dx);
double r2 = 1 - 2 * r;

double t = 0;

double *u = new double[nx - 1];

void llenado()
{
    for (int i = 0; i < nx - 1; i++)
    {
        if (i % 5 == 0)
        {
            u[i] = (double)1200;
        }
        else
        {
            u[i] = (double)300;
        }
    }
}

void proceso()
{
    for (int m = 0; m < nt; m++)
    {
        t = t + dt;
        for (int i = 1; i < nx - 2; i++)
        {
            u[i] = r * u[i - 1] + r2 * u[i] + r * u[i + 1];
        }
    }
}

int main()
{
    llenado();
    cout << "Inicial!" << u[43] << endl;
    proceso();
    cout << "FInal!" << u[43] << endl;

    return 0;
}