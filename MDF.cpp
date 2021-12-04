#include <iostream>
#include <fstream>
#include <algorithm>
using namespace std;

int nc = 100;
int nr = 100;
int L = 100;
int tmax = 3000;
int nx = nc * nr;
int nt = 500;

double dx = (double)L / (nx);
double dt = (double)tmax / (nt);
double alpha = 0.001 / 1000;
double r = alpha * dt / (dx * dx);
double r2 = 1 - 2 * r;

double t = 0;

double *u;

// void llenado()
// {
//     for (int i = 1; i < nx - 1; i++)
//     {
//         u[i] = 0;
//     }

//     u[0] = 1200;
//     u[nx - 1] = 300;
// }

void MDF()
{
    for (int m = 0; m < nt; m++)
    {
        t = t + dt;
        for (int i = 1; i < nx - 1; i++)
        {
            u[i] = r * u[i - 1] + r2 * u[i] + r * u[i + 1];
        }
    }
}

double *split(string s, int size)
{
    double *arr = new double[size];
    int occ = -1;
    int occ2 = 0;
    for (int i = 0; i < size; i++)
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
    return arr;
}

int main(int argc, char *argv[])
{
    ifstream file1(argv[1]);
    string line;
    int nline = 1;
    double *arr;
    int size = 0;
    if (!file1)
    {
        cout << "Please use $ ./MDA <file> " << endl;
    }
    else
    {
        // cout << file1.rdbuf() << endl;
        while (getline(file1, line))
        {
            cout << "-----" << endl;
            cout << line << endl;
            switch (nline)
            {
            case 1:
                nr = stoi(line);
                break;
            case 2:
                nc = stoi(line);
                break;
            case 3:
                dt = stod(line);
                break;
            case 4:
                dx = stod(line);
                break;
            case 5:
                
                size = std::count(line.begin(), line.end(), ',') + 1;
                arr = split(line, size);
                u = arr;
                nx = size;
                if (size > 0)
                {
                    cout << "funciona" << endl;
                    for (int j = 0; j < size; j++)
                    {
                        cout << j << ": " << arr[j] << endl;
                    }
                }
                break;
            case 6: alpha = stod(line);
            }
            nline++;
        }
        file1.close();
    }
    cout << "dt: " << dt << "  dx: " << dx << "  alpha: " << alpha << endl;
    //llenado();
    cout << "Inicial! " << u[nx/2] << endl;
    MDF();
    cout << "Final! " << u[nx/2] << endl;

    return 0;
}