import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/'),
          tooltip: 'Back to Lobby',
        ),
        title: const Text('Game Rules', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: FutureBuilder<String>(
              future: rootBundle.loadString('assets/docs/game_rules.md'),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Markdown(
                    data: snapshot.data!,
                    selectable: true,
                    sizedImageBuilder: (config) {
                      final uri = config.uri;
                      if (uri.path.endsWith('.svg')) {
                        return SvgPicture.asset(
                          'assets/ships/${uri.path.split('/').last}',
                          width: config.width ?? 32,
                          height: config.height ?? 32,
                        );
                      }
                      return Image.asset(uri.toString(), width: config.width, height: config.height);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading rules: ${snapshot.error}'));
                }
                return const Center(child: GridLoadingIndicator(size: 40));
              },
            ),
          ),
        ),
      ),
    );
  }
}
