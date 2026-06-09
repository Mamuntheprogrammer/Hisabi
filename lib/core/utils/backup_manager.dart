import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class BackupManager {
  static Future<Directory> _getBackupDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  static Future<String> createBackup() async {
    final dbPath = await getDatabasesPath();
    final dbFile = File('$dbPath/hisabi.db');

    if (!await dbFile.exists()) {
      throw Exception('Database file not found');
    }

    final backupDir = await _getBackupDir();
    final dateStr = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final backupFile = File('${backupDir.path}/hisabi_backup_$dateStr.db');

    await dbFile.copy(backupFile.path);

    return backupFile.path;
  }

  static Future<void> restoreBackup(String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw Exception('Backup file not found');
    }

    final dbPath = await getDatabasesPath();
    final dbFile = File('$dbPath/hisabi.db');

    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    await backupFile.copy(dbFile.path);
  }

  static Future<List<FileSystemEntity>> getBackupFiles() async {
    final backupDir = await _getBackupDir();
    final files = await backupDir.list().toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files.where((f) => f.path.endsWith('.db')).toList();
  }

  static Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<String> getBackupDirPath() async {
    final dir = await _getBackupDir();
    return dir.path;
  }
}
