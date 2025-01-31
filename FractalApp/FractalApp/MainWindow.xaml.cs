using System.Diagnostics;
using System.Linq.Expressions;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using FractalCSharpLib;


namespace FractalApp
{

    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private int _threads { get; set; }
        private double _real { get; set; }
        private double _imaginary { get; set; }
        private int _iterations { get; set; }
        private Stopwatch _cSharpTimer;
        private Stopwatch _asmTimer;


#if DEBUG
        [DllImport(@"C:\Users\wrobl\source\repos\projekt_JA\FractalApp\x64\Debug\FractalAsmLib.dll", CallingConvention = CallingConvention.Cdecl)]
        private static extern void GenerateJuliaFractalASM(
            byte[] result,        // tablica wynikowa
            double re,           // część rzeczywista C
            double im,           // część urojona C
            int iterations,      // max iteracji
            int startY,          // początek zakresu Y
            int endY            // koniec zakresu Y
        );
        

#else
        [DllImport(@"C:\Users\wrobl\source\repos\projekt_JA\FractalApp\x64\Release\FractalAsmLib.dll", CallingConvention = CallingConvention.Cdecl)]
        private static extern void GenerateJuliaFractalASM(
    byte[] result,        // tablica wynikowa
    double re,           // część rzeczywista C
    double im,           // część urojona C
    int iterations,      // max iteracji
    int startY,          // początek zakresu Y
    int endY            // koniec zakresu Y
);
#endif
        public MainWindow()
        {
            InitializeComponent();
            ThreadsSlider.Value = Environment.ProcessorCount;
            _cSharpTimer = new Stopwatch();
            _asmTimer = new Stopwatch();
        }

        private byte[] GenerateFractalParallel(double re, double im, int iterations, int width, int height, int threads)
        {
            byte[] result = new byte[width * height];
            for (int i = 0; i < result.Length; i++)
            {
                result[i] = 255;
            }

            int segmentHeight = height / threads;
            Task[] tasks = new Task[threads];

            for (int i = 0; i < threads; i++)
            {
                int threadIndex = i;
                int startY = threadIndex * segmentHeight;
                int endY = (threadIndex == threads - 1) ? height : startY + segmentHeight;

                tasks[i] = Task.Run(() =>
                {
                    GenerateJuliaFractalASM(
                        result,
                        re,
                        im,
                        iterations,
                        startY,
                        endY
                    );
                });
            }

            Task.WaitAll(tasks);
            return result;
        }
        private BitmapSource ConvertToImage(byte[,] data)
        {
            int width = data.GetLength(0);
            int height = data.GetLength(1);

            if (width <= 0 || height <= 0)
            {
                throw new ArgumentException("Wymiary obrazu muszą być większe niż 0!");
            }

            // Utwórz bufor na piksele (Bgra32 wymaga 4 bajtów na piksel)
            var pixels = new byte[width * height * 4];

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int index = (y * width + x) * 4;
                    byte value = data[x, y];

                    pixels[index] = value;      // R (odcienie szarości)
                    pixels[index + 1] = value; // G
                    pixels[index + 2] = value; // B
                    pixels[index + 3] = 255;   // Alpha
                }
            }

            // Walidacja rozmiaru
            if (pixels.Length != width * height * 4)
                throw new ArgumentException("Nieprawidłowy rozmiar danych obrazu!");

            // Tworzenie obrazu
            return BitmapSource.Create(
                width, height,
                96, 96,                          // DPI
                PixelFormats.Bgra32,             // Format piksela
                null,                            // Paleta kolorów
                pixels,                          // Dane piksela
                width * 4                        // Stride (ilość bajtów na wiersz)
            );
        }

        private BitmapSource ConvertToImageFromBuffer(byte[] buffer, int width, int height)
        {
            if (width <= 0 || height <= 0)
            {
                throw new ArgumentException("Image dimensions must be greater than 0!");
            }

            // Tworzymy bufor na piksele BGRA (4 bajty na piksel)
            var pixels = new byte[width * height * 4];

            // Konwertujemy wartości skali szarości na format BGRA
            for (int i = 0; i < buffer.Length; i++)
            {
                int pixelIndex = i * 4;
                byte value = buffer[i];
                pixels[pixelIndex] = value;     // B
                pixels[pixelIndex + 1] = value; // G
                pixels[pixelIndex + 2] = value; // R
                pixels[pixelIndex + 3] = 255;   // Alpha (pełna nieprzezroczystość)
            }

            // Tworzymy i zwracamy źródło bitmapy
            return BitmapSource.Create(
                width,                  // Szerokość
                height,                 // Wysokość
                96, 96,                // DPI
                PixelFormats.Bgra32,   // Format pikseli
                null,                  // Paleta kolorów
                pixels,                // Dane pikseli
                width * 4              // Stride (bajtów na linię)
            );
        }


        private async void StartButton_Click(object sender, RoutedEventArgs e)
        {
            _threads = (int)ThreadsSlider.Value;

            try
            {
                _real = double.Parse(ReTextBox.Text.Replace(".", ","));
                _imaginary = double.Parse(ImTextBox.Text.Replace(".", ","));
                _iterations = int.Parse(IterationsTextBox.Text);

                //_real = 0.285;
                //_imaginary = 0.01;
                //_iterations = 100;

            }
            catch (Exception ex)
            {
                MessageBox.Show($"error when inserting data: {ex.Message}");
                return;
            }
            int width = 800;
            int height = 600;

            try
            {
                if (CSharpRadioButton.IsChecked == true)
                {
                    
                    _cSharpTimer = Stopwatch.StartNew();

                    var fractal = await Task.Run(() => JuliaFractalCSharp.GenerateFractal(_real, _imaginary, _iterations, width, height, _threads));

                    _cSharpTimer.Stop();
                    CSharpTimeTextBox.Text = $"{_cSharpTimer.ElapsedMilliseconds} ms";

                    FractalImage.Source = ConvertToImage(fractal);
                }
                else if (AsmRadioButton.IsChecked == true)
                {
                    _asmTimer = Stopwatch.StartNew();
                    try
                    {
                        int pixelCount = width * height;
                        byte[] result = new byte[pixelCount];

                        result = GenerateFractalParallel(
                            _real,
                            _imaginary,
                            _iterations,
                            width,
                            height,
                            _threads
                        );

                        var bitmap = ConvertToImageFromBuffer(result, width, height);

                        // Użyj Dispatcher do aktualizacji UI
                        Dispatcher.Invoke(() =>
                        {
                            FractalImage.Source = bitmap;
                        });
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Error: {ex.Message}\n{ex.StackTrace}");
                    }
                    finally
                    {
                        _asmTimer.Stop();
                        AsmTimeTextBox.Text = $"{_asmTimer.ElapsedMilliseconds} ms";
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error: {ex.Message}\n{ex.StackTrace}");
            }
        }

        private void HelpButton_Click(object sender, RoutedEventArgs e)
        {
            string helpMessage =
                "User Guide for the Fractal Generator Application:\n\n" +
                "1. Enter the fractal parameters:\n" +
                "   - Real part (Re(c)) and Imaginary part (Im(c)) define the complex coordinates.\n" +
                "   - The number of iterations affects the fractal's level of detail (higher value means more detail).\n\n" +
                "2. Choose the generation method:\n" +
                "   - C#: Generation using C# code.\n" +
                "   - ASM: Generation using assembler (if implemented).\n\n" +
                "3. Select the number of threads using the slider (from 1 to 64).\n" +
                "   - A higher number of threads can speed up fractal generation on multi-core processors.\n\n" +
                "4. Click 'Start' to begin generating the fractal.\n\n" +
                "5. The time taken to generate the fractal will be displayed in the respective fields (for C# and ASM).\n\n" +
                "6. You can clear the data and image by clicking the 'Clear' button.\n\n" +
                "If you encounter any issues, check the input parameters or contact the application developer.";

            MessageBox.Show(helpMessage, "Help", MessageBoxButton.OK, MessageBoxImage.Information);
        }


        private void ClearButton_Click(object sender, RoutedEventArgs e)
        {
            ReTextBox.Text = string.Empty;
            ImTextBox.Text = string.Empty;
            IterationsTextBox.Text = string.Empty;
            ThreadsSlider.Value = Environment.ProcessorCount;
            CSharpTimeTextBox.Text = string.Empty;
            AsmTimeTextBox.Text = string.Empty;
            FractalImage.Source = null;
        }

        private void ThreadsSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            if (ThreadsLabel != null)
            {
                ThreadsLabel.Text = ThreadsSlider.Value.ToString();
            }
        }
    }
}