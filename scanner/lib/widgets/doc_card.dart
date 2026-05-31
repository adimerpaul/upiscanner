import 'package:flutter/material.dart';
import '../models/document.dart';
import '../core/app_colors.dart';
import 'page_thumbnail.dart';
import '../models/filter_option.dart';

class DocCard extends StatelessWidget {
  final Document doc;
  final VoidCallback onTap;

  const DocCard({super.key, required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFeef2f3)),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1 / 1.18,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFeef2f3)),
                      ),
                      child: PageThumbnail(kind: doc.kind, filter: FilterType.original),
                    ),
                  ),
                ),
                Positioned(
                  top: 7, right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xC60f172a),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${doc.pages} pág',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              doc.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.25),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 11, color: AppColors.slateL),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    doc.date,
                    style: const TextStyle(fontSize: 11, color: AppColors.slateL, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
