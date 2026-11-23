import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';

class GameFallingItem {
  final String id;
  final String emoji;
  final int points;
  double x; // 0.0 to 1.0
  double y; // 0.0 to 1.0
  final double speed;

  GameFallingItem({
    required this.id,
    required this.emoji,
    required this.points,
    required this.x,
    this.y = 0.0,
    required this.speed,
  });
}

class VaultMiniGameController extends GetxController {
  final playerX = 0.5.obs; // 0.0 (left) to 1.0 (right)
  final score = 0.obs;
  final highScore = 0.obs;
  final items = <GameFallingItem>[].obs;
  final isPlaying = true.obs;
  final catchEffectEmoji = ''.obs;

  Timer? _gameLoopTimer;
  Timer? _spawnTimer;
  final _random = Random();

  @override
  void onInit() {
    super.onInit();
    startGame();
  }

  void startGame() {
    score.value = 0;
    items.clear();
    playerX.value = 0.5;
    isPlaying.value = true;
    _gameLoopTimer?.cancel();
    _spawnTimer?.cancel();

    // Spawn 2 initial items immediately with staggered positions
    items.add(
      GameFallingItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_init1',
        emoji: '📄',
        points: 10,
        x: 0.35,
        y: 0.15,
        speed: 0.024,
      ),
    );
    items.add(
      GameFallingItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_init2',
        emoji: '🛡️',
        points: 15,
        x: 0.65,
        y: 0.35,
        speed: 0.022,
      ),
    );

    // 60 FPS update loop
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _updateGameStep();
    });

    // Spawn falling items every 650ms
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (isPlaying.value) {
        _spawnItem();
      }
    });
  }

  void _spawnItem() {
    final typeRoll = _random.nextInt(10);
    String emoji = '📄';
    int pts = 10;
    double spd = 0.02 + (_random.nextDouble() * 0.015);

    if (typeRoll == 0 || typeRoll == 1) {
      emoji = '🔑';
      pts = 25;
      spd += 0.008;
    } else if (typeRoll == 2 || typeRoll == 3) {
      emoji = '🛡️';
      pts = 15;
    } else if (typeRoll == 4) {
      emoji = '⭐';
      pts = 30;
      spd += 0.01;
    }

    items.add(
      GameFallingItem(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        emoji: emoji,
        points: pts,
        x: 0.08 + (_random.nextDouble() * 0.84),
        speed: spd,
      ),
    );
  }

  void _updateGameStep() {
    if (!isPlaying.value) return;

    final caughtList = <GameFallingItem>[];
    final missedList = <GameFallingItem>[];

    for (final item in items) {
      item.y += item.speed;

      // Check collision with player paddle (at y ~ 0.78 to 0.94)
      if (item.y >= 0.78 && item.y <= 0.94) {
        final dist = (item.x - playerX.value).abs();
        if (dist <= 0.13) {
          caughtList.add(item);
        }
      } else if (item.y > 1.05) {
        missedList.add(item);
      }
    }

    for (final caught in caughtList) {
      items.remove(caught);
      score.value += caught.points;
      if (score.value > highScore.value) {
        highScore.value = score.value;
      }
      catchEffectEmoji.value = '+${caught.points} ${caught.emoji}';
      Future.delayed(const Duration(milliseconds: 400), () {
        if (catchEffectEmoji.value.startsWith('+${caught.points}')) {
          catchEffectEmoji.value = '';
        }
      });
    }

    for (final missed in missedList) {
      items.remove(missed);
    }

    items.refresh();
  }

  void moveLeft() {
    playerX.value = (playerX.value - 0.09).clamp(0.06, 0.94);
  }

  void moveRight() {
    playerX.value = (playerX.value + 0.09).clamp(0.06, 0.94);
  }

  void setPlayerPosition(double normalizedX) {
    playerX.value = normalizedX.clamp(0.06, 0.94);
  }

  @override
  void onClose() {
    _gameLoopTimer?.cancel();
    _spawnTimer?.cancel();
    super.onClose();
  }
}
