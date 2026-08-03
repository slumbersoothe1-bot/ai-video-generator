/// A viral hook template with a prediction score.
class ViralHook {
  const ViralHook({
    required this.text,
    required this.niche,
    required this.score,
    required this.reason,
    required this.language,
  });

  final String text;
  final String niche;
  final int score;
  final String reason;
  final String language;
}

/// Supported languages for multi-lingual content generation.
const List<String> kSupportedLanguages = [
  'English',
  'Arabic',
  'French',
  'Spanish',
  'German',
  'Portuguese',
  'Hindi',
  'Turkish',
  'Indonesian',
  'Korean',
  'Japanese',
  'Chinese',
];

const Map<String, String> kLanguageFlags = {
  'English': '🇬🇧',
  'Arabic': '🇪🇬',
  'French': '🇫🇷',
  'Spanish': '🇪🇸',
  'German': '🇩🇪',
  'Portuguese': '🇧🇷',
  'Hindi': '🇮🇳',
  'Turkish': '🇹🇷',
  'Indonesian': '🇮🇩',
  'Korean': '🇰🇷',
  'Japanese': '🇯🇵',
  'Chinese': '🇨🇳',
};

/// Available niches for viral content.
const List<String> kNiches = [
  'Fitness',
  'Fashion',
  'Food',
  'Tech',
  'Travel',
  'Business',
  'Beauty',
  'Gaming',
  'Education',
  'Lifestyle',
  'Real Estate',
  'Crypto',
];

/// The Viral Hook Engine generates high-converting first-3-second hooks
/// and multi-lingual marketing scripts with a viral prediction score.
class ViralHookEngine {
  ViralHookEngine._();

  /// Generates viral hooks for a niche and language.
  static List<ViralHook> generate({
    required String niche,
    String language = 'English',
    int count = 5,
  }) {
    final hooks = _hookCatalog[niche] ?? _hookCatalog['Lifestyle']!;
    final scored = hooks.map((h) {
      final score = _scoreHook(h, niche);
      final reason = _scoreReason(score);
      return ViralHook(
        text: h,
        niche: niche,
        score: score,
        reason: reason,
        language: language,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(count).toList();
  }

  /// Generates a multi-lingual marketing script for a product/niche.
  static String generateScript({
    required String niche,
    required String language,
    String? productName,
  }) {
    final templates = _scriptTemplates[niche] ?? _scriptTemplates['Lifestyle']!;
    final template = templates[0];
    final product = productName?.isNotEmpty == true ? productName! : 'your product';

    if (language == 'English') {
      return template.replaceAll('{product}', product);
    }

    final translations = _scriptTranslations[language];
    if (translations != null) {
      return translations
          .replaceAll('{product}', product)
          .replaceAll('{niche}', niche.toLowerCase());
    }

    return template.replaceAll('{product}', product);
  }

  static int _scoreHook(String hook, String niche) {
    int score = 60;
    if (hook.contains('?')) score += 12;
    if (hook.contains('Stop') || hook.contains('Wait') || hook.contains('Don\'t')) score += 15;
    if (hook.contains('secret') || hook.contains('nobody') || hook.contains('hidden')) score += 10;
    if (hook.contains('you') || hook.contains('your')) score += 8;
    if (hook.length < 80) score += 10;
    if (hook.length < 50) score += 5;
    if (hook.contains('in 2024') || hook.contains('today') || hook.contains('now')) score += 8;
    return score.clamp(0, 99);
  }

  static String _scoreReason(int score) {
    if (score >= 85) return 'Exceptional hook — pattern interrupt + curiosity gap';
    if (score >= 75) return 'Strong hook — high emotional trigger';
    if (score >= 65) return 'Good hook — solid attention grabber';
    return 'Decent hook — consider adding a stronger opening';
  }

  static const Map<String, List<String>> _hookCatalog = {
    'Fitness': [
      'Stop scrolling if you want abs in 30 days — this one exercise changed everything',
      'Nobody tells you this about belly fat, but it\'s the #1 reason you can\'t lose it',
      'Wait... you\'ve been doing push-ups wrong your entire life? Here\'s the fix',
      'The 5-minute morning routine that burns more fat than a 1-hour gym session',
      'Don\'t buy another protein powder until you watch this',
    ],
    'Fashion': [
      'Stop buying fast fashion — these 3 pieces will transform your entire wardrobe',
      'Nobody notices this one detail, but it\'s why your outfits always look off',
      'Wait... you\'re wearing the wrong size? Here\'s how to tell in 10 seconds',
      'The \$10 accessory that makes a \$200 outfit look like \$2,000',
      'Don\'t wear these colors together in 2024 — here\'s what to wear instead',
    ],
    'Food': [
      'Stop making rice like that — this one trick makes it perfect every time',
      'Nobody talks about this secret ingredient, but it changes everything',
      'Wait... you\'ve been storing coffee wrong this whole time?',
      'The 3-ingredient recipe that went viral in 5 countries',
      'Don\'t buy pre-cut fruit until you see this money-saving hack',
    ],
    'Tech': [
      'Stop paying for these 5 apps — your phone already does it for free',
      'Nobody uses this iPhone feature, but it\'s the most powerful one',
      'Wait... your phone is tracking you right now? Here\'s how to stop it',
      'The \$0 AI tool that replaces a \$500/month subscription',
      'Don\'t update your phone until you watch this',
    ],
    'Travel': [
      'Stop booking flights on these days — you\'re overpaying by 40%',
      'Nobody knows about this hidden island, but it\'s the most beautiful place on Earth',
      'Wait... you can travel for free? Here\'s the credit card hack nobody talks about',
      'The 3 countries where your \$100 feels like \$1,000',
      'Don\'t stay in hotels until you try this alternative',
    ],
    'Business': [
      'Stop cold-calling — this one LinkedIn message gets 80% reply rates',
      'Nobody talks about this side hustle, but it makes \$10K/month with zero skills',
      'Wait... you\'re leaving money on the table? Here\'s the tax deduction you\'re missing',
      'The 3-step framework that turned a \$0 startup into a \$1M business',
      'Don\'t start a business until you validate it with this test',
    ],
    'Beauty': [
      'Stop using moisturizer first — this is the correct skincare order nobody tells you',
      'Nobody notices this, but your pillowcase is causing your breakouts',
      'Wait... you\'ve been applying concealer wrong? Here\'s the right way',
      'The \$5 drugstore product that works better than a \$200 serum',
      'Don\'t buy expensive hair masks — this kitchen ingredient works 10x better',
    ],
    'Gaming': [
      'Stop playing this map — here\'s the secret spot nobody knows about',
      'Nobody uses this weapon, but it\'s actually the most overpowered in the game',
      'Wait... you\'re missing this hidden achievement? Here\'s how to get it',
      'The 3 settings every pro player changes immediately',
      'Don\'t buy the battle pass until you see this trick',
    ],
    'Education': [
      'Stop highlighting your notes — science says this method is 10x more effective',
      'Nobody teaches math like this, but it makes calculus feel like first grade',
      'Wait... you\'ve been studying wrong? Here\'s what neuroscience says',
      'The 5-minute trick that helps you remember anything forever',
      'Don\'t pay for a course when this free resource is 10x better',
    ],
    'Lifestyle': [
      'Stop doing morning routines like that — this 3-minute version works better',
      'Nobody talks about this habit, but it changed my entire life in 30 days',
      'Wait... your morning coffee is making you more tired? Here\'s why',
      'The simple evening routine that guarantees better sleep tonight',
      'Don\'t buy organizers until you try this decluttering method',
    ],
    'Real Estate': [
      'Stop touring houses without this one checklist item — it\'ll save you thousands',
      ' Nobody knows this first-time buyer program, but it covers your entire down payment',
      'Wait... you can negotiate your mortgage rate? Here\'s exactly what to say',
      'The 3 upgrades that increase home value by 15% for under \$5,000',
      'Don\'t rent another year until you see this ownership hack',
    ],
    'Crypto': [
      'Stop buying random coins — this 3-step research method finds the real gems',
      'Nobody talks about this on-chain metric, but it predicts every major move',
      'Wait... you\'re paying 30% extra in hidden fees? Here\'s how to avoid them',
      'The simple strategy that turned \$100 into \$10K in one bull cycle',
      'Don\'t hold coins in your exchange wallet — here\'s why it\'s dangerous',
    ],
  };

  static const Map<String, List<String>> _scriptTemplates = {
    'Fitness': 'Stop scrolling. If you want real results in 30 days, {product} is your shortcut. No more guessing — just follow the plan. Tap the link to start your transformation today.',
    'Fashion': 'Your wardrobe deserves better. {product} gives you that designer look without the designer price. Limited drop — tap before it\'s gone.',
    'Food': 'You\'ve been missing this flavor your whole life. {product} changes everything in your kitchen. Get yours now and taste the difference.',
    'Tech': 'Why pay \$500/month when {product} does it all for free? This is the upgrade you didn\'t know you needed. Tap to get started.',
    'Travel': 'Your dream trip is closer than you think. {product} makes luxury travel affordable. Book now and save 40% this week only.',
    'Business': 'Ready to scale? {product} automates the boring stuff so you can focus on growth. Start your free trial today.',
    'Beauty': 'The glow-up starts here. {product} is the secret your favorite influencer isn\'t telling you about. Tap to get yours.',
    'Gaming': 'Level up instantly. {product} gives you the edge every pro uses. Don\'t play without it — get yours now.',
    'Education': 'Learn faster, remember more. {product} uses science-backed methods to 10x your study efficiency. Start learning today.',
    'Lifestyle': 'Upgrade your daily routine. {product} makes every morning feel effortless. Tap to transform your life today.',
    'Real Estate': 'Your first home is within reach. {product} guides you from zero to keys in hand. Start your journey today.',
    'Crypto': 'Don\'t let another cycle pass you by. {product} gives you the tools the pros use to find gems. Start your research now.',
  };

  static const Map<String, String> _scriptTranslations = {
    'Arabic': 'توقف عن التمرير. إذا كنت تريد نتائج حقيقية في 30 يومًا، فإن {product} هو اختصارك. لا مزيد من التخمين - فقط اتبع الخطة. اضغط على الرابط لبدء تحولك اليوم.',
    'French': 'Arrêtez de défiler. Si vous voulez des résultats réels en 30 jours, {product} est votre raccourci. Plus de devinettes — suivez simplement le plan. Touchez le lien pour commencer votre transformation aujourd\'hui.',
    'Spanish': 'Deja de deslizar. Si quieres resultados reales en 30 días, {product} es tu atajo. No más adivinanzas — solo sigue el plan. Toca el enlace para comenzar tu transformación hoy.',
    'German': 'Hör auf zu scrollen. Wenn du in 30 Tagen echte Ergebnisse willst, ist {product} deine Abkürzung. Kein Raten mehr — folge einfach dem Plan. Tippe auf den Link, um heute zu starten.',
    'Portuguese': 'Pare de rolar. Se você quer resultados reais em 30 dias, {product} é o seu atalho. Chega de adivinhação — siga o plano. Toque no link para começar sua transformação hoje.',
    'Hindi': 'स्क्रॉल करना बंद करें। अगर आप 30 दिनों में असली नतीजे चाहते हैं, तो {product} आपका शॉर्टकट है। अब अंदाजा नहीं — बस प्लान फॉलो करें। आज ही ट्रांसफॉर्मेशन शुरू करने के लिए लिंक टैप करें।',
    'Turkish': 'Kaydırmayı durdur. 30 günde gerçek sonuçlar istiyorsan, {product} senin kısayolun. Artık tahmin yok — sadece planı takip et. Dönüşümüne bugün başlamak için linke dokun.',
    'Indonesian': 'Berhenti scroll. Kalau kamu mau hasil nyata dalam 30 hari, {product} adalah jalan pintas kamu. Tidak perlu menebak lagi — ikuti saja rencananya. Ketuk tautan untuk memulai transformasi kamu hari ini.',
    'Korean': '스크롤을 멈추세요. 30일 안에 진짜 결과를 원한다면, {product}가 지름길입니다. 더 이상 추측하지 마세요 — 그냥 계획을 따르세요. 오늘 변화를 시작하려면 링크를 탭하세요.',
    'Japanese': 'スクロールを止めて。30日で本当の結果を出したいなら、{product}があなたの近道です。もう推測は不要 — プランに従うだけ。今日から変身を始めるにはリンクをタップ。',
    'Chinese': '停止滑动。如果你想在30天内看到真正的效果，{product}就是你的捷径。不用再猜了 — 只需按计划来。点击链接，今天就开始你的蜕变。',
  };
}
