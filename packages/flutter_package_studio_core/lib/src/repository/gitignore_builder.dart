/// Utility for generating structured .gitignore contents.
class GitignoreBuilder {
  /// Builds a standard .gitignore file content for Dart/Flutter projects.
  static String buildGitignore({bool isFlutter = true}) {
    final buffer = StringBuffer();
    buffer.writeln('# Miscellaneous');
    buffer.writeln('*.class');
    buffer.writeln('*.log');
    buffer.writeln('*.pyc');
    buffer.writeln('*.swp');
    buffer.writeln('.DS_Store');
    buffer.writeln('.atom/');
    buffer.writeln('.buildlog/');
    buffer.writeln('.history');
    buffer.writeln('.svn/');
    buffer.writeln('migrate_working_dir/');
    buffer.writeln();
    buffer.writeln('# User-specific stuff');
    buffer.writeln('*.rsuser');
    buffer.writeln('*.suo');
    buffer.writeln('*.user');
    buffer.writeln('*.userosscache');
    buffer.writeln('*.sln.docstates');
    buffer.writeln();
    buffer.writeln('# Build / Dart / Flutter packages');
    buffer.writeln('.dart_tool/');
    buffer.writeln('.packages');
    buffer.writeln('build/');
    buffer.writeln('coverage/');
    buffer.writeln('.pub-cache/');
    buffer.writeln('.pub/');
    buffer.writeln('pubspec.lock');
    buffer.writeln();
    buffer.writeln('# IDE files');
    buffer.writeln('.idea/');
    buffer.writeln('*.iml');
    buffer.writeln('*.ipr');
    buffer.writeln('*.iws');
    buffer.writeln('.vscode/');
    buffer.writeln();
    if (isFlutter) {
      buffer.writeln('# Android / iOS / Web / Desktop artifacts');
      buffer.writeln('android/app/debug');
      buffer.writeln('android/app/profile');
      buffer.writeln('android/app/release');
      buffer.writeln('ios/Runner/GeneratedPluginRegistrant.h');
      buffer.writeln('ios/Runner/GeneratedPluginRegistrant.m');
      buffer.writeln('ephemeral/');
      buffer.writeln('linux/flutter/ephemeral/');
      buffer.writeln('windows/flutter/ephemeral/');
      buffer.writeln('macOS/flutter/ephemeral/');
    }
    return buffer.toString();
  }
}
