using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace FractalAsmLib
{
    public class JuliaFractalAsm
    {
        [DllImport("FractalAsm.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern IntPtr GenerateFractal(
        double re,
        double im,
        int iterations,
        int width,
        int height,
        int threads);

        public static byte[,] GetFractal(double re, double im, int iterations, int width, int height, int threads)
        {
            IntPtr bufferPtr = GenerateFractal(re, im, iterations, width, height, threads);
            byte[,] result = new byte[width, height * 4];

            unsafe
            {
                byte* buffer = (byte*)bufferPtr.ToPointer();
                for (int y = 0; y < height; y++)
                {
                    for (int x = 0; x < width * 4; x++)
                    {
                        result[y, x] = buffer[y * width * 4 + x];
                    }
                }
            }
            return result;
        }
    }
}
