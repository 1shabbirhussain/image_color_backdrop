import 'package:flutter/material.dart';
import 'package:image_color_backdrop/image_color_backdrop.dart';

void main() => runApp(const ExampleApp());

/// The sample images bundled with the example app.
const List<({String label, String asset})> samples = [
  (
    label: 'Coral bolt (transparent PNG)',
    asset: 'assets/samples/coral_bolt.png',
  ),
  (label: 'Teal ring (transparent PNG)', asset: 'assets/samples/teal_ring.png'),
  (label: 'Amber hexagon', asset: 'assets/samples/amber_hex.png'),
  (label: 'Purple badge', asset: 'assets/samples/purple_badge.png'),
  (
    label: 'Indigo diamond (full bleed)',
    asset: 'assets/samples/indigo_diamond.png',
  ),
  (label: 'Green apple on white', asset: 'assets/samples/green_on_white.png'),
  (label: 'White mark on dark', asset: 'assets/samples/white_on_dark.png'),
  (label: 'Sunset', asset: 'assets/samples/sunset.png'),
];

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'image_color_backdrop',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = <Widget>[
    GalleryPage(),
    PlaygroundPage(),
    UseTheColorPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('image_color_backdrop')),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Gallery'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Playground'),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            label: 'Use the color',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Gallery: ImageBackdrop.image with different styles.
// ---------------------------------------------------------------------------

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Section('Solid (default: dominant color)'),
        _row(const BackdropOptions(), BackdropStyle.original),
        const _Section('Soft tint: BackdropStyle.soft'),
        _row(const BackdropOptions(), BackdropStyle.soft),
        const _Section('Pastel: BackdropStyle.pastel'),
        _row(const BackdropOptions(), BackdropStyle.pastel),
        const _Section('Deep: BackdropStyle.deep'),
        _row(const BackdropOptions(), BackdropStyle.deep),
        const _Section('Vibrant strategy + ignore white studio backgrounds'),
        _row(
          const BackdropOptions(
            strategy: BackdropStrategy.vibrant,
            ignoreNearWhite: true,
          ),
          BackdropStyle.original,
        ),
        const _Section('Edges only: match what surrounds the logo'),
        _row(
          const BackdropOptions(region: BackdropRegion.edges),
          BackdropStyle.original,
        ),
        const _Section('Tonal gradient'),
        _row(
          const BackdropOptions(),
          BackdropStyle.original,
          gradient: BackdropGradientMode.tonal,
        ),
        const _Section('Palette gradient'),
        _row(
          const BackdropOptions(),
          BackdropStyle.original,
          gradient: BackdropGradientMode.palette,
        ),
      ],
    );
  }

  Widget _row(
    BackdropOptions options,
    BackdropStyle style, {
    BackdropGradientMode gradient = BackdropGradientMode.none,
  }) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: samples.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => ImageBackdrop.image(
          image: AssetImage(samples[i].asset),
          options: options,
          style: style,
          gradientMode: gradient,
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Playground: change every option live.
// ---------------------------------------------------------------------------

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  int _sample = 0;
  BackdropStrategy _strategy = BackdropStrategy.dominant;
  BackdropGradientMode _gradient = BackdropGradientMode.none;
  bool _ignoreWhite = false;
  bool _edges = false;
  double _opacity = 1;
  double _brightness = 0;
  double _saturation = 0;

  @override
  Widget build(BuildContext context) {
    final image = AssetImage(samples[_sample].asset);
    final options = BackdropOptions(
      strategy: _strategy,
      ignoreNearWhite: _ignoreWhite,
      region: _edges ? BackdropRegion.edges : BackdropRegion.whole,
    );
    final style = BackdropStyle(
      opacity: _opacity,
      brightness: _brightness,
      saturation: _saturation,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ImageBackdrop.image(
            image: image,
            options: options,
            style: style,
            gradientMode: _gradient,
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(28),
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        const SizedBox(height: 12),
        BackdropColorBuilder(
          image: image,
          options: options,
          style: style,
          builder: (context, result) => _PaletteRow(result: result),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < samples.length; i++)
              ChoiceChip(
                label: Text('${i + 1}'),
                selected: i == _sample,
                onSelected: (_) => setState(() => _sample = i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(samples[_sample].label),
        const Divider(height: 32),
        _labeled(
          'Strategy',
          DropdownButton<BackdropStrategy>(
            value: _strategy,
            isExpanded: true,
            items: [
              for (final s in BackdropStrategy.values)
                DropdownMenuItem(value: s, child: Text(s.name)),
            ],
            onChanged: (v) => setState(() => _strategy = v ?? _strategy),
          ),
        ),
        _labeled(
          'Gradient',
          DropdownButton<BackdropGradientMode>(
            value: _gradient,
            isExpanded: true,
            items: [
              for (final g in BackdropGradientMode.values)
                DropdownMenuItem(value: g, child: Text(g.name)),
            ],
            onChanged: (v) => setState(() => _gradient = v ?? _gradient),
          ),
        ),
        SwitchListTile(
          title: const Text('ignoreNearWhite'),
          value: _ignoreWhite,
          onChanged: (v) => setState(() => _ignoreWhite = v),
        ),
        SwitchListTile(
          title: const Text('Sample edges only'),
          value: _edges,
          onChanged: (v) => setState(() => _edges = v),
        ),
        _slider('opacity', _opacity, 0, 1, (v) => setState(() => _opacity = v)),
        _slider(
          'brightness',
          _brightness,
          -1,
          1,
          (v) => setState(() => _brightness = v),
        ),
        _slider(
          'saturation',
          _saturation,
          -1,
          1,
          (v) => setState(() => _saturation = v),
        ),
      ],
    );
  }

  Widget _labeled(String label, Widget child) => Row(
    children: [
      SizedBox(width: 90, child: Text(label)),
      Expanded(child: child),
    ],
  );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label)),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(width: 44, child: Text(value.toStringAsFixed(2))),
      ],
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.result});

  final BackdropResult result;

  @override
  Widget build(BuildContext context) {
    final swatches = result.palette.swatches;
    if (swatches.isEmpty) {
      return const SizedBox(height: 32);
    }
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          for (final s in swatches)
            Expanded(
              flex: (s.proportion * 1000).round().clamp(1, 1000),
              child: Container(color: s.color),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Use the color somewhere else.
// ---------------------------------------------------------------------------

class UseTheColorPage extends StatefulWidget {
  const UseTheColorPage({super.key});

  @override
  State<UseTheColorPage> createState() => _UseTheColorPageState();
}

class _UseTheColorPageState extends State<UseTheColorPage> {
  final BackdropController _controller = BackdropController(
    style: const BackdropStyle(opacity: 0.9),
  );

  @override
  void initState() {
    super.initState();
    _controller.load(AssetImage(samples.first.asset));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final result = _controller.result;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: result.color.withValues(alpha: 0.25),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'The tile you tap tints this whole page through a '
                'BackdropController.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final sample in samples)
                    GestureDetector(
                      onTap: () => _controller.load(AssetImage(sample.asset)),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Image.asset(sample.asset),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'BackdropColorBuilder: color any widget you like',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              BackdropColorBuilder(
                image: const AssetImage('assets/samples/coral_bolt.png'),
                style: BackdropStyle.pastel,
                builder: (context, result) {
                  return Card(
                    color: result.color,
                    child: ListTile(
                      leading: Image.asset('assets/samples/coral_bolt.png'),
                      title: Text(
                        'Custom card',
                        style: TextStyle(color: result.onColor),
                      ),
                      subtitle: Text(
                        'Colored with result.color',
                        style: TextStyle(color: result.onColor),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'A logo inside a container that matches it',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ImageBackdrop(
                image: const AssetImage('assets/samples/teal_ring.png'),
                style: BackdropStyle.soft,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Image.asset('assets/samples/teal_ring.png', width: 48),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('Text and icons adapt automatically.'),
                    ),
                    const Icon(Icons.check_circle),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
