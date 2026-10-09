# IPTV Jotac

Cliente IPTV pessoal para Windows desktop, construido do zero em Flutter. Permite
cadastrar listas de canais/conteudo (M3U/M3U8 ou painel Xtream Codes), navegar por
TV ao vivo, filmes e series, assistir em um player embutido, baixar conteudo VOD
para assistir offline e manter um historico de "continuar assistindo".

Este e um projeto pessoal e independente: nao possui verificacao de licenca,
telemetria ou qualquer chamada "phone home" embutida. O unico tráfego de rede e
para as fontes de conteudo que voce mesmo cadastra.

## Funcionalidades

- Cadastro de multiplas listas via URL M3U/M3U8 ou credenciais Xtream Codes
  (host, usuario, senha)
- Aviso explicito quando uma fonte usa HTTP sem criptografia
- TV ao vivo, filmes e series com busca, categorias e favoritos
- Player de video embutido ([media_kit](https://pub.dev/packages/media_kit))
- Download de filmes/episodios com fila, progresso e limite de downloads
  simultaneos configuravel
- Historico de "continuar assistindo"
- Tema claro/escuro

## Stack tecnica

- [Flutter](https://flutter.dev) (stable), desktop Windows
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) para gerenciamento de estado
- [drift](https://pub.dev/packages/drift) (sobre sqlite3) para armazenamento local
- [dio](https://pub.dev/packages/dio) para requisicoes HTTP e download de arquivos
- [media_kit](https://pub.dev/packages/media_kit) / media_kit_video para reproducao
- [path_provider](https://pub.dev/packages/path_provider) para diretorios locais
- [uuid](https://pub.dev/packages/uuid) para identificadores

## Estrutura

```
lib/
  main.dart            Bootstrap (media_kit + ProviderScope)
  app.dart             MaterialApp / tema
  models/              Channel, Movie, Series, Episode, Playlist, DownloadItem, WatchHistoryEntry
  services/            m3u_parser, xtream_api_client, download_manager,
                        playlist_repository, watch_history_repository, database/ (drift)
  providers/           Providers Riverpod (playlists, conteudo, downloads, configuracoes)
  screens/             Telas (home, TV ao vivo, filmes, series, downloads, configuracoes, player)
  widgets/             Componentes reutilizaveis (cards, banners, estados vazios)
```

## Rodando o projeto

Pre-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) com
suporte a desktop Windows habilitado (`flutter config --enable-windows-desktop`).

```powershell
flutter pub get
flutter run -d windows
```

Para gerar o build de release:

```powershell
flutter build windows
```

> Nota: em alguns ambientes Windows, o build de plugins nativos exige o Modo de
> Desenvolvedor habilitado (`start ms-settings:developers`) para suporte a
> symlinks.

### Banco de dados / codegen

O schema local usa [drift](https://pub.dev/packages/drift), que gera codigo em
`lib/services/database/app_database.g.dart`. O arquivo gerado ja esta versionado;
caso o schema em `lib/services/database/tables.dart` seja alterado, regenere com:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Seguranca

- Prefira sempre fontes Xtream Codes com `https://`. Quando o host configurado
  usa `http://`, o app exibe um aviso na tela de configuracoes porque usuario e
  senha trafegam sem criptografia naquela rede.
- Nenhuma credencial e enviada a servidores alem daquele que voce cadastrou.

## Licenca

Distribuido sob a licenca MIT. Veja [LICENSE](LICENSE).
