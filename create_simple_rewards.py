#!/usr/bin/env python3
"""
Простой скрипт для создания базовых PNG заглушек без PIL
"""
import os
import struct

def create_simple_png(width, height, output_path):
    """Создает простой PNG файл с однотонным цветом"""
    
    # Создаем простой PNG файл (красный квадрат)
    def make_png(width, height):
        # Создаем простые данные пикселей (красный цвет)
        data = []
        for y in range(height):
            for x in range(width):
                # Красный пиксель
                data.extend([255, 0, 0, 255])  # RGBA
                
        # PNG заголовок
        png_header = b'\x89PNG\r\n\x1a\n'
        
        # IHDR chunk
        ihdr_data = struct.pack('>2I5B', width, height, 8, 2, 0, 0, 0)
        ihdr_chunk = make_chunk(b'IHDR', ihdr_data)
        
        # IDAT chunk (сжатые данные)
        compressed_data = compress_data(data)
        idat_chunk = make_chunk(b'IDAT', compressed_data)
        
        # IEND chunk
        iend_chunk = make_chunk(b'IEND', b'')
        
        return png_header + ihdr_chunk + idat_chunk + iend_chunk
    
    def make_chunk(chunk_type, data):
        length = struct.pack('>I', len(data))
        crc = struct.pack('>I', (zlib.crc32(chunk_type + data) & 0xffffffff))
        return length + chunk_type + data + crc
    
    def compress_data(data):
        # Простое сжатие - пока что возвращаем как есть
        import zlib
        return zlib.compress(bytes(data))
    
    # Создаем директорию если не существует
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Создаем PNG файл
    try:
        png_data = make_png(width, height)
        with open(output_path, 'wb') as f:
            f.write(png_data)
        print(f"Создано: {output_path}")
    except Exception as e:
        print(f"Ошибка при создании {output_path}: {e}")
        # Создаем простой текстовый файл как заглушку
        with open(output_path.replace('.png', '.txt'), 'w') as f:
            f.write(f"Заглушка для награды: {os.path.basename(output_path)}")

def create_text_placeholder(output_path, content):
    """Создает текстовую заглушку"""
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(content)
    print(f"Создана текстовая заглушка: {output_path}")

def main():
    """Создает награды для тестирования"""
    countries = ['japan', 'egypt', 'france', 'brazil', 'norway']
    subcategories = [
        'classic', 'hard', 'games', 'legends', 'cinema', 
        'cuisine', 'transport', 'unexpected', 'history_personalities', 'architecture'
    ]
    
    # Создаем награды только для нескольких уровней для тестирования
    test_levels = [1, 2, 3]
    
    print("Создание простых заглушек для наград...")
    
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
                
                # Создаем простую заглушку
                content = f"Награда за 3 звезды в уровне {level} категории {subcategory} страны {country}"
                create_text_placeholder(output_path, content)
    
    print(f"\nСоздано {len(countries) * len(subcategories) * len(test_levels)} заглушек!")
    print("Теперь пересоберите проект: flutter clean && flutter pub get && flutter run")

if __name__ == "__main__":
    main()