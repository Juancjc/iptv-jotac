import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'network_address.dart';

/// Data submitted by the phone's browser through the pairing web form.
class PairingSubmission {
  final String name;
  final bool isXtream;
  final String? m3uUrl;
  final String? xtreamHost;
  final String? xtreamUsername;
  final String? xtreamPassword;

  const PairingSubmission.m3u({required this.name, required String url})
      : isXtream = false,
        m3uUrl = url,
        xtreamHost = null,
        xtreamUsername = null,
        xtreamPassword = null;

  const PairingSubmission.xtream({
    required this.name,
    required String host,
    required String username,
    required String password,
  })  : isXtream = true,
        m3uUrl = null,
        xtreamHost = host,
        xtreamUsername = username,
        xtreamPassword = password;
}

/// Starts a tiny local HTTP server with a mobile-friendly form so a playlist
/// can be typed on a phone (scanning a QR code with the URL) instead of with
/// a TV remote control. Meant to be started only while the "QR Code" tab of
/// the add/edit playlist screen is visible, and stopped as soon as it is left.
class QrPairingServer {
  /// When set, the form edits this existing playlist: fields come prefilled
  /// (except the Xtream password, which is never sent over the plain-HTTP
  /// page; leaving it blank keeps [initial]'s password) and the type is fixed.
  final PairingSubmission? initial;

  QrPairingServer({this.initial});

  HttpServer? _server;
  final _submissions = StreamController<PairingSubmission>.broadcast();

  Stream<PairingSubmission> get submissions => _submissions.stream;

  /// Binds the server and returns the URL to encode in the QR code.
  /// Tries a fixed, uncommon port first (easier to read out loud / type
  /// manually); falls back to a random free port if that one is taken.
  Future<Uri> start({int preferredPort = 58712}) async {
    final handler = const shelf.Pipeline().addHandler(_handle);
    HttpServer server;
    try {
      server = await shelf_io.serve(handler, InternetAddress.anyIPv4, preferredPort, shared: true);
    } on SocketException {
      server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0, shared: true);
    }
    _server = server;
    final ip = await findLocalIPv4();
    return Uri(scheme: 'http', host: ip, port: server.port);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    await _submissions.close();
  }

  Future<shelf.Response> _handle(shelf.Request request) async {
    final initial = this.initial;
    if (request.method == 'GET') {
      return shelf.Response.ok(_formHtml(), headers: _htmlHeaders);
    }
    if (request.method == 'POST') {
      final body = await request.readAsString();
      final fields = Uri.splitQueryString(body);
      final name = (fields['name'] ?? '').trim();
      final type = initial == null ? fields['type'] : (initial.isXtream ? 'xtream' : 'm3u');

      if (name.isEmpty) {
        return shelf.Response.ok(_page('Informe um nome para a lista.', isError: true), headers: _htmlHeaders);
      }

      if (type == 'xtream') {
        final host = (fields['host'] ?? '').trim();
        final user = (fields['user'] ?? '').trim();
        var pass = (fields['pass'] ?? '').trim();
        if (pass.isEmpty && initial != null) pass = initial.xtreamPassword ?? '';
        if (host.isEmpty || user.isEmpty || pass.isEmpty) {
          return shelf.Response.ok(
            _page('Preencha host, usuario e senha.', isError: true),
            headers: _htmlHeaders,
          );
        }
        _submissions.add(PairingSubmission.xtream(name: name, host: host, username: user, password: pass));
      } else {
        final url = (fields['url'] ?? '').trim();
        final uri = Uri.tryParse(url);
        if (uri == null || !uri.hasScheme) {
          return shelf.Response.ok(_page('URL invalida.', isError: true), headers: _htmlHeaders);
        }
        _submissions.add(PairingSubmission.m3u(name: name, url: url));
      }

      return shelf.Response.ok(
        _page(
          initial == null
              ? 'Lista enviada! Pode voltar para a TV, ela ja vai aparecer la.'
              : 'Alteracoes enviadas! A TV vai salvar e atualizar a lista.',
        ),
        headers: _htmlHeaders,
      );
    }
    return shelf.Response.notFound('not found');
  }

  static const _htmlHeaders = {'content-type': 'text/html; charset=utf-8'};

  static String _page(String message, {bool isError = false}) => '''
<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>IPTV Jotac</title>
<style>$_sharedCss</style></head>
<body><div class="card">
<h1>IPTV Jotac</h1>
<p class="${isError ? 'error' : 'success'}">$message</p>
${isError ? '<a class="btn" href="javascript:history.back()">Voltar</a>' : ''}
</div></body></html>''';

  static const _sharedCss = '''
  body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
    background:#100E12;color:#F2EDF2;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;padding:16px;box-sizing:border-box}
  .card{width:100%;max-width:420px;background:#1C181D;border:1px solid #494149;border-radius:16px;padding:24px}
  h1{font-size:20px;margin:0 0 16px;color:#E04848}
  label{display:block;margin:14px 0 6px;font-size:14px;color:#C9C2C9}
  input,select{width:100%;box-sizing:border-box;padding:12px;border-radius:10px;border:1px solid #494149;
    background:#29262C;color:#F2EDF2;font-size:16px}
  input:focus,select:focus{outline:2px solid #E04848}
  .btn{display:block;width:100%;margin-top:20px;padding:14px;border:none;border-radius:10px;
    background:#E04848;color:#fff;font-size:16px;font-weight:600;text-align:center;text-decoration:none;
    box-sizing:border-box}
  .seg{display:flex;gap:8px;margin-top:4px}
  .seg label{flex:1;margin:0;text-align:center;padding:10px;border-radius:10px;border:1px solid #494149;
    background:#29262C;cursor:pointer}
  .seg input{display:none}
  .seg input:checked + span{color:#E04848;font-weight:700}
  .success{color:#4CD964}
  .error{color:#FF5A5F}
  .hidden{display:none}
  ''';

  static String _escape(String? value) => const HtmlEscape(HtmlEscapeMode.attribute).convert(value ?? '');

  String _formHtml() {
    final initial = this.initial;
    final editing = initial != null;
    final xtream = initial?.isXtream ?? false;
    final typeSelector = editing
        ? '<input type="hidden" name="type" value="${xtream ? 'xtream' : 'm3u'}">'
        : '''
    <div class="seg">
      <label><input type="radio" name="type" value="m3u" checked onchange="toggleType()"><span>URL M3U</span></label>
      <label><input type="radio" name="type" value="xtream" onchange="toggleType()"><span>Xtream Codes</span></label>
    </div>''';
    return '''
<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>IPTV Jotac - ${editing ? 'Editar' : 'Adicionar'} lista</title>
<style>$_sharedCss</style></head>
<body>
<div class="card">
  <h1>${editing ? 'Editar lista na TV' : 'Adicionar lista na TV'}</h1>
  <form method="post" onsubmit="return prepareSubmit()">
    $typeSelector

    <label for="name">Nome da lista</label>
    <input id="name" name="name" type="text" required placeholder="Minha lista" value="${_escape(initial?.name)}">

    <div id="m3u-fields"${xtream ? ' class="hidden"' : ''}>
      <label for="url">URL do M3U/M3U8</label>
      <input id="url" name="url" type="url" placeholder="http://exemplo.com/lista.m3u8" value="${_escape(initial?.m3uUrl)}">
    </div>

    <div id="xtream-fields"${xtream ? '' : ' class="hidden"'}>
      <label for="host">Host (http(s)://host:porta)</label>
      <input id="host" name="host" type="text" placeholder="http://exemplo.com:8080" value="${_escape(initial?.xtreamHost)}">
      <label for="user">Usuario</label>
      <input id="user" name="user" type="text" value="${_escape(initial?.xtreamUsername)}">
      <label for="pass">Senha</label>
      <input id="pass" name="pass" type="password"${editing ? ' placeholder="Deixe em branco para manter a senha atual"' : ''}>
    </div>

    <button class="btn" type="submit">${editing ? 'Salvar na TV' : 'Enviar para a TV'}</button>
  </form>
</div>
<script>
function toggleType() {
  var xtream = document.querySelector('input[name=type]:checked, input[name=type][type=hidden]').value === 'xtream';
  document.getElementById('m3u-fields').classList.toggle('hidden', xtream);
  document.getElementById('xtream-fields').classList.toggle('hidden', !xtream);
  document.getElementById('url').required = !xtream;
  document.getElementById('host').required = xtream;
  document.getElementById('user').required = xtream;
  document.getElementById('pass').required = xtream && !$editing;
}
toggleType();
function prepareSubmit() { return true; }
</script>
</body></html>''';
  }
}
