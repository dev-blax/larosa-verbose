# larosa88

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.






<!-- String fixEncoding(String text) {
  try {
    // Step 1: Normalize line breaks (\r\n → \n)
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    // Step 2: Decode text while preserving special characters
    String decoded = utf8.decode(text.runes.toList(), allowMalformed: true);

if (decoded.contains('�')) {
          debugPrint("Malformation detected, replacing corrupt bytes.");
          return utf8.decode(text.runes.toList(), allowMalformed: false);
        }
    // Step 3: Ensure emojis and grapheme clusters remain intact using `characters`
    decoded = decoded.characters.string;

    return decoded;
  } catch (e) {
    debugPrint("UTF-8 Normal Decoding Failed: $e");

    try {
      // Step 4: Latin-1 Fix
      List<int> bytes = latin1.encode(text);
      String decoded = utf8.decode(bytes, allowMalformed: true);

      // Step 5: Use `characters` package to ensure emoji correctness
      return decoded.characters.string.trim();
    } catch (e) {
      debugPrint("Latin-1 Fallback Failed: $e");

      try {
        // Step 6: Windows-1252 Fix
        List<int> bytes = latin1.encode(text);
        return utf8.decode(bytes, allowMalformed: true)
            .characters.string
            .trim();
      } catch (e) {
        debugPrint("Windows-1252 Fallback Failed: $e");

        // Last resort: Use `characters` package on the raw text
        return text.characters.string.trim();
      }
    }
  }
} -->