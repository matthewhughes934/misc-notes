# `wchar_t`

``` c
#define _XOPEN_SOURCE
#include <stdio.h>
#include <locale.h>
#include <wchar.h>

void print_details(const wchar_t *string)
{
    wprintf(L"Details for: %ls\n", string);
    wprintf(L"width is: %d\n", wcswidth(string, 8 * wcslen(string)));

    for (size_t i = 0; i < wcslen(string); i++) {
        if (iswprint(string[i]))
            wprintf(L"%dth byte is printable ", i);
        else
            wprintf(L"%dth byte is not printable ", i);
        wprintf(L"and has width: %d\n", wcwidth(string[i]));
    }

}

int main(void)
{
    setlocale(LC_ALL, "");

    const wchar_t *string =
        // DEVANAGARI LETTER KHA
        L"\x196"
        // DEVANAGARI VOWEL SIGN AA
        L"\x93e";
    print_details(string);

    const wchar_t *flag =
        // WAVING WHITE FLAG
        L"\x1f3f3"
        // VARIATION SELECTOR-16
        L"\xfe0f"
        // ZERO WIDTH JOINER
        L"\x200d"
        // RAINBOW
        L"\x1f308";

    print_details(flag);
    return 0;
}
```
