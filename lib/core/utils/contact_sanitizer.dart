/// Result of [ContactInfoSanitizer.sanitize].
typedef SanitizeResult = ({String text, bool removedSomething});

/// Strips contact details from free text that other people will read
/// (e.g. "About me"), so users can't bypass Khalty by sharing a number,
/// link or social handle. Works with English and Arabic text and with
/// Arabic-Indic digits.
abstract final class ContactInfoSanitizer {
  // Any digit set we accept: ASCII, Arabic-Indic, Extended Arabic-Indic.
  static const _d = '[0-9٠-٩۰-۹]';

  static final List<RegExp> _patterns = [
    // URLs with a scheme or www.
    RegExp(r'(?:https?://|www\.)\S+', caseSensitive: false),
    // Emails (before handles, so the @ part isn't left behind).
    RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+', caseSensitive: false),
    // Bare domains such as wa.me/123, t.me/x, example.com.
    RegExp(
      r'\b[\w-]+(?:\.[\w-]+)*\.(?:com|net|org|io|me|ly|co|app|link|info|biz|'
      r'sa|ae|kw|qa|bh|om|eg|uk|us)\b(?:/\S*)?',
      caseSensitive: false,
    ),
    // Phone numbers: 9+ digits, optionally separated by spaces, dots,
    // dashes or brackets, optionally starting with + or (. (9 keeps year ranges
    // like "2010-2014" intact while catching Gulf mobiles such as
    // 5x xxx xxxx and anything longer.)
    RegExp('[+(]?$_d(?:[\\s\\-.()]*$_d){8,}'),
    // Social handles like @name.
    RegExp(r'@[A-Za-z0-9_.]{2,}'),
    // Social network names, as whole words (English and Arabic).
    RegExp(
      r'(?<!\p{L})(?:whats\s?app|snapchat|instagram|insta|telegram|tiktok|'
      r'facebook|twitter|واتس\s?اب|واتساب|واتس|سناب\s?شات|سناب|انستقرام|'
      r'انستغرام|انستجرام|انستا|تلغرام|تليجرام|تيليجرام|تيك\s?توك|فيسبوك|'
      r'فيس\s?بوك|تويتر)(?!\p{L})',
      caseSensitive: false,
      unicode: true,
    ),
  ];

  static final _spaces = RegExp(r'[ \t]{2,}');
  static final _spaceBeforePunctuation = RegExp(r' +([.,!?،؟])');

  static SanitizeResult sanitize(String input) {
    var text = input;
    for (final pattern in _patterns) {
      text = text.replaceAll(pattern, ' ');
    }
    final removedSomething = text != input;
    if (removedSomething) {
      text = text
          .replaceAll(_spaces, ' ')
          .replaceAllMapped(_spaceBeforePunctuation, (m) => m[1]!)
          .split('\n')
          .map((line) => line.trim())
          .join('\n')
          .trim();
    }
    return (text: text, removedSomething: removedSomething);
  }
}
