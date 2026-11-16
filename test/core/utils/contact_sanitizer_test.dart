import 'package:flutter_test/flutter_test.dart';
import 'package:khalty_ai_matchmaker/core/utils/contact_sanitizer.dart';

String clean(String s) => ContactInfoSanitizer.sanitize(s).text;

void main() {
  test('leaves normal text untouched', () {
    const bio = 'I love reading and travelling. Graduated 2010-2014, age 29.';
    final result = ContactInfoSanitizer.sanitize(bio);
    expect(result.text, bio);
    expect(result.removedSomething, isFalse);
  });

  group('phone numbers', () {
    test('international and local formats', () {
      expect(clean('Call me +966 50 123 4567 please'), 'Call me please');
      expect(clean('رقمي 0501234567'), 'رقمي');
      expect(clean('ring (050) 123-4567'), 'ring');
    });

    test('Arabic-Indic digits', () {
      expect(clean('رقمي ٠٥٠١٢٣٤٥٦٧ شكرا'), 'رقمي شكرا');
      expect(clean('رقمي ۰۵۰۱۲۳۴۵۶۷'), 'رقمي');
    });
  });

  group('links and emails', () {
    test('URLs and bare domains', () {
      expect(clean('see https://example.com/me now'), 'see now');
      expect(clean('visit www.mysite.net'), 'visit');
      expect(clean('message wa.me/966501234567'), 'message');
      expect(clean('join t.me/someone'), 'join');
    });

    test('emails', () {
      expect(clean('email me at ali.k+1@mail.co.uk.'), 'email me at.');
    });
  });

  group('social handles and networks', () {
    test('@handles', () {
      expect(clean('find me @ali_k99'), 'find me');
    });

    test('network names in English and Arabic, as whole words', () {
      expect(clean('add me on WhatsApp or Instagram'), 'add me on or');
      expect(clean('كلمني واتساب أو سناب'), 'كلمني أو');
      expect(clean('تابعني انستقرام'), 'تابعني');
    });

    test('does not cut words that merely contain a network name', () {
      expect(clean('Installing software'), 'Installing software');
    });
  });

  test('keeps line breaks and reports removal', () {
    final result = ContactInfoSanitizer.sanitize(
      'Hello!\nMy number is 0501234567\nBye',
    );
    expect(result.text, 'Hello!\nMy number is\nBye');
    expect(result.removedSomething, isTrue);
  });
}
