import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:moonlander/components/pause_component.dart';
import 'package:moonlander/components/rocket_component.dart';
import 'package:moonlander/game_state.dart';
import 'package:moonlander/widgets/pause_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();

  final game = MoonlanderGame();

  runApp(
    MaterialApp(
      theme: ThemeData(
        ///From here https://www.dafont.com/de/aldo-the-apache.font
        fontFamily: 'AldotheApache',
      ),
      home: GameWidget(
        game: game,
        //Work in progress loading screen on game start
        loadingBuilder: (context) => const Material(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        //Work in progress error handling
        errorBuilder: (context, ex) {
          //Print the error in th dev console
          debugPrint(ex.toString());
          return const Material(
            child: Center(
              child: Text('Sorry, something went wrong. Reload me'),
            ),
          );
        },
        overlayBuilderMap: {
          'pause': (context, MoonlanderGame game) => PauseMenu(game: game),
          // 'levelSelection': (context, MoonlanderGame game) => LevelSelection(
          //       game,
          //     ),
          // 'highscore': (context, MoonlanderGame game) =>
          //     HighscoreOverview(game),
          // 'enterSeed': (context, MoonlanderGame game) => EnterSeed(game),
        },
      ),
    ),
  );
}

/// This class encapulates the whole game.
class MoonlanderGame extends FlameGame
    with
        HasCollisionDetection,
        HasTappables,
        HasKeyboardHandlerComponents,
        HasDraggables {
  ///Interface to play audio
  // late final MoonLanderAudioPlayer audioPlayer;

  late final RocketComponent _rocket;

  ///The rocket component currnetly in the game
  RocketComponent get rocket => _rocket;

  /// Depending on the active overlay state we turn of the engine or not.
  void onOverlayChanged() {
    if (overlays.value.isNotEmpty) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  @override
  bool get debugMode => true;
  // GameState.showDebugInfo;

  /// Restart the current level.
  void restart() {
    // GameState.playState = PlayingState.playing;
    // (children.firstWhere((child) => child is RocketComponent)
    //         as RocketComponent)
    // .reset();
    // children.query<MapComponent>().first.resetPowerups();
  }

  @override
  void onMount() {
    overlays.addListener(onOverlayChanged);
    super.onMount();
  }

  @override
  void onRemove() {
    overlays.removeListener(onOverlayChanged);
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    final image = await images.load('joystick.png');
    final sheet = SpriteSheet.fromColumnsAndRows(
      image: image,
      columns: 6,
      rows: 1,
    );
    // camera.viewport = FixedVerticalResolutionViewpor(800);
    //Init and load the audio assets
    // audioPlayer = MoonLanderAudioPlayer();
    // await audioPlayer.loadAssets();

    ///Ensure our joystick knob is between 50 and 100 based on view height
    ///Important its based on device size not viewport size
    ///8.2 is the "magic" hud joystick factor... ;)
    final knobSize = min(max(50, size.y / 8.2), 100).toDouble();

    final joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: sheet.getSpriteById(1),
        size: Vector2.all(knobSize),
      ),
      background: SpriteComponent(
        sprite: sheet.getSpriteById(0),
        size: Vector2.all(knobSize * 1.5),
      ),
      margin: const EdgeInsets.only(left: 10, bottom: 10),
    );
    _rocket = RocketComponent(
      position: size / 2,
      size: Vector2(32, 48),
      joystick: joystick,
    );

    camera.followComponent(_rocket);
    await add(_rocket);
    await add(joystick);
    // children.register<MapComponent>();
    // await add(MapComponent(mapSeed: GameState.seed.hashCode));
    // await add(RocketInfo(_rocket));

    await add(
      PauseComponent(
        margin: const EdgeInsets.only(
          top: 10,
          left: 5,
        ),
        sprite: await Sprite.load('PauseButton.png'),
        spritePressed: await Sprite.load('PauseButtonInvert.png'),
        onPressed: () {
          if (overlays.isActive('levelSelection')) {
            return;
          }
          if (overlays.isActive('pause')) {
            overlays.remove('pause');
            if (GameState.playState == PlayingState.paused) {
              GameState.playState = PlayingState.playing;
            }
          } else {
            if (GameState.playState == PlayingState.playing) {
              GameState.playState = PlayingState.paused;
            }

            overlays.add('pause');
          }
        },
      ),
    );
    // overlays.
    overlays.addListener(onOverlayChanged);
    return super.onLoad();
  }

  ///Load the level based on the given seed
  Future<void> loadLevel(String seed) async {
    restart();
    // GameState.seed = seed;
    // removeAll(children.query<MapComponent>());
    // await add(MapComponent(mapSeed: seed.hashCode));
    _removeAnyOverlay();
  }

  void _removeAnyOverlay() {
    for (final activeOverlay in overlays.value.toList()) {
      overlays.remove(activeOverlay);
    }
  }
}
