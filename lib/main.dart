import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Particle Network",
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Random random = Random();
  GlobalKey paintKey = GlobalKey();
  late Timer timer;
  List<Particle> particles = [];
  Offset? mousePosition;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ 60), update);
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) => generate());
    super.initState();
  }

  void update(Timer _timer) {
    setState(() {});
  }

  void generate() async {
    Size size = getPaintSize();
    particles.clear();
    particles.addAll(List<Particle>.generate(50, (index) => Particle.generate(size.width, size.height, -1, -1)));
    particles.addAll(List<Particle>.generate(50, (index) => Particle.generate(size.width, size.height, 1, -1)));
    particles.addAll(List<Particle>.generate(50, (index) => Particle.generate(size.width, size.height, -1, 1)));
    particles.addAll(List<Particle>.generate(50, (index) => Particle.generate(size.width, size.height, 1, 1)));
  }

  Size getPaintSize() {
    RenderBox? renderBox = paintKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size ?? const Size(400, 400);
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener(
        onNotification: (SizeChangedLayoutNotification notification) {
          WidgetsBinding.instance?.addPostFrameCallback((timeStamp) => generate());
          return true;
        },
        child: SizeChangedLayoutNotifier(
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: const Color.fromARGB(255, 46, 46, 46))),
              Positioned.fill(
                key: paintKey,
                child: MouseRegion(
                  onHover: (event) {
                    setState(() {
                      mousePosition = event.localPosition;
                    });
                  },
                  onExit: (event) {
                    setState(() {
                      mousePosition = null;
                    });
                  },
                  child: CustomPaint(
                    painter: MyPainter(particles: particles, mousePosition: mousePosition),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } 
}

class MyPainter extends CustomPainter {
  List<Particle> particles;
  Offset? mousePosition;
  MyPainter({
    required this.particles,
    this.mousePosition,
  });
  @override
  void paint(Canvas canvas, Size size) {
    Color circleColor = Colors.amber;
    Color lineColor = Colors.amber;
    Paint paint = Paint();
    paint.color = circleColor;
    paint.style = PaintingStyle.fill;
    Paint paintLine = Paint();
    paintLine.color = lineColor;
    paintLine.style = PaintingStyle.stroke;

    for (var elementOne in particles) {
      elementOne.travel(size);
      if (mousePosition != null) {
        double distance = sqrt(pow(mousePosition!.dx - elementOne.position.dx, 2).toDouble() + pow(mousePosition!.dy - elementOne.position.dy, 2).toDouble());
        if (distance < 100) {
          paintLine.color = lineColor.withOpacity(1.0 - (distance / 100));
          canvas.drawLine(mousePosition!, elementOne.position, paintLine);
        }
      }
      for (var elementTwo in particles) {
        double distance = sqrt(pow(elementTwo.position.dx - elementOne.position.dx, 2).toDouble() + pow(elementTwo.position.dy - elementOne.position.dy, 2).toDouble());
        if (distance < 100) {
          paintLine.color = lineColor.withOpacity(1.0 - (distance / 100));
          canvas.drawLine(elementTwo.position, elementOne.position, paintLine);
        }
      }
    }
    for (var elementOne in particles) {
      canvas.drawCircle(elementOne.position, elementOne.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  double radius;
  Offset position;
  Offset velocity;
  Particle({
    required this.radius,
    required this.position,
    required this.velocity,
  });

  factory Particle.generate(double width, double height, int xDirection, int yDirection) {
    return Particle(
      radius: RandomNum.nextDouble(min: 2.0, max: 4.0),
      position: Offset(RandomNum.nextDouble(min: 10, max: width - 10), RandomNum.nextDouble(min: 10, max: height - 10)),
      velocity: Offset(RandomNum.nextDouble(min: 0.05, max: 0.2) * xDirection, RandomNum.nextDouble(min: 0.05, max: 0.2) * yDirection),
    );
  }

  void travel(Size canvas) {
    if (position.dx + velocity.dx > canvas.width - radius || position.dx + velocity.dx < radius) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy + velocity.dy > canvas.height - radius || position.dy + velocity.dy < radius) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }
    position = Offset(position.dx + velocity.dx, position.dy + velocity.dy);
  }
}

class RandomNum {
  static final Random _random = Random(DateTime.now().millisecondsSinceEpoch);

  static double nextDouble({double min = 0, required double max}) {
    return _random.nextDouble() * (max - min) + min;
  }

  static int nextInt({int min = 0, required int max}) {
    return min + _random.nextInt(max - min);
  }
}