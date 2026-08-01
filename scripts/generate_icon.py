#!/usr/bin/env python3
"""Generate a premium AI Video Studio app icon and all native launcher sizes."""

import math
import os
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(OUTPUT_DIR)
ASSETS_DIR = os.path.join(PROJECT_ROOT, "assets", "images")
ANDROID_DIR = os.path.join(PROJECT_ROOT, "android", "app", "src", "main", "res")
IOS_DIR = os.path.join(PROJECT_ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")

SIZE = 1024

def lerp(a, b, t):
    return int(a + (b - a) * t)

def lerp_color(c1, c2, t):
    return tuple(lerp(c1[i], c2[i], t) for i in range(3))

def create_gradient(size, colors, angle_deg=135):
    """Create a diagonal gradient."""
    img = Image.new("RGB", (size, size), colors[0])
    pixels = img.load()
    angle = math.radians(angle_deg)
    dx = math.cos(angle)
    dy = math.sin(angle)
    for y in range(size):
        for x in range(size):
            t = (x * dx + y * dy) / (size * (abs(dx) + abs(dy)))
            t = max(0, min(1, t))
            segment = t * (len(colors) - 1)
            idx = int(segment)
            frac = segment - idx
            if idx >= len(colors) - 1:
                pixels[x, y] = colors[-1]
            else:
                pixels[x, y] = lerp_color(colors[idx], colors[idx + 1], frac)
    return img

def draw_glowing_circle(draw, cx, cy, radius, color, glow_layers=6):
    """Draw a circle with a soft glow halo."""
    for i in range(glow_layers, 0, -1):
        r = int(radius + i * 12)
        alpha = int(40 * (1 - i / glow_layers))
        glow_color = (*color, alpha)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=glow_color)

def create_icon(size):
    """Create the premium app icon."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Background gradient: deep navy to dark blue-black
    bg_colors = [
        (12, 18, 40),    # deep navy
        (8, 12, 28),     # darker navy
        (5, 8, 16),      # near-black
    ]
    bg = create_gradient(size, bg_colors, angle_deg=135).convert("RGBA")
    img.paste(bg, (0, 0))

    draw = ImageDraw.Draw(img, "RGBA")
    cx, cy = size // 2, size // 2

    # Outer neon ring — electric cyan glow
    ring_radius = int(size * 0.38)
    ring_thickness = max(3, size // 80)
    for i in range(8, 0, -1):
        r = ring_radius + i * 8
        alpha = int(25 * (1 - i / 8))
        draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            outline=(0, 212, 255, alpha),
            width=ring_thickness,
        )
    # Crisp ring
    draw.ellipse(
        [cx - ring_radius, cy - ring_radius, cx + ring_radius, cy + ring_radius],
        outline=(0, 212, 255, 220),
        width=ring_thickness,
    )

    # Inner gradient circle — sapphire blue to cyan
    inner_radius = int(size * 0.30)
    inner_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inner_draw = ImageDraw.Draw(inner_img, "RGBA")
    for r in range(inner_radius, 0, -1):
        t = 1 - (r / inner_radius)
        color = lerp_color(
            (37, 99, 235),   # sapphire blue
            (0, 212, 255),   # electric cyan
            t,
        )
        inner_draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            fill=(*color, 255),
        )
    img = Image.alpha_composite(img, inner_img)
    draw = ImageDraw.Draw(img, "RGBA")

    # Play triangle — pure white with subtle glow
    triangle_size = int(size * 0.14)
    # Center the triangle slightly right for optical balance
    offset = int(size * 0.02)
    triangle = [
        (cx - triangle_size + offset, cy - int(triangle_size * 1.3)),
        (cx - triangle_size + offset, cy + int(triangle_size * 1.3)),
        (cx + int(triangle_size * 1.5) + offset, cy),
    ]
    # Glow behind triangle
    for i in range(5, 0, -1):
        glow_triangle = []
        expand = i * 4
        for px, py in triangle:
            dx = px - cx
            dy = py - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if dist > 0:
                glow_triangle.append((
                    px + (dx / dist) * expand,
                    py + (dy / dist) * expand,
                ))
            else:
                glow_triangle.append((px, py))
        draw.polygon(glow_triangle, fill=(255, 255, 255, 20))
    draw.polygon(triangle, fill=(255, 255, 255, 255))

    # Small sparkle accent — top right of the ring
    sparkle_cx = cx + int(ring_radius * 0.7)
    sparkle_cy = cy - int(ring_radius * 0.7)
    sparkle_size = int(size * 0.025)
    # 4-point star
    sparkle = [
        (sparkle_cx, sparkle_cy - sparkle_size * 3),
        (sparkle_cx + sparkle_size, sparkle_cy),
        (sparkle_cx, sparkle_cy + sparkle_size * 3),
        (sparkle_cx - sparkle_size, sparkle_cy),
    ]
    draw.polygon(sparkle, fill=(255, 255, 255, 200))
    # Small dot glow
    for i in range(3, 0, -1):
        r = sparkle_size + i * 6
        draw.ellipse(
            [sparkle_cx - r, sparkle_cy - r, sparkle_cx + r, sparkle_cy + r],
            fill=(0, 212, 255, int(30 * (1 - i / 3))),
        )

    # Apply slight blur for premium softness on the glow elements only
    blurred = img.filter(ImageFilter.GaussianBlur(radius=0.5))
    img = Image.alpha_composite(img, blurred)

    return img

def save_icon(img, path, size):
    """Save icon at specific size."""
    resized = img.resize((size, size), Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    resized.save(path, "PNG")
    print(f"  Created: {path} ({size}x{size})")

def generate_all():
    print("Generating premium app icon (1024x1024)...")
    icon = create_icon(SIZE)

    # Save master icon
    master_path = os.path.join(ASSETS_DIR, "launcher_icon.png")
    save_icon(icon, master_path, SIZE)

    # Android launcher icons (mipmap folders)
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    print("\nGenerating Android launcher icons...")
    for folder, size in android_sizes.items():
        path = os.path.join(ANDROID_DIR, folder, "ic_launcher.png")
        save_icon(icon, path, size)

    # Android adaptive foreground (needs padding for safe zone)
    print("\nGenerating Android adaptive foreground...")
    fg_size = 108
    fg_img = Image.new("RGBA", (fg_size * 3, fg_size * 3), (0, 0, 0, 0))
    # Scale icon to 66% of the 108dp canvas (safe zone)
    inner_icon = icon.resize((int(fg_size * 3 * 0.66), int(fg_size * 3 * 0.66)), Image.LANCZOS)
    offset = (fg_size * 3 - inner_icon.width) // 2
    fg_img.paste(inner_icon, (offset, offset), inner_icon)
    for folder in ["drawable-mdpi", "drawable-hdpi", "drawable-xhdpi", "drawable-xxhdpi", "drawable-xxxhdpi"]:
        scale = {"drawable-mdpi": 1, "drawable-hdpi": 1.5, "drawable-xhdpi": 2, "drawable-xxhdpi": 3, "drawable-xxxhdpi": 4}[folder]
        target_size = int(fg_size * scale)
        path = os.path.join(ANDROID_DIR, folder, "ic_launcher_foreground.png")
        save_icon(fg_img, path, target_size)

    # iOS AppIcon set
    print("\nGenerating iOS AppIcon set...")
    ios_sizes = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    for filename, size in ios_sizes:
        path = os.path.join(IOS_DIR, filename)
        save_icon(icon, path, size)

    print("\nAll icons generated successfully!")

if __name__ == "__main__":
    generate_all()
