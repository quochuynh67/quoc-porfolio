import 'package:flutter/material.dart';

class SortPage extends StatefulWidget {
  const SortPage({super.key});

  @override
  State<SortPage> createState() => _SortPageState();
}

class _SortPageState extends State<SortPage> with TickerProviderStateMixin {
  List<int> numbers = [50, 20, 80, 10, 60, 90, 30];
  List<int> comparing = [];
  List<int> sortedIndices = [];
  bool isSorting = false;
  int speedMs = 400;
  String selectedAlgorithm = 'Bubble Sort';

  double barWidth = 40.0;
  double spacing = 10.0;
  TextEditingController inputController = TextEditingController();
  Duration sortDuration = Duration.zero;

  List<String> pseudoCode = [];
  int pseudoLine = -1;

  List<AnimationController> _positionControllers = [];
  List<Animation<double>> _positionAnimations = [];
  List<double> positions = [];

  final Map<String, List<String>> algorithmPseudocodes = {
    'Bubble Sort': [
      'for i in 0..n-1',
      '  for j in 0..n-i-1',
      '    if arr[j] > arr[j+1]',
      '      swap(arr[j], arr[j+1])',
    ],
    'Selection Sort': [
      'for i in 0..n-1',
      '  min = i',
      '  for j in i+1..n',
      '    if arr[j] < arr[min]',
      '      min = j',
      '  swap(arr[i], arr[min])',
    ],
    'Insertion Sort': [
      'for i in 1..n',
      '  key = arr[i]',
      '  j = i - 1',
      '  while j >= 0 and arr[j] > key',
      '    arr[j + 1] = arr[j]',
      '    j = j - 1',
      '  arr[j + 1] = key',
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializePositions();
  }

  void _initializePositions() {
    _positionControllers.forEach((c) => c.dispose());
    _positionControllers = List.generate(numbers.length, (i) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: speedMs),
      );
    });
    positions = List.generate(numbers.length, (i) => i.toDouble());
    _positionAnimations = List.generate(numbers.length, (i) {
      return Tween<double>(begin: i.toDouble(), end: i.toDouble())
          .animate(_positionControllers[i]);
    });
  }

  void reset() {
    setState(() {
      numbers = [50, 20, 80, 10, 60, 90, 30];
      comparing = [];
      sortedIndices = [];
      isSorting = false;
      inputController.clear();
      sortDuration = Duration.zero;
      pseudoLine = -1;
      pseudoCode = algorithmPseudocodes[selectedAlgorithm]!;
      _initializePositions();
    });
  }

  void updateFromInput() {
    final input = inputController.text.trim();
    final parts = input.split(RegExp(r'[\s,]+'));
    final parsed = <int>[];
    for (var p in parts) {
      final n = int.tryParse(p);
      if (n != null) parsed.add(n);
    }
    if (parsed.isNotEmpty) {
      setState(() {
        numbers = parsed;
        sortedIndices = [];
        _initializePositions();
      });
    }
  }

  Future<void> startSort() async {
    setState(() {
      isSorting = true;
      sortedIndices = [];
      sortDuration = Duration.zero;
      pseudoLine = -1;
      pseudoCode = algorithmPseudocodes[selectedAlgorithm]!;
    });

    final stopwatch = Stopwatch()..start();

    switch (selectedAlgorithm) {
      case 'Bubble Sort':
        await bubbleSort();
        break;
      case 'Selection Sort':
        await selectionSort();
        break;
      case 'Insertion Sort':
        await insertionSort();
        break;
    }

    stopwatch.stop();

    setState(() {
      comparing = [];
      isSorting = false;
      sortDuration = stopwatch.elapsed;
      sortedIndices = List.generate(numbers.length, (i) => i);
      pseudoLine = -1;
    });
  }

  Future<void> bubbleSort() async {
    final n = numbers.length;
    for (int i = 0; i < n - 1; i++) {
      setState(() => pseudoLine = 0);
      for (int j = 0; j < n - i - 1; j++) {
        setState(() {
          comparing = [j, j + 1];
          pseudoLine = 2;
        });
        await Future.delayed(Duration(milliseconds: speedMs));
        if (numbers[j] > numbers[j + 1]) {
          setState(() => pseudoLine = 3);
          await animateSwap(j, j + 1);
        }
      }
      setState(() {
        sortedIndices.add(n - i - 1);
      });
    }
    setState(() {
      sortedIndices = List.generate(n, (i) => i);
    });
  }

  Future<void> selectionSort() async {
    final n = numbers.length;
    for (int i = 0; i < n; i++) {
      setState(() => pseudoLine = 0);
      int minIdx = i;
      setState(() => pseudoLine = 1);
      for (int j = i + 1; j < n; j++) {
        setState(() {
          comparing = [minIdx, j];
          pseudoLine = 3;
        });
        await Future.delayed(Duration(milliseconds: speedMs));
        if (numbers[j] < numbers[minIdx]) {
          minIdx = j;
        }
      }
      if (i != minIdx) {
        setState(() => pseudoLine = 5);
        await animateSwap(i, minIdx);
      }
      setState(() {
        sortedIndices.add(i);
      });
    }
    setState(() {
      sortedIndices = List.generate(n, (i) => i);
    });
  }

  Future<void> insertionSort() async {
    final n = numbers.length;
    for (int i = 1; i < n; i++) {
      int j = i;
      setState(() => pseudoLine = 0);
      while (j > 0 && numbers[j - 1] > numbers[j]) {
        setState(() {
          comparing = [j - 1, j];
          pseudoLine = 3;
        });
        await animateSwap(j - 1, j);
        j--;
      }
    }
    setState(() {
      sortedIndices = List.generate(n, (i) => i);
    });
  }

  Future<void> animateSwap(int i, int j) async {
    // Swap numbers
    final tempNum = numbers[i];
    numbers[i] = numbers[j];
    numbers[j] = tempNum;

    // Swap positions
    final tempPos = positions[i];
    positions[i] = positions[j];
    positions[j] = tempPos;

    _positionControllers[i].reset();
    _positionControllers[j].reset();

    _positionAnimations[i] = Tween<double>(
      begin: tempPos,
      end: positions[i],
    ).animate(_positionControllers[i]);

    _positionAnimations[j] = Tween<double>(
      begin: positions[i],
      end: positions[j],
    ).animate(_positionControllers[j]);

    _positionControllers[i].forward();
    _positionControllers[j].forward();

    await Future.delayed(Duration(milliseconds: speedMs));
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = numbers.isNotEmpty
        ? numbers.reduce((a, b) => a > b ? a : b).toDouble()
        : 1;
    final totalWidth =
        numbers.length * barWidth + (numbers.length - 1) * spacing;
    final widthFactor = totalWidth > MediaQuery.of(context).size.width
        ? MediaQuery.of(context).size.width / totalWidth
        : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Sort Visualizer")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: inputController,
              onSubmitted: (_) => updateFromInput(),
              decoration: const InputDecoration(
                labelText: "Nhập danh sách số (vd: 50, 20, 30...)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isSorting ? null : updateFromInput,
              child: const Text("Cập nhật danh sách"),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedAlgorithm,
              items: algorithmPseudocodes.keys
                  .map((algo) =>
                      DropdownMenuItem(value: algo, child: Text(algo)))
                  .toList(),
              onChanged: isSorting
                  ? null
                  : (value) => setState(() => selectedAlgorithm = value!),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Tốc độ:"),
                SizedBox(
                  height: 40,
                  child: Slider(
                    value: speedMs.toDouble(),
                    min: 50,
                    max: 1000,
                    divisions: 20,
                    label: "$speedMs ms",
                    onChanged: isSorting
                        ? null
                        : (val) => setState(() => speedMs = val.toInt()),
                  ),
                ),
              ],
            ),
            if (sortDuration != Duration.zero)
              Text("⏱️ Thời gian chạy: ${sortDuration.inMilliseconds}ms"),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.builder(
                itemCount: pseudoCode.length,
                itemBuilder: (_, i) => Container(
                  color: i == pseudoLine ? Colors.yellow[300] : null,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(pseudoCode[i]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                ...List.generate(numbers.length, (i) {
                  final height = 150 * (numbers[i] / maxVal);
                  return AnimatedBuilder(
                    animation: _positionControllers[i],
                    builder: (context, child) {
                      final x = _positionAnimations[i].value *
                          (barWidth * widthFactor + spacing);
                      return Positioned(
                        left: x,
                        bottom: 0,
                        child: Column(
                          children: [
                            Text(
                              numbers[i].toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Container(
                              width: barWidth * widthFactor,
                              height: height,
                              color: sortedIndices.contains(i)
                                  ? Colors.green
                                  : comparing.contains(i)
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
                CustomPaint(
                  size: const Size(double.infinity, 250),
                  painter: BezierSwapPainter(
                    comparing: comparing,
                    animations: _positionAnimations,
                    barWidth: barWidth * widthFactor,
                    spacing: spacing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isSorting ? null : startSort,
                  child: const Text("Start Sort"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: isSorting ? null : reset,
                  child: const Text("Reset"),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class BezierSwapPainter extends CustomPainter {
  final List<int> comparing;
  final List<Animation<double>> animations;
  final double barWidth;
  final double spacing;

  BezierSwapPainter({
    required this.comparing,
    required this.animations,
    required this.barWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (comparing.length != 2) return;

    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final i = comparing[0];
    final j = comparing[1];
    final x1 = animations[i].value * (barWidth + spacing) + barWidth / 2;
    final x2 = animations[j].value * (barWidth + spacing) + barWidth / 2;
    const y = 150.0; // Fixed height for the bezier curve

    final path = Path();
    path.moveTo(x1, y);
    path.cubicTo(x1, y - 20, x2, y - 20, x2, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
