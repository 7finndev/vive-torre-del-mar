import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionTag extends StatelessWidget {
  final Color color;
  const VersionTag({super.key, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final version = snapshot.data!.version;
        final buildNumber = snapshot.data!.buildNumber;
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "v$version ($buildNumber)",
            style: TextStyle(fontSize: 10, color: color),
          ),
        );
      },
    );
  }
}