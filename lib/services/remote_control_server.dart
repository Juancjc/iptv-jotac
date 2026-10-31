import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'network_address.dart';

/// Kind of content the phone can browse and start on the TV.
enum RemoteContentType { live, movie, series }

/// Buttons of the phone's remote control page.
enum RemoteKey { up, down, left, right, ok, back, home, playPause }

class RemoteCategory {
  final String name;
  final int count;

  const RemoteCategory(this.name, this.count);

  Map<String, Object?> toJson() => {'name': name, 'count': count};
}

class RemoteItem {
  final String id;
  final String name;
  final String? imageUrl;

  const RemoteItem(this.id, this.name, [this.imageUrl]);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'image': imageUrl};
}

class RemoteEpisode {
  final String id;
  final int season;
  final int episode;
  final String title;

  const RemoteEpisode(this.id, this.season, this.episode, this.title);

  Map<String, Object?> toJson() => {'id': id, 'season': season, 'episode': episode, 'title': title};
}

/// What the server needs from the app: content to list and actions to run on
/// the TV. Keeps the HTTP layer free of Flutter/database details.
abstract class RemoteControlHandler {
  Future<List<RemoteItem>> playlists();

  Future<List<RemoteCategory>> categories(RemoteContentType type, String? playlistId);

  /// Items of [type], optionally limited to a playlist, a category and a
  /// search [query]. Returns at most [limit] items starting at [offset], plus
  /// the total number of matches.
  Future<(List<RemoteItem>, int)> items(
    RemoteContentType type, {
    String? playlistId,
    String? category,
    String? query,
    int offset = 0,
    int limit = 100,
  });

  Future<List<RemoteEpisode>> episodes(String seriesId);

  /// Starts playback on the TV. [type] is live/movie, or `null` for an episode.
  Future<void> play(RemoteContentType? type, String id);

  Future<void> pressKey(RemoteKey key);
}

/// Local HTTP server that lets a phone on the same network control the app
/// from its browser: a remote control page and a catalog to pick what plays.
///
/// Every request must carry the random access code from the QR code (`k`),
/// so other devices on the network can't take over the TV. Stream URLs (which
/// may contain the provider's credentials) are never sent to the phone.
class RemoteControlServer {
  static const defaultPort = 58713;

  final RemoteControlHandler handler;
  final String accessCode;

  HttpServer? _server;

  RemoteControlServer(this.handler, {String? accessCode}) : accessCode = accessCode ?? _randomCode();

  static String _randomCode() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  bool get isRunning => _server != null;

  /// Binds the server and returns the URL (with the access code) for the QR.
  Future<Uri> start({int preferredPort = defaultPort}) async {
    final pipeline = const shelf.Pipeline().addHandler(_handle);
    HttpServer server;
    try {
      server = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, preferredPort, shared: true);
    } on SocketException {
      server = await shelf_io.serve(pipeline, InternetAddress.anyIPv4, 0, shared: true);
    }
    _server = server;
    final ip = await findLocalIPv4();
    return Uri(scheme: 'http', host: ip, port: server.port, path: '/', queryParameters: {'k': accessCode});
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static const _jsonHeaders = {'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store'};

  shelf.Response _json(Object? data, [int status = 200]) =>
      shelf.Response(status, body: jsonEncode(data), headers: _jsonHeaders);

  Future<shelf.Response> _handle(shelf.Request request) async {
    if (request.url.queryParameters['k'] != accessCode) {
      return shelf.Response.forbidden(
        _deniedHtml,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    }
    final path = request.url.path;
    final params = request.url.queryParameters;
    try {
      if (request.method == 'GET' && path.isEmpty) {
        return shelf.Response.ok(remotePageHtml, headers: {'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store'});
      }
      if (request.method == 'GET' && path == 'api/playlists') {
        return _json([for (final p in await handler.playlists()) p.toJson()]);
      }
      if (request.method == 'GET' && path == 'api/categories') {
        final type = _type(params['type']);
        if (type == null) return _json({'error': 'tipo invalido'}, 400);
        final categories = await handler.categories(type, _blankToNull(params['playlist']));
        return _json([for (final c in categories) c.toJson()]);
      }
      if (request.method == 'GET' && path == 'api/items') {
        final type = _type(params['type']);
        if (type == null) return _json({'error': 'tipo invalido'}, 400);
        final (items, total) = await handler.items(
          type,
          playlistId: _blankToNull(params['playlist']),
          category: params['category'],
          query: _blankToNull(params['q']),
          offset: int.tryParse(params['offset'] ?? '') ?? 0,
          limit: (int.tryParse(params['limit'] ?? '') ?? 100).clamp(1, 500),
        );
        return _json({
          'total': total,
          'items': [for (final i in items) i.toJson()],
        });
      }
      if (request.method == 'GET' && path == 'api/episodes') {
        final id = params['series'];
        if (id == null) return _json({'error': 'serie invalida'}, 400);
        return _json([for (final e in await handler.episodes(id)) e.toJson()]);
      }
      if (request.method == 'POST' && path == 'api/play') {
        final body = jsonDecode(await request.readAsString());
        if (body is! Map || body['id'] is! String) return _json({'error': 'pedido invalido'}, 400);
        final kind = body['type'];
        await handler.play(kind == 'episode' ? null : _type(kind?.toString()), body['id'] as String);
        return _json({'ok': true});
      }
      if (request.method == 'POST' && path == 'api/key') {
        final body = jsonDecode(await request.readAsString());
        final key = RemoteKey.values.where((k) => body is Map && k.name == body['key']).firstOrNull;
        if (key == null) return _json({'error': 'tecla invalida'}, 400);
        await handler.pressKey(key);
        return _json({'ok': true});
      }
      return _json({'error': 'nao encontrado'}, 404);
    } catch (error) {
      return _json({'error': error.toString()}, 500);
    }
  }

  static RemoteContentType? _type(String? value) =>
      RemoteContentType.values.where((t) => t.name == value).firstOrNull;

  static String? _blankToNull(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}

const _deniedHtml = '''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>IPTV Jotac</title></head>
<body style="background:#100E12;color:#F2EDF2;font-family:system-ui,sans-serif;padding:24px">
<h2 style="color:#E04848">Acesso negado</h2>
<p>Leia novamente o QR code mostrado na TV. O codigo muda cada vez que o controle via rede e ativado.</p>
</body></html>''';

/// The phone page: a remote control and a catalog, in plain HTML/JS so it
/// works in any mobile browser without installing anything.
const remotePageHtml = r'''<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<meta name="theme-color" content="#121014">
<title>IPTV Jotac - Controle</title>
<style>
:root{--bg:#100E12;--card:#1C181D;--card2:#29262C;--line:#494149;--text:#F2EDF2;--muted:#B5ACB5;--accent:#E04848}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
body{margin:0;background:var(--bg);color:var(--text);font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
header{position:sticky;top:0;z-index:5;background:#121014;border-bottom:1px solid var(--line);padding:12px 16px 0}
h1{margin:0 0 10px;font-size:18px;color:var(--accent)}
.modes,.tabs{display:flex;gap:6px}
.modes button,.tabs button{flex:1;padding:10px 6px;border:none;border-bottom:3px solid transparent;background:none;color:var(--muted);font-size:15px;font-weight:600}
.modes button.on,.tabs button.on{color:var(--text);border-bottom-color:var(--accent)}
main{padding:16px;max-width:640px;margin:0 auto}
.hidden{display:none!important}
/* remote */
.pad{position:relative;width:min(78vw,300px);aspect-ratio:1;margin:12px auto 24px;border-radius:50%;background:var(--card2);border:1px solid var(--line)}
.pad button{position:absolute;border:none;background:none;color:var(--text);font-size:30px;width:33%;height:33%}
.pad button:active{color:var(--accent)}
.pad .up{top:0;left:33.5%}.pad .down{bottom:0;left:33.5%}.pad .left{left:0;top:33.5%}.pad .right{right:0;top:33.5%}
.pad .ok{top:30%;left:30%;width:40%;height:40%;border-radius:50%;background:var(--accent);font-size:20px;font-weight:700;color:#fff}
.pad .ok:active{filter:brightness(.85);color:#fff}
.row{display:flex;gap:12px;justify-content:center;max-width:360px;margin:0 auto}
.round{flex:1;padding:16px 8px;border-radius:14px;border:1px solid var(--line);background:var(--card);color:var(--text);font-size:15px;font-weight:600}
.round:active{background:var(--card2)}
/* catalog */
select,input{width:100%;padding:12px;border-radius:12px;border:1px solid var(--line);background:var(--card2);color:var(--text);font-size:16px}
.bar{display:flex;flex-direction:column;gap:10px;margin-bottom:12px}
.crumb{display:flex;align-items:center;gap:8px;margin:4px 0 10px;color:var(--muted);font-size:14px}
.crumb button{border:none;background:var(--card2);color:var(--text);padding:8px 12px;border-radius:10px;font-size:14px}
.list{display:flex;flex-direction:column;gap:6px}
.item{display:flex;align-items:center;gap:12px;padding:10px;border-radius:12px;background:var(--card);border:1px solid var(--line);color:var(--text);text-align:left;font-size:15px;width:100%}
.item:active{background:var(--card2)}
.item img,.item .ph{width:48px;height:36px;object-fit:contain;border-radius:6px;background:var(--card2);flex:none}
.item .name{flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.item .count{color:var(--muted);font-size:13px}
.more{margin-top:10px}
.empty{color:var(--muted);text-align:center;padding:24px}
#toast{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);background:#332E34;color:var(--text);padding:12px 18px;border-radius:12px;border:1px solid var(--line);opacity:0;transition:opacity .2s;pointer-events:none;max-width:90vw}
#toast.show{opacity:1}
.minipad{display:flex;gap:8px;margin-top:16px}
.minipad button{flex:1;padding:12px 4px;border-radius:12px;border:1px solid var(--line);background:var(--card);color:var(--text);font-size:14px}
</style></head>
<body>
<header>
  <h1>IPTV Jotac</h1>
  <div class="modes">
    <button data-mode="remote">Controle</button>
    <button data-mode="catalog">Escolher o que assistir</button>
  </div>
</header>
<main>
  <section id="remote">
    <div class="pad">
      <button class="up" data-key="up" aria-label="Cima">&#9650;</button>
      <button class="left" data-key="left" aria-label="Esquerda">&#9664;</button>
      <button class="ok" data-key="ok">OK</button>
      <button class="right" data-key="right" aria-label="Direita">&#9654;</button>
      <button class="down" data-key="down" aria-label="Baixo">&#9660;</button>
    </div>
    <div class="row">
      <button class="round" data-key="back">&#8617; Voltar</button>
      <button class="round" data-key="home">&#8962; Inicio</button>
      <button class="round" data-key="playPause">&#9199; Play/Pausa</button>
    </div>
  </section>

  <section id="catalog" class="hidden">
    <div class="bar">
      <select id="playlist"><option value="">Todas as listas</option></select>
      <div class="tabs">
        <button data-type="live" class="on">TV ao vivo</button>
        <button data-type="movie">Filmes</button>
        <button data-type="series">Series</button>
      </div>
      <input id="search" type="search" placeholder="Buscar..." autocomplete="off">
    </div>
    <div id="crumb" class="crumb hidden"><button id="backBtn">&#8592; Voltar</button><span id="crumbText"></span></div>
    <div id="list" class="list"></div>
    <button id="more" class="round more hidden" style="width:100%">Carregar mais</button>
    <div class="minipad">
      <button data-key="back">&#8617; Voltar</button>
      <button data-key="playPause">&#9199; Play/Pausa</button>
      <button data-key="home">&#8962; Inicio</button>
    </div>
  </section>
</main>
<div id="toast"></div>
<script>
const K = new URLSearchParams(location.search).get('k') || '';
const $ = s => document.querySelector(s);
const PAGE = 100;
let state = {type:'live', category:null, series:null, offset:0, total:0};

function api(path, params){
  const u = new URL(path, location.origin);
  u.searchParams.set('k', K);
  for (const [a,b] of Object.entries(params||{})) if (b !== null && b !== undefined) u.searchParams.set(a, b);
  return u;
}
async function get(path, params){
  const r = await fetch(api(path, params));
  if (!r.ok) throw new Error((await r.json().catch(()=>({}))).error || ('Erro ' + r.status));
  return r.json();
}
async function post(path, body){
  const r = await fetch(api(path), {method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify(body)});
  if (!r.ok) throw new Error((await r.json().catch(()=>({}))).error || ('Erro ' + r.status));
  return r.json();
}
let toastTimer;
function toast(msg){
  const t = $('#toast'); t.textContent = msg; t.classList.add('show');
  clearTimeout(toastTimer); toastTimer = setTimeout(()=>t.classList.remove('show'), 1800);
}
function esc(s){ return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

// Modes
function setMode(mode){
  document.querySelectorAll('.modes button').forEach(b => b.classList.toggle('on', b.dataset.mode === mode));
  $('#remote').classList.toggle('hidden', mode !== 'remote');
  $('#catalog').classList.toggle('hidden', mode !== 'catalog');
  try { localStorage.setItem('mode', mode); } catch(e) {}
  if (mode === 'catalog' && !$('#list').childElementCount) load();
}
document.querySelectorAll('.modes button').forEach(b => b.onclick = () => setMode(b.dataset.mode));

// Remote keys
document.querySelectorAll('[data-key]').forEach(b => b.addEventListener('click', async () => {
  if (navigator.vibrate) navigator.vibrate(15);
  try { await post('/api/key', {key: b.dataset.key}); } catch(e) { toast(e.message); }
}));

// Catalog
async function loadPlaylists(){
  try {
    const lists = await get('/api/playlists');
    const sel = $('#playlist');
    for (const p of lists) { const o = document.createElement('option'); o.value = p.id; o.textContent = p.name; sel.appendChild(o); }
  } catch(e) { toast(e.message); }
}
$('#playlist').onchange = () => { state.category = null; state.series = null; load(); };
document.querySelectorAll('.tabs button').forEach(b => b.onclick = () => {
  document.querySelectorAll('.tabs button').forEach(x => x.classList.toggle('on', x === b));
  state.type = b.dataset.type; state.category = null; state.series = null; load();
});
let searchTimer;
$('#search').oninput = () => { clearTimeout(searchTimer); searchTimer = setTimeout(() => { state.series = null; load(); }, 300); };
$('#backBtn').onclick = () => {
  if (state.series) state.series = null; else state.category = null;
  load();
};
$('#more').onclick = () => loadItems(true);

function crumb(text){
  $('#crumb').classList.toggle('hidden', !text);
  $('#crumbText').textContent = text || '';
}

function load(){
  state.offset = 0;
  $('#more').classList.add('hidden');
  const q = $('#search').value.trim();
  if (state.series) return loadEpisodes();
  if (state.category === null && !q) return loadCategories();
  return loadItems(false);
}

async function loadCategories(){
  crumb('');
  const list = $('#list'); list.innerHTML = '<div class="empty">Carregando...</div>';
  try {
    const cats = await get('/api/categories', {type: state.type, playlist: $('#playlist').value});
    const total = cats.reduce((a, c) => a + c.count, 0);
    list.innerHTML = '';
    if (!cats.length) { list.innerHTML = '<div class="empty">Nada por aqui. Atualize a lista na TV.</div>'; return; }
    addRow(list, 'Todos', total, () => { state.category = ''; load(); });
    for (const c of cats) addRow(list, c.name, c.count, () => { state.category = c.name; load(); });
  } catch(e) { list.innerHTML = '<div class="empty">' + esc(e.message) + '</div>'; }
}

function addRow(list, name, count, onclick){
  const b = document.createElement('button'); b.className = 'item';
  b.innerHTML = '<span class="name">' + esc(name) + '</span><span class="count">' + count + '</span>';
  b.onclick = onclick; list.appendChild(b);
}

async function loadItems(append){
  const q = $('#search').value.trim();
  const cat = state.category;
  crumb(q ? 'Busca: ' + q : (cat ? cat : 'Todos'));
  if (q && cat === null) $('#crumb').classList.add('hidden');
  const list = $('#list');
  if (!append) list.innerHTML = '<div class="empty">Carregando...</div>';
  try {
    const res = await get('/api/items', {type: state.type, playlist: $('#playlist').value, category: cat || null, q: q || null, offset: state.offset, limit: PAGE});
    if (!append) list.innerHTML = '';
    state.offset += res.items.length; state.total = res.total;
    if (!res.items.length && !append) list.innerHTML = '<div class="empty">Nenhum resultado</div>';
    for (const it of res.items) {
      const b = document.createElement('button'); b.className = 'item';
      b.innerHTML = (it.image ? '<img loading="lazy" src="' + esc(it.image) + '" onerror="this.replaceWith(Object.assign(document.createElement(\'span\'),{className:\'ph\'}))">' : '<span class="ph"></span>') +
        '<span class="name">' + esc(it.name) + '</span>' + (state.type === 'series' ? '<span class="count">&#8250;</span>' : '');
      b.onclick = () => state.type === 'series' ? openSeries(it) : play(state.type, it.id, it.name);
      list.appendChild(b);
    }
    $('#more').classList.toggle('hidden', state.offset >= state.total);
  } catch(e) { list.innerHTML = '<div class="empty">' + esc(e.message) + '</div>'; }
}

function openSeries(it){ state.series = it; load(); }

async function loadEpisodes(){
  crumb(state.series.name);
  const list = $('#list'); list.innerHTML = '<div class="empty">Carregando episodios...</div>';
  try {
    const eps = await get('/api/episodes', {series: state.series.id});
    list.innerHTML = '';
    if (!eps.length) { list.innerHTML = '<div class="empty">Nenhum episodio encontrado</div>'; return; }
    eps.sort((a, b) => a.season - b.season || a.episode - b.episode);
    for (const e of eps) {
      const b = document.createElement('button'); b.className = 'item';
      b.innerHTML = '<span class="count">T' + e.season + ' E' + e.episode + '</span><span class="name">' + esc(e.title) + '</span>';
      b.onclick = () => play('episode', e.id, e.title);
      list.appendChild(b);
    }
  } catch(e) { list.innerHTML = '<div class="empty">' + esc(e.message) + '</div>'; }
}

async function play(type, id, name){
  try { await post('/api/play', {type, id}); toast('Abrindo na TV: ' + name); }
  catch(e) { toast(e.message); }
}

let saved = 'remote';
try { saved = localStorage.getItem('mode') || 'remote'; } catch(e) {}
loadPlaylists();
setMode(saved);
</script>
</body></html>''';
