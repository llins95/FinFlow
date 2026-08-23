import 'package:flutter/material.dart';

/// Representação compacta do cartão usada ao lado de faturas.
///
/// A cor vem do cadastro do cartão e a bandeira é desenhada localmente para
/// manter o componente disponível offline no Android e no Windows.
class MiniCreditCard extends StatelessWidget {
  const MiniCreditCard({
    super.key,
    required this.color,
    required this.brand,
    this.width = 48,
    this.height = 30,
  });

  final int color;
  final String brand;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final background = Color(color);
    final foreground = ThemeData.estimateBrightnessForColor(background) ==
            Brightness.dark
        ? Colors.white
        : const Color(0xE6000000);

    return Semantics(
      label: 'Mini cartão, bandeira $brand',
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(height * 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: width * 0.13,
                top: height * 0.2,
                child: Container(
                  width: width * 0.2,
                  height: height * 0.24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD77A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                right: width * 0.1,
                bottom: height * 0.12,
                child: _CardBrandMark(
                  brand: brand,
                  foreground: foreground,
                  scale: height / 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBrandMark extends StatelessWidget {
  const _CardBrandMark({
    required this.brand,
    required this.foreground,
    required this.scale,
  });

  final String brand;
  final Color foreground;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final normalized = brand.toLowerCase().trim();

    if (normalized.contains('master')) {
      return SizedBox(
        width: 18 * scale,
        height: 11 * scale,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: _BrandCircle(
                color: const Color(0xFFEB001B),
                diameter: 11 * scale,
              ),
            ),
            Positioned(
              right: 0,
              child: _BrandCircle(
                color: const Color(0xFFF79E1B),
                diameter: 11 * scale,
              ),
            ),
          ],
        ),
      );
    }

    if (normalized.contains('visa')) {
      return _BrandText(
        text: 'VISA',
        color: foreground,
        scale: scale,
        italic: true,
      );
    }

    if (normalized.contains('elo')) {
      return _BrandText(
        text: 'elo',
        color: foreground,
        scale: scale,
      );
    }

    if (normalized.contains('american') || normalized.contains('amex')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 2 * scale),
        color: const Color(0xFF2E77BC),
        child: _BrandText(
          text: 'AMEX',
          color: Colors.white,
          scale: scale * 0.82,
        ),
      );
    }

    return _BrandText(
      text: _initials(brand),
      color: foreground,
      scale: scale,
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'CARD';
    }
    if (words.length == 1) {
      final length = words.first.length > 4 ? 4 : words.first.length;
      return words.first.substring(0, length).toUpperCase();
    }
    return words.take(3).map((word) => word[0]).join().toUpperCase();
  }
}

class _BrandCircle extends StatelessWidget {
  const _BrandCircle({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BrandText extends StatelessWidget {
  const _BrandText({
    required this.text,
    required this.color,
    required this.scale,
    this.italic = false,
  });

  final String text;
  final Color color;
  final double scale;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      style: TextStyle(
        color: color,
        fontSize: 7 * scale,
        height: 1,
        fontWeight: FontWeight.w900,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: -0.2,
      ),
    );
  }
}
