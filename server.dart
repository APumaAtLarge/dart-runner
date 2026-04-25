
import 'dart:io';
import 'dart:convert';

void main() async {
  // 监听所有 IP 的 2000 端口
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 2000);
  print('自建 Dart 执行 API 已启动，监听端口: 2000');

  await for (HttpRequest request in server) {
    // 跨域支持 (CORS)，方便你的 Obsidian 插件直接调用
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.close();
      continue;
    }

    if (request.method == 'POST') {
      try {
        // 读取请求体中的 JSON 数据
        String content = await utf8.decoder.bind(request).join();
        var data = jsonDecode(content);
        String code = data['code'] ?? '';

        // 1. 在系统的临时目录下生成一个独一无二的 .dart 文件
        String tempPath = '${Directory.systemTemp.path}/run_${DateTime.now().microsecondsSinceEpoch}.dart';
        File tempFile = File(tempPath);
        await tempFile.writeAsString(code);

        // 2. 拉起子进程执行这个 dart 文件
        var result = await Process.run('dart', ['run', tempPath]);

        // 3. 执行完毕后，删除临时文件以释放空间
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        // 4. 组装返回结果，完美模仿你原本需要的 JSON 格式
        var responseJson = {
          'success': result.exitCode == 0,
          'stdout': result.stdout.toString(),
          'stderr': result.stderr.toString(),
        };

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(responseJson))
          ..close();

      } catch (e) {
        // 捕获异常
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write(jsonEncode({
            'success': false,
            'stdout': '',
            'stderr': '服务器执行异常: $e'
          }))
          ..close();
      }
    } else {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('仅支持 POST 请求')
        ..close();
    }
  }
}
