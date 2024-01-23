import 'package:flutter/material.dart';

const Color lightBrown = Color.fromARGB(255, 205, 193, 180);
const Color darkBrown = Color.fromARGB(255, 187, 173, 160);
const Color tan = Color.fromARGB(255, 238, 228, 218);
const Color greyText = Color.fromARGB(255, 119, 110, 101);

const Map<int, Color> numTileColor = {
  2: tan,
  4: tan,
  8: Color.fromARGB(255, 242, 177, 121),
  16: Color.fromARGB(255, 245, 149, 99),
  32: Color.fromARGB(255, 246, 124, 95),
  64: Color.fromARGB(255, 246, 95, 64),
  128: Color.fromARGB(255, 235, 208, 117),
  256: Color.fromARGB(255, 237, 203, 103),
  512: Color.fromARGB(255, 236, 201, 85),
  1024: Color.fromARGB(255, 229, 194, 90),
  2048: Color.fromARGB(255, 232, 192, 70),
};

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '2048',
      home: TwentyFortyEight(duration: Duration(milliseconds: 200)),
    );
  }
}

class Tile {
  final int x;
  final int y;
  int val;

  late Animation<double> animatedX;
  late Animation<double> animatedY;
  late Animation<int> animatedValue;
  late Animation<double> scale;

  Tile(
    this.x,
    this.y,
    this.val,
  ) {
    resetAnimations();
  }

  void resetAnimations() {
    animatedX = AlwaysStoppedAnimation(x.toDouble());
    animatedY = AlwaysStoppedAnimation(y.toDouble());
    animatedValue = AlwaysStoppedAnimation(val);
    scale = const AlwaysStoppedAnimation(1.0);
  }

  void moveTo(Animation<double> parent, int x, int y) {
    animatedX = Tween(begin: this.x.toDouble(), end: x.toDouble())
        .animate(CurvedAnimation(parent: parent, curve: const Interval(0, .5)));
    animatedY = Tween(begin: this.y.toDouble(), end: y.toDouble())
        .animate(CurvedAnimation(parent: parent, curve: const Interval(0, .5)));
  }

  void bounce(Animation<double> parent) {
    scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1.0),
    ]).animate(CurvedAnimation(parent: parent, curve: const Interval(.5, 1.0)));
  }

  void appear(Animation<double> parent) {
    scale = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: parent, curve: const Interval(.5, 1.0)));
  }

  void changeNumber(Animation<double> parent, int newValue) {
    animatedValue = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(val), weight: .01),
      TweenSequenceItem(tween: ConstantTween(newValue), weight: .99),
    ]).animate(CurvedAnimation(parent: parent, curve: const Interval(.5, 1.0)));
  }
}

class TwentyFortyEight extends StatefulWidget {
  const TwentyFortyEight({super.key, required this.duration});

  final Duration duration;

  @override
  State<TwentyFortyEight> createState() => _TwentyFortyEightState();
}

class _TwentyFortyEightState extends State<TwentyFortyEight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<List<Tile>> grid =
      List.generate(4, (y) => List.generate(4, (x) => Tile(x, y, 0)));
  List<Tile> toAdd = [];
  Iterable<Tile> get flattenedGrid => grid.expand((e) => e);
  Iterable<List<Tile>> get cols =>
      List.generate(4, (x) => List.generate(4, (y) => grid[y][x]));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        for (var e in toAdd) {
          grid[e.y][e.x].val = e.val;
        }
        for (var e in flattenedGrid) {
          e.resetAnimations();
        }
        toAdd.clear();
      }
    });
    grid[1][2].val = 4;
    grid[0][2].val = 4;
    grid[3][2].val = 16;
    grid[0][0].val = 16;

    for (var element in flattenedGrid) {
      element.resetAnimations();
    }
  }

  void addNewTile() {
    List<Tile> empty = flattenedGrid.where((e) => e.val == 0).toList();
    empty.shuffle();
    toAdd.add(Tile(empty.first.x, empty.first.y, 2)..appear(_controller));
  }

  @override
  Widget build(BuildContext context) {
    double gridSize = MediaQuery.of(context).size.width - 16.0 * 2;
    double tileSize = (gridSize - 4.0 * 2) / 4;
    List<Widget> stackItems = [];
    stackItems.addAll(
      [flattenedGrid, toAdd].expand((e) => e).map(
            (e) => Positioned(
              left: e.animatedX.value * tileSize,
              top: e.animatedY.value * tileSize,
              width: tileSize,
              height: tileSize,
              child: Center(
                child: Container(
                  width: (tileSize - 4.0 * 2) * e.scale.value,
                  height: (tileSize - 4.0 * 2) * e.scale.value,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: lightBrown),
                ),
              ),
            ),
          ),
    );
    stackItems.addAll(
      flattenedGrid.map(
        (e) => AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => e.animatedValue.value == 0
              ? const SizedBox()
              : Positioned(
                  left: e.x * tileSize,
                  top: e.y * tileSize,
                  width: tileSize,
                  height: tileSize,
                  child: Center(
                    child: Container(
                      width: tileSize - 4.0 * 2,
                      height: tileSize - 4.0 * 2,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: numTileColor[e.animatedValue.value]),
                      child: Center(
                        child: Text(
                          "${e.animatedValue.value}",
                          style: TextStyle(
                              color: e.animatedValue.value <= 5
                                  ? greyText
                                  : Colors.white,
                              fontSize: 35,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: tan,
      body: Center(
        child: Container(
          width: gridSize,
          height: gridSize,
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0), color: darkBrown),
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -250 && canSwipeUp()) {
                doSwipe(swipeUp);
              } else if (details.velocity.pixelsPerSecond.dy > 250 &&
                  canSwipeDown()) {
                doSwipe(swipeDown);
              }
            },
            onHorizontalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dx < -250 &&
                  canSwipeLeft()) {
                doSwipe(swipeLeft);
              } else if (details.velocity.pixelsPerSecond.dx > 250 &&
                  canSwipeRight()) {
                doSwipe(swipeRight);
              }
            },
            child: Stack(
              children: stackItems,
            ),
          ),
        ),
      ),
    );
  }

  void doSwipe(void Function() swipeFn) {
    setState(() {
      swipeFn();
      addNewTile();
      _controller.forward(from: 0);
    });
  }

  bool canSwipeLeft() => grid.any(canSwipe);
  bool canSwipeRight() => grid.map((e) => e.reversed.toList()).any(canSwipe);
  bool canSwipeUp() => cols.any(canSwipe);
  bool canSwipeDown() => cols.map((e) => e.reversed.toList()).any(canSwipe);

  bool canSwipe(List<Tile> tiles) {
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].val == 0) {
        if (tiles.skip(i + 1).any((e) => e.val != 0)) {
          return true;
        }
      } else {
        Tile nextNonZero = tiles
            .skip(i + 1)
            .firstWhere((e) => e.val != 0, orElse: () => Tile(0, 0, 0));
        if (nextNonZero != Tile(0, 0, 0) && nextNonZero.val == tiles[i].val) {
          return true;
        }
      }
    }
    return false;
  }

  void swipeLeft() => grid.forEach(mergeTiles);
  void swipeRight() => grid.map((e) => e.reversed.toList()).forEach(mergeTiles);
  void swipeUp() => cols.forEach(mergeTiles);
  void swipeDown() => cols.map((e) => e.reversed.toList()).forEach(mergeTiles);

  void mergeTiles(List<Tile> tiles) {
    for (int i = 0; i < tiles.length; i++) {
      Iterable<Tile> toCheck =
          tiles.skip(i).skipWhile((value) => value.val == 0);
      if (toCheck.isNotEmpty) {
        Tile t = toCheck.first;
        Tile merge = toCheck
            .skip(1)
            .firstWhere((t) => t.val != 0, orElse: () => Tile(0, 0, 0));
        if (merge != Tile(0, 0, 0) && merge.val != t.val) {
          merge = Tile(0, 0, 0);
        }
        if (tiles[i] != t || merge != Tile(0, 0, 0)) {
          int resultValue = t.val;
          t.moveTo(_controller, tiles[i].x, tiles[i].y);
          if (merge != Tile(0, 0, 0)) {
            resultValue += merge.val;
            merge.moveTo(_controller, tiles[i].x, tiles[i].y);
            merge.bounce(_controller);
            merge.changeNumber(_controller, resultValue);
            merge.val = 0;
            t.changeNumber(_controller, 0);
          }
          t.val = 0;
          tiles[i].val = resultValue;
        }
      }
    }
  }
}
