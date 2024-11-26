# Generator Fraktala Julii

## Opis
Projekt **Generator Fraktala Julii** to aplikacja umożliwiająca wizualizację jednego z najbardziej znanych rodzajów fraktali – zbioru Julii. Program generuje obrazy fraktali na podstawie wprowadzonych przez użytkownika parametrów zespolonych, liczby iteracji oraz rozmiarów okna rysowania. W celu zapewnienia elastyczności i wydajności, projekt umożliwia wybór metody generowania fraktala – za pomocą kodu napisanego w języku C# lub asemblerze (ASM).

Aplikacja dodatkowo wspiera wielowątkowość, umożliwiając użytkownikowi wybór liczby wątków używanych podczas generowania fraktala, co pozwala zoptymalizować czas wykonania na procesorach wielordzeniowych.

## Technologie
Projekt został zrealizowany przy użyciu następujących technologii:
- **C#** – Główna logika aplikacji oraz interfejs graficzny (WPF).
- **Asembler (ASM)** – Kod niskopoziomowy do generowania fraktala, zoptymalizowany pod kątem wydajności.
- **WPF (Windows Presentation Foundation)** – Tworzenie graficznego interfejsu użytkownika.
- **Task Parallel Library (TPL)** – Używana w wersji C# do obsługi wielowątkowości.

## Funkcjonalność
1. **Wybór metody generowania fraktala:**
   - **C#:** Generowanie fraktala przy użyciu kodu wysokopoziomowego w języku C#.
   - **ASM:** Generowanie fraktala przy użyciu niskopoziomowego kodu asemblera.

2. **Obsługa wielowątkowości:**
   - Użytkownik może wybrać liczbę wątków (od 1 do 64) w celu zoptymalizowania wydajności.

3. **Pomiar czasu wykonania:**
   - Aplikacja mierzy czas generowania fraktala w obu trybach (C# i ASM), umożliwiając porównanie ich wydajności.

4. **Dynamiczne skalowanie rozmiaru:**
   - Fraktal jest generowany w oparciu o aktualne wymiary okna rysowania, które można zmieniać dynamicznie.

## Cel projektu
Projekt ma na celu:
- Zbadanie wydajności kodu generowanego w języku C# w porównaniu z kodem asemblera.
- Zrozumienie różnic między wysokopoziomowym i niskopoziomowym podejściem do programowania.
- Stworzenie wizualnego narzędzia do eksploracji piękna matematyki i geometrii fraktalnej.

## Autor
Projekt został stworzony przez Grzegorza Urbańskiego jako część zaliczenia z przedmiotu **Języki Asemblerowe** na Politechnice Śląskiej w Katowicach.

## Dodatkowe informacje
Projekt demonstruje, jak zaawansowane funkcje programowania w C# można zintegrować z niskopoziomowym kodem asemblera, aby uzyskać większą wydajność. Wykorzystanie wielowątkowości oraz porównanie dwóch podejść wykonawczych czyni ten projekt interesującym eksperymentem z zakresu optymalizacji i architektury oprogramowania.

**Interfejs aplikacji** został zaprojektowany w WPF i oferuje użytkownikowi intuicyjne narzędzia do wprowadzania parametrów, takich jak liczba iteracji, parametry zespolone oraz liczba wątków. Wynikowy obraz fraktala jest wyświetlany w czasie rzeczywistym, umożliwiając eksplorację geometrii fraktalnej.
