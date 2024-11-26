using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FractalCSharpLib
{
    public class JuliaFractalCSharp
    {
        public static byte[,] GenerateFractal(double re, double im, int iterations, int width, int height, int threads)
        {
            byte[,] result = new byte[width, height];

            // Skalowanie (przekształcenie współrzędnych pikseli na przestrzeń zespoloną)
            double scaleX = 3.0 / width;  // Zakres rzeczywistej części (-1.5 do +1.5)
            double scaleY = 2.0 / height; // Zakres urojonej części (-1.0 do +1.0)

            // Środek prostokąta
            double centerX = width / 2.0;
            double centerY = height / 2.0;

            // Podział pracy na segmenty (każdy wątek przetwarza fragment obrazu)
            int segmentHeight = height / threads; // Wysokość przetwarzana przez każdy wątek

            Parallel.For(0, threads, threadIndex =>
            {
                // Zakres pracy dla danego wątku
                int startY = threadIndex * segmentHeight;
                int endY = (threadIndex == threads - 1) ? height : startY + segmentHeight;

                for (int y = startY; y < endY; y++)
                {
                    for (int x = 0; x < width; x++)
                    {
                        // Przesunięcie układu współrzędnych względem środka prostokąta
                        double zx = (x - centerX) * scaleX;
                        double zy = (y - centerY) * scaleY;

                        int i = 0;
                        while (zx * zx + zy * zy < 4 && i < iterations)
                        {
                            double temp = zx * zx - zy * zy + re;
                            zy = 2.0 * zx * zy + im;
                            zx = temp;
                            i++;
                        }

                        // Przekształcenie liczby iteracji na wartość koloru (0–255)
                        result[x, y] = (byte)(i * 255 / iterations);
                    }
                }
            });

            return result;
        }
    }
}
