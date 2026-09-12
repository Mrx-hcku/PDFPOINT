import 'package:flutter/material.dart';

class HomeFeedTab extends StatelessWidget {
  const HomeFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'Home Feed',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                ),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF1E293B),
                  child: Icon(Icons.person, color: Color(0xFF94A3B8), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                hintText: 'Search teachers, subjects, PDFs...',
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Trending Batches',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF1F5F9),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTrendingCard(
              context,
              title: 'Physics Wallah - NEET 2026',
              description: 'Physics Wallah - NEET 2026, Physics - Physics Wallah - NEET 2028, Mer...',
              time: '1 hr',
              gradientColors: [const Color(0xFF4338CA), const Color(0xFFEC4899)],
            ),
            const SizedBox(height: 12),
            _buildTrendingCard(
              context,
              title: 'Maths Wizard - Calculus Pro',
              description: 'Maths Wizard - Calculus Pro, Maths Wizard - Calculus, Wizard - Calculus Pro -> 2...',
              time: '1 hr',
              isDarkCard: true,
            ),
            const SizedBox(height: 12),
            _buildTrendingCard(
              context,
              title: 'Physics Wallah -',
              description: 'Advanced Mechanics & Formula Sheets for Board Aspirants...',
              time: '2 hrs',
              gradientColors: [const Color(0xFF312E81), const Color(0xFFBE185D)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingCard(
    BuildContext context, {
    required String title,
    required String description,
    required String time,
    List<Color>? gradientColors,
    bool isDarkCard = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradientColors != null
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isDarkCard ? const Color(0xFF1E293B) : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFFBBF24), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
