import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache ảnh coin lấy từ CDN của CoinGecko.
class AppImageCacheManager {
  static const String cacheKey = 'coin_image_cache';

  static final CacheManager instance = CacheManager(
    Config(
      cacheKey,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: cacheKey),
      fileService: HttpFileService(),
    ),
  );
}
