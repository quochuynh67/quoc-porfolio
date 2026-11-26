export 'filter_catalog.dart';
import 'package:flutter/material.dart';

import 'video_editor_project.dart';

@immutable
class EditorTextTemplate {
  const EditorTextTemplate({
    required this.id,
    required this.name,
    required this.sample,
    required this.category,
    required this.style,
    this.enter = OverlayEnter.none,
    this.exit = OverlayExit.none,
    this.loop = OverlayLoop.none,
  });

  final String id;
  final String name;
  final String sample;
  final String category;
  final EditorTextStyle style;
  final OverlayEnter enter;
  final OverlayExit exit;
  final OverlayLoop loop;
}

const textCategories = [
  'All',
  'Animated',
  'Titles',
  'Captions',
  'Fun',
  'Elegant',
];

const textTemplates = <EditorTextTemplate>[
  EditorTextTemplate(
    id: 'anim-typewriter',
    name: 'Typewriter',
    sample: 'Once upon a time...',
    category: 'Animated',
    enter: OverlayEnter.typewriter,
    exit: OverlayExit.fade,
    style: EditorTextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 22,
        weight: 700,
        background: Color(0xB3000000),
        shadow: false,
        radius: 4),
  ),
  EditorTextTemplate(
    id: 'anim-letter-rise',
    name: 'Letter rise',
    sample: 'Hello World',
    category: 'Animated',
    enter: OverlayEnter.letterRise,
    exit: OverlayExit.fade,
    style: EditorTextStyle(fontFamily: 'Montserrat', fontSize: 32, weight: 900),
  ),
  EditorTextTemplate(
    id: 'anim-wave',
    name: 'Wave',
    sample: 'Good vibes',
    category: 'Animated',
    enter: OverlayEnter.fade,
    loop: OverlayLoop.wave,
    style: EditorTextStyle(
        fontFamily: 'Fredoka',
        fontSize: 34,
        weight: 700,
        gradient: [Color(0xFFFF9A9E), Color(0xFFFAD0C4), Color(0xFFFBC2EB)],
        shadow: false),
  ),
  EditorTextTemplate(
    id: 'anim-glitch',
    name: 'Glitch',
    sample: 'SYSTEM ERROR',
    category: 'Animated',
    enter: OverlayEnter.fade,
    loop: OverlayLoop.glitch,
    style: EditorTextStyle(
        fontFamily: 'Orbitron',
        fontSize: 26,
        weight: 900,
        letterSpacing: 2,
        uppercase: true),
  ),
  EditorTextTemplate(
    id: 'anim-pop',
    name: 'Pop in',
    sample: 'WOW!',
    category: 'Animated',
    enter: OverlayEnter.pop,
    exit: OverlayExit.zoom,
    loop: OverlayLoop.pulse,
    style: EditorTextStyle(
        fontFamily: 'Bangers',
        fontSize: 44,
        weight: 400,
        color: Color(0xFFFFE600),
        stroke: Color(0xFFE53935),
        strokeWidth: 5,
        letterSpacing: 2),
  ),
  EditorTextTemplate(
    id: 'anim-bounce',
    name: 'Bounce drop',
    sample: 'Subscribe',
    category: 'Animated',
    enter: OverlayEnter.bounce,
    exit: OverlayExit.slideDown,
    style: EditorTextStyle(
        fontFamily: 'Poppins',
        fontSize: 22,
        weight: 800,
        background: Color(0xFFE53935),
        shadow: false,
        radius: 99),
  ),
  EditorTextTemplate(
    id: 'anim-neon-blink',
    name: 'Neon blink',
    sample: 'OPEN 24/7',
    category: 'Animated',
    enter: OverlayEnter.fade,
    loop: OverlayLoop.blink,
    style: EditorTextStyle(
        fontFamily: 'Orbitron',
        fontSize: 28,
        weight: 800,
        color: Color(0xFFFFF3E0),
        glow: Color(0xFFFF6D00),
        letterSpacing: 3),
  ),
  EditorTextTemplate(
    id: 'anim-slide-title',
    name: 'Slide title',
    sample: 'Chapter 01',
    category: 'Animated',
    enter: OverlayEnter.slideRight,
    exit: OverlayExit.slideUp,
    style: EditorTextStyle(
        fontFamily: 'Oswald',
        fontSize: 30,
        weight: 700,
        letterSpacing: 4,
        uppercase: true),
  ),
  EditorTextTemplate(
    id: 'anim-blur-in',
    name: 'Blur reveal',
    sample: 'The Journey',
    category: 'Animated',
    enter: OverlayEnter.blur,
    exit: OverlayExit.fade,
    loop: OverlayLoop.float,
    style: EditorTextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 32,
        weight: 700,
        italic: true),
  ),
  EditorTextTemplate(
    id: 'anim-shake',
    name: 'Shake alert',
    sample: 'BREAKING',
    category: 'Animated',
    enter: OverlayEnter.pop,
    loop: OverlayLoop.shake,
    style: EditorTextStyle(
        fontFamily: 'Anton',
        fontSize: 32,
        weight: 400,
        color: Colors.white,
        background: Color(0xFFD50000),
        shadow: false,
        radius: 4,
        letterSpacing: 2),
  ),
  EditorTextTemplate(
    id: 'bold-title',
    name: 'Bold title',
    sample: 'Travel Vlog',
    category: 'Titles',
    style: EditorTextStyle(
        fontFamily: 'Montserrat', fontSize: 30, weight: 900, uppercase: true),
  ),
  EditorTextTemplate(
    id: 'cinema',
    name: 'Cinematic',
    sample: 'Chapter One',
    category: 'Titles',
    style: EditorTextStyle(
        fontFamily: 'Cinzel',
        fontSize: 28,
        weight: 700,
        letterSpacing: 5,
        uppercase: true),
  ),
  EditorTextTemplate(
    id: 'impact',
    name: 'Impact',
    sample: 'Big Moment',
    category: 'Titles',
    style: EditorTextStyle(
        fontFamily: 'Anton',
        fontSize: 36,
        weight: 400,
        uppercase: true,
        stroke: Color(0xFF111111),
        strokeWidth: 4,
        color: Color(0xFFFFE600)),
  ),
  EditorTextTemplate(
    id: 'neon-pink',
    name: 'Neon pink',
    sample: 'Night Out',
    category: 'Titles',
    style: EditorTextStyle(
        fontFamily: 'Pacifico',
        fontSize: 32,
        weight: 400,
        color: Color(0xFFFFE6F7),
        glow: Color(0xFFFF2BD6)),
  ),
  EditorTextTemplate(
    id: 'neon-cyan',
    name: 'Neon cyan',
    sample: 'City Lights',
    category: 'Titles',
    style: EditorTextStyle(
        fontFamily: 'Orbitron',
        fontSize: 26,
        weight: 800,
        color: Color(0xFFE0FFFF),
        glow: Color(0xFF00E5FF),
        letterSpacing: 2),
  ),
  EditorTextTemplate(
    id: 'sunset-gradient',
    name: 'Sunset',
    sample: 'Golden Hour',
    category: 'Titles',
    style: EditorTextStyle(
        fontFamily: 'Righteous',
        fontSize: 32,
        weight: 400,
        gradient: [Color(0xFFFFC837), Color(0xFFFF4E50)],
        shadow: false),
  ),
  EditorTextTemplate(
    id: 'ocean-gradient',
    name: 'Ocean',
    sample: 'Summer Trip',
    category: 'Titles',
    style: EditorTextStyle(
        fontFamily: 'Poppins',
        fontSize: 30,
        weight: 800,
        gradient: [Color(0xFF00F5A0), Color(0xFF00B8FF)],
        shadow: false),
  ),
  EditorTextTemplate(
    id: 'subtitle-box',
    name: 'Subtitle box',
    sample: 'Add your caption here',
    category: 'Captions',
    style: EditorTextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        weight: 600,
        background: Color(0xCC000000),
        shadow: false,
        radius: 6),
  ),
  EditorTextTemplate(
    id: 'subtitle-yellow',
    name: 'Yellow caption',
    sample: 'Watch till the end',
    category: 'Captions',
    style: EditorTextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        weight: 700,
        color: Color(0xFFFFE600),
        stroke: Color(0xFF000000),
        strokeWidth: 3),
  ),
  EditorTextTemplate(
    id: 'lower-third',
    name: 'Lower third',
    sample: 'Quoc Huynh',
    category: 'Captions',
    style: EditorTextStyle(
        fontFamily: 'Oswald',
        fontSize: 22,
        weight: 600,
        color: Color(0xFF101010),
        background: Color(0xFFFFFFFF),
        shadow: false,
        radius: 2,
        letterSpacing: 1),
  ),
  EditorTextTemplate(
    id: 'pill-pink',
    name: 'Pill label',
    sample: 'NEW',
    category: 'Captions',
    style: EditorTextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        weight: 800,
        background: Color(0xFFFF4D8D),
        shadow: false,
        radius: 99,
        letterSpacing: 1.5),
  ),
  EditorTextTemplate(
    id: 'pill-lime',
    name: 'Lime tag',
    sample: 'Day 01',
    category: 'Captions',
    style: EditorTextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        weight: 800,
        color: Color(0xFF0A1A00),
        background: Color(0xFFB6FF3B),
        shadow: false,
        radius: 99),
  ),
  EditorTextTemplate(
    id: 'comic',
    name: 'Comic',
    sample: 'Wow!',
    category: 'Fun',
    style: EditorTextStyle(
        fontFamily: 'Bangers',
        fontSize: 38,
        weight: 400,
        color: Color(0xFFFFFFFF),
        stroke: Color(0xFFE53935),
        strokeWidth: 5,
        letterSpacing: 2),
  ),
  EditorTextTemplate(
    id: 'marker',
    name: 'Marker',
    sample: 'So good',
    category: 'Fun',
    style: EditorTextStyle(
        fontFamily: 'Permanent Marker',
        fontSize: 30,
        weight: 400,
        color: Color(0xFFFFF176)),
  ),
  EditorTextTemplate(
    id: 'bubble',
    name: 'Bubble',
    sample: 'Hello!',
    category: 'Fun',
    style: EditorTextStyle(
        fontFamily: 'Fredoka',
        fontSize: 30,
        weight: 700,
        color: Color(0xFFFFFFFF),
        background: Color(0xFF7C4DFF),
        shadow: false,
        radius: 22),
  ),
  EditorTextTemplate(
    id: 'retro-game',
    name: 'Retro game',
    sample: 'Level Up',
    category: 'Fun',
    style: EditorTextStyle(
        fontFamily: 'Press Start 2P',
        fontSize: 16,
        weight: 400,
        color: Color(0xFF39FF14),
        stroke: Color(0xFF000000),
        strokeWidth: 3),
  ),
  EditorTextTemplate(
    id: 'bungee',
    name: 'Street',
    sample: 'Downtown',
    category: 'Fun',
    style: EditorTextStyle(
        fontFamily: 'Bungee',
        fontSize: 28,
        weight: 400,
        color: Color(0xFFFF6D00),
        stroke: Color(0xFFFFFFFF),
        strokeWidth: 2),
  ),
  EditorTextTemplate(
    id: 'typewriter',
    name: 'Typewriter',
    sample: 'Dear diary...',
    category: 'Fun',
    style: EditorTextStyle(
        fontFamily: 'Special Elite',
        fontSize: 22,
        weight: 400,
        background: Color(0xE6F5EFE0),
        color: Color(0xFF2B2B2B),
        shadow: false,
        radius: 3),
  ),
  EditorTextTemplate(
    id: 'script',
    name: 'Script',
    sample: 'With love',
    category: 'Elegant',
    style: EditorTextStyle(
        fontFamily: 'Dancing Script', fontSize: 36, weight: 700),
  ),
  EditorTextTemplate(
    id: 'lobster',
    name: 'Vlog script',
    sample: 'My Vlog',
    category: 'Elegant',
    style: EditorTextStyle(
        fontFamily: 'Lobster',
        fontSize: 34,
        weight: 400,
        color: Color(0xFFFFFFFF),
        glow: Color(0xFFFF7043)),
  ),
  EditorTextTemplate(
    id: 'serif',
    name: 'Serif quote',
    sample: 'Less is more',
    category: 'Elegant',
    style: EditorTextStyle(
        fontFamily: 'Playfair Display',
        fontSize: 28,
        weight: 600,
        italic: true),
  ),
  EditorTextTemplate(
    id: 'minimal',
    name: 'Minimal',
    sample: 'simple things',
    category: 'Elegant',
    style: EditorTextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        weight: 300,
        letterSpacing: 6,
        uppercase: true,
        shadow: false),
  ),
  EditorTextTemplate(
    id: 'gold',
    name: 'Gold',
    sample: 'Premium',
    category: 'Elegant',
    style: EditorTextStyle(
        fontFamily: 'Cinzel',
        fontSize: 30,
        weight: 800,
        gradient: [Color(0xFFFFE9A8), Color(0xFFC9972B), Color(0xFFFFE9A8)],
        letterSpacing: 3,
        shadow: false),
  ),
];

@immutable
class EditorSticker {
  const EditorSticker(this.emoji, this.name);
  final String emoji;
  final String name;

  List<int> get _runes => emoji.runes.toList();

  /// Animated Noto emoji (Google Fonts CDN, CORS enabled).
  String get animatedUrl => 'https://fonts.gstatic.com/s/e/notoemoji/latest/'
      '${_runes.map((r) => r.toRadixString(16)).join('_')}/512.webp';

  /// Static Twemoji PNG (jsDelivr CDN, CORS enabled).
  String get staticUrl =>
      'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/'
      '${_runes.where((r) => r != 0xfe0f).map((r) => r.toRadixString(16)).join('-')}.png';
}

const stickerCategories = <String, List<EditorSticker>>{
  'Faces': [
    EditorSticker('😀', 'Grin'),
    EditorSticker('😂', 'Joy'),
    EditorSticker('🥰', 'Love'),
    EditorSticker('😎', 'Cool'),
    EditorSticker('🤩', 'Star-struck'),
    EditorSticker('😜', 'Wink'),
    EditorSticker('🥳', 'Party'),
    EditorSticker('😴', 'Sleepy'),
    EditorSticker('🤯', 'Mind blown'),
    EditorSticker('🥺', 'Pleading'),
    EditorSticker('😭', 'Cry'),
    EditorSticker('🤔', 'Thinking'),
  ],
  'Love': [
    EditorSticker('❤️', 'Heart'),
    EditorSticker('💖', 'Sparkle heart'),
    EditorSticker('💕', 'Two hearts'),
    EditorSticker('💘', 'Cupid'),
    EditorSticker('💋', 'Kiss'),
    EditorSticker('🌹', 'Rose'),
    EditorSticker('💍', 'Ring'),
    EditorSticker('😍', 'Heart eyes'),
    EditorSticker('💌', 'Love letter'),
    EditorSticker('🫶', 'Heart hands'),
  ],
  'Travel': [
    EditorSticker('✈️', 'Plane'),
    EditorSticker('🏝️', 'Island'),
    EditorSticker('🌴', 'Palm'),
    EditorSticker('🏖️', 'Beach'),
    EditorSticker('🗺️', 'Map'),
    EditorSticker('🧳', 'Luggage'),
    EditorSticker('📸', 'Camera'),
    EditorSticker('🚗', 'Car'),
    EditorSticker('⛰️', 'Mountain'),
    EditorSticker('🌅', 'Sunrise'),
    EditorSticker('☀️', 'Sun'),
    EditorSticker('🌊', 'Wave'),
  ],
  'Party': [
    EditorSticker('🎉', 'Party popper'),
    EditorSticker('🎊', 'Confetti'),
    EditorSticker('🎈', 'Balloon'),
    EditorSticker('🎂', 'Cake'),
    EditorSticker('🎁', 'Gift'),
    EditorSticker('🍾', 'Champagne'),
    EditorSticker('🪩', 'Disco ball'),
    EditorSticker('🎤', 'Mic'),
    EditorSticker('🎧', 'Headphones'),
    EditorSticker('🎶', 'Notes'),
  ],
  'Nature': [
    EditorSticker('🔥', 'Fire'),
    EditorSticker('✨', 'Sparkles'),
    EditorSticker('⭐', 'Star'),
    EditorSticker('🌈', 'Rainbow'),
    EditorSticker('⚡', 'Lightning'),
    EditorSticker('🌸', 'Blossom'),
    EditorSticker('🌻', 'Sunflower'),
    EditorSticker('🍀', 'Clover'),
    EditorSticker('🌙', 'Moon'),
    EditorSticker('❄️', 'Snow'),
    EditorSticker('🦋', 'Butterfly'),
    EditorSticker('🐶', 'Dog'),
  ],
  'Food': [
    EditorSticker('🍕', 'Pizza'),
    EditorSticker('🍔', 'Burger'),
    EditorSticker('🍜', 'Noodles'),
    EditorSticker('🍣', 'Sushi'),
    EditorSticker('🍰', 'Cake slice'),
    EditorSticker('🍦', 'Ice cream'),
    EditorSticker('☕', 'Coffee'),
    EditorSticker('🧋', 'Bubble tea'),
    EditorSticker('🍓', 'Strawberry'),
    EditorSticker('🍉', 'Watermelon'),
  ],
  'Symbols': [
    EditorSticker('👍', 'Thumbs up'),
    EditorSticker('👏', 'Clap'),
    EditorSticker('🙌', 'Hooray'),
    EditorSticker('💯', '100'),
    EditorSticker('✅', 'Check'),
    EditorSticker('❗', 'Exclamation'),
    EditorSticker('❓', 'Question'),
    EditorSticker('🔔', 'Bell'),
    EditorSticker('📍', 'Pin'),
    EditorSticker('👑', 'Crown'),
    EditorSticker('💎', 'Gem'),
    EditorSticker('🚀', 'Rocket'),
  ],
};

// ------------------------------------------------------- sprite stickers

const _phaser =
    'https://raw.githubusercontent.com/phaserjs/examples/master/public/assets/sprites';

/// Real sprite sheets (CORS-enabled GitHub raw URLs).
const builtinSprites = <SpriteSpec>[
  SpriteSpec(
      url: '$_phaser/explosion.png',
      cols: 5,
      rows: 5,
      frames: 23,
      fps: 18,
      name: 'Explosion'),
  SpriteSpec(
      url: '$_phaser/boom32wh12.png',
      cols: 6,
      rows: 2,
      frames: 12,
      fps: 16,
      name: 'Boom'),
  SpriteSpec(
      url: '$_phaser/coin.png',
      cols: 6,
      rows: 1,
      frames: 6,
      fps: 10,
      name: 'Coin'),
  SpriteSpec(
      url: '$_phaser/dude.png',
      cols: 9,
      rows: 1,
      frames: 9,
      fps: 12,
      name: 'Runner'),
];

/// Procedural particle stickers painted by `ParticlePainter`.
const particleStickers = <String, String>{
  'confetti': 'Confetti',
  'hearts': 'Rising hearts',
  'sparkles': 'Sparkles',
  'snow': 'Snow',
  'fireworks': 'Fireworks',
};

// --------------------------------------------------------------- filters

const aspectPresets = <(String, double)>[
  ('9:16', 9 / 16),
  ('16:9', 16 / 9),
  ('1:1', 1),
  ('4:5', 4 / 5),
  ('3:4', 3 / 4),
  ('21:9', 21 / 9),
];
