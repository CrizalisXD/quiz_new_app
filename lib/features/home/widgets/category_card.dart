import 'package:flutter/material.dart';

// Карточка страны. Раньше ширина была не задана, поэтому в Column она схлопывалась до 0
// (отсюда отсутствие клика). Теперь фиксируем ширину в infinity.
class CategoryCard extends StatelessWidget {
  final String imageAsset;
  final VoidCallback onTap;
  final String? title; // опционально: показать текст поверх

  const CategoryCard({
    super.key,
    required this.imageAsset,
    required this.onTap,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 112,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: const BoxDecoration(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Фоновое изображение с fallback
                  Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.black45, size: 32),
                    ),
                  ),
                  // Лёгкий градиент снизу
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.18),
                        ],
                      ),
                    ),
                  ),
                  if (title != null)
                    Positioned(
                      left: 16,
                      bottom: 12,
                      right: 16,
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
