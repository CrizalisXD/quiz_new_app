#!/usr/bin/env python3
"""
Скрипт для создания простых заглушек изображений наград
"""
import os
from PIL import Image, ImageDraw, ImageFont

def create_reward_image(country, subcategory, level, output_path):
    """Создает простое изображение-заглушку для награды"""
    # Размеры изображения
    width, height = 300, 400
    
    # Создаем изображение с градиентным фоном
    img = Image.new('RGB', (width, height), color='#4A90E2')
    draw = ImageDraw.Draw(img)
    
    # Создаем градиентный фон
    for y in range(height):
        color_value = int(74 + (y / height) * 50)  # От #4A90E2 до #6BB6FF
        color = f"#{color_value:02X}{180:02X}{226:02X}"
        draw.line([(0, y), (width, y)], fill=color)
    
    # Добавляем текст
    try:
        # Пытаемся использовать системный шрифт
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 24)
    except:
        try:
            font = ImageFont.truetype("arial.ttf", 24)
        except:
            font = ImageFont.load_default()
    
    # Текст
    title = f"{country.upper()}"
    subtitle = f"{subcategory.replace('_', ' ').title()}"
    level_text = f"Level {level}"
    
    # Позиции текста
    title_bbox = draw.textbbox((0, 0), title, font=font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_x = (width - subtitle_width) // 2
    
    level_bbox = draw.textbbox((0, 0), level_text, font=font)
    level_width = level_bbox[2] - level_bbox[0]
    level_x = (width - level_width) // 2
    
    # Рисуем текст
    draw.text((title_x, 80), title, fill='white', font=font)
    draw.text((subtitle_x, 120), subtitle, fill='white', font=font)
    draw.text((level_x, 160), level_text, fill='white', font=font)
    
    # Добавляем звезды
    star_y = 220
    for i in range(3):
        star_x = 50 + i * 80
        draw.text((star_x, star_y), "★", fill='gold', font=font)
    
    # Добавляем рамку
    draw.rectangle([10, 10, width-10, height-10], outline='white', width=3)
    
    # Сохраняем изображение
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, 'PNG')
    print(f"Создано: {output_path}")

def main():
    """Создает награды для всех стран и подкатегорий"""
    countries = ['japan', 'egypt', 'france', 'brazil', 'norway']
    subcategories = [
        'classic', 'hard', 'games', 'legends', 'cinema', 
        'cuisine', 'transport', 'unexpected', 'history_personalities', 'architecture'
    ]
    
    # Создаем награды только для нескольких уровней для тестирования
    test_levels = [1, 2, 3]
    
    for country in countries:
        for subcategory in subcategories:
            for level in test_levels:
                # Определяем алиас для совместимости с кодом
                if subcategory == 'history_persons':
                    alias = 'history_personalities'
                elif subcategory in ['food', 'food_drink', 'food_drinks', 'food_and_drink', 'food_and_drinks', 'cuisine']:
                    alias = 'cuisine'
                else:
                    alias = subcategory
                
                # Создаем путь к файлу
                output_path = f"assets/images/reward/{country}/{country}_{alias}_lvl/{country}_{alias}_{level}.png"
                
                # Создаем изображение
                create_reward_image(country, alias, level, output_path)

if __name__ == "__main__":
    main()
    print("\nВсе награды созданы!")
    print("Теперь пересоберите проект: flutter clean && flutter pub get && flutter run")