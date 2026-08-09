import 'package:flutter_test/flutter_test.dart';
import 'package:culpeo_studio/modules/marketplace/marketplace_format.dart';

void main() {
  group('Marketplace quantization summary', () {
    test('groups related variants into one compact label', () {
      final summary = summarizeMarketplaceQuantizations([
        'q4_k_m',
        'Q4-0',
        'q8_0',
        'fp16',
      ]);

      expect(summary.variants, ['Q4_K_M', 'Q4_0', 'Q8_0', 'FP16']);
      expect(summary.families, ['Q4', 'Q8', 'FP16']);
      expect(summary.label, 'Q4 · Q8 · FP16 · +1');
      expect(summary.tooltip, 'Q4_K_M · Q4_0 · Q8_0 · FP16');
    });

    test('keeps a single exact quantization visible', () {
      final summary = summarizeMarketplaceQuantizations(['q4_k_m']);

      expect(summary.label, 'Q4_K_M');
      expect(summary.tooltip, 'Q4_K_M');
    });

    test('removes quantization duplicates from capability tags', () {
      final tags = marketplaceNonQuantizationTags([
        'chat',
        'q4_k_m',
        'q8_0',
        'gguf',
        'fp16',
      ]);

      expect(tags, ['chat', 'gguf']);
      expect(isMarketplaceQuantization('IQ4_XS'), isTrue);
      expect(isMarketplaceQuantization('reasoning'), isFalse);
    });
  });
}
