# IPTV Jotac

Cliente IPTV pessoal para Windows, Android e Android TV / Fire TV, construido do
zero em Flutter. Permite cadastrar listas de canais/conteudo (M3U/M3U8 ou painel
Xtream Codes), navegar por TV ao vivo, filmes e series, assistir em um player
embutido, baixar conteudo VOD para assistir offline e manter um historico de
"continuar assistindo".

Este e um projeto pessoal e independente: nao possui verificacao de licenca,
telemetria ou qualquer chamada "phone home" embutida. O unico tráfego de rede e
para as fontes de conteudo que voce mesmo cadastra.

## Funcionalidades

- Cadastro de multiplas listas via URL M3U/M3U8 ou credenciais Xtream Codes
  (host, usuario, senha)
- Cadastro de lista por QR code: na Android TV/Fire TV (onde digitar com o
  controle remoto e ruim), a opcao "QR Code" ao adicionar uma lista sobe um
  servidor local e mostra um QR apontando para um formulario simples; basta
  escanear com o celular, preencher por la e a lista aparece sozinha na TV
- Aviso explicito quando uma fonte usa HTTP sem criptografia
- TV ao vivo, filmes e series com busca, categorias e favoritos
- Navegacao 100% por D-pad/controle remoto na Android TV e Fire TV (todo o
  app usa widgets focaveis nativamente pelo Flutter)
- Player de video embutido ([media_kit](https://pub.dev/packages/media_kit)),
  com tela de capa antes de assistir filmes/episodios para escolher audio e
  legenda (quando o stream tiver mais de uma opcao)
- Personalizacao de legenda (tamanho, cor do texto e do fundo) em Configuracoes
- Download de filmes/episodios com fila, progresso e limite de downloads
  simultaneos configuravel
- Historico de "continuar assistindo"
- Tema claro/escuro

## Instalacao no Windows

### Opcao 1: Instalador (recomendado)

1. Baixe o instalador em `installer/Output/IPTV_Jotac_Setup.exe` (ou gere um
   novo, veja abaixo).
2. Execute o `.exe` e siga o assistente. Ele cria os atalhos no menu Iniciar e,
   opcionalmente, na area de trabalho.
3. Abra "IPTV Jotac" pelo menu Iniciar ou atalho criado.

> O instalador nao e assinado digitalmente. O Windows SmartScreen pode exibir
> um aviso ("Windows protegeu seu computador") — clique em "Mais informacoes"
> e depois em "Executar assim mesmo" para prosseguir.

Para gerar o instalador a partir do codigo-fonte:

```powershell
flutter build windows --release
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\iptv_jotac.iss
```

Isso requer o [Inno Setup 6](https://jrsoftware.org/isdl.php) instalado. O
`.exe` gerado fica em `installer\Output\IPTV_Jotac_Setup.exe`.

### Opcao 2: Build manual (sem instalador)

1. Rode `flutter build windows --release` (veja pre-requisitos na secao
   seguinte).
2. Copie a pasta `build\windows\x64\runner\Release` para onde preferir.
3. Execute `iptv_jotac.exe` diretamente dessa pasta.

### Opcao 3: Skill do Claude Code

Quem usa [Claude Code](https://claude.com/claude-code) neste repositorio pode
usar o skill `instalar-windows` (`.claude/skills/instalar-windows/`) para
automatizar tudo isso: ele builda, detecta uma instalacao anterior do app pelo
AppId e a remove antes de instalar a nova (evita duplicidade ao atualizar), e
entao compila e roda o instalador.

Basta pedir "instala/atualiza o app no Windows" ou rodar diretamente:

```powershell
powershell -ExecutionPolicy Bypass -File .claude\skills\instalar-windows\scripts\install.ps1
```

Aceita `-SkipBuild` (reempacota sem recompilar) e `-Silent` (instala sem abrir
o assistente grafico). Veja `.claude/skills/instalar-windows/SKILL.md` para
detalhes.

## Instalacao no Android / Fire TV

O app nao esta em nenhuma loja — e instalado via "sideload" (arquivo `.apk`
direto). Funciona em celulares/tablets Android e em Android TV / Fire TV
(aparece no launcher de TV e e totalmente navegavel pelo controle remoto).

1. Gere o APK (ou use um ja gerado em `build\app\outputs\flutter-apk\app-release.apk`):
   ```powershell
   flutter build apk --release
   ```
2. Instale no aparelho:
   - **Via USB/ADB** (celular ou Fire TV com depuracao USB/rede ativada):
     ```powershell
     adb install -r build\app\outputs\flutter-apk\app-release.apk
     ```
     Em Fire TV, ative antes em Configuracoes > Minha Fire TV > Opcoes do
     desenvolvedor > Depuracao via ADB, e conecte com `adb connect <ip-da-tv>:5555`.
   - **Sem USB**: envie o `.apk` para o aparelho (Google Drive, um servidor
     local, um app como "Send files to TV"/"Downloader") e instale pelo
     gerenciador de arquivos. Em Fire TV, instale antes um app de
     gerenciador de arquivos com suporte a instalacao de APK (ex.: "Downloader"
     ou "X-plore"), e habilite "Apps de fontes desconhecidas" em
     Configuracoes > Minha Fire TV > Opcoes do desenvolvedor.
3. Abra "IPTV Jotac" no launcher normal (celular) ou na fileira de apps da
   Fire TV / Android TV.

> O APK e assinado com a chave de debug do Flutter (nao ha chave de release
> propria configurada). Isso e normal para uso pessoal via sideload, mas
> significa que cada rebuild deve ser reinstalado por cima da versao anterior
> normalmente (sem conflito de assinatura, pois a chave nao muda).

Depois de instalado, para cadastrar uma lista na TV sem digitar com o
controle: va em "Adicionar lista" > aba "QR Code", escaneie com o celular e
preencha o formulario por la.

## Stack tecnica

- [Flutter](https://flutter.dev) (stable), Windows desktop + Android (celular e Android TV/Fire TV)
- [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) para gerenciamento de estado
- [drift](https://pub.dev/packages/drift) (sobre sqlite3) para armazenamento local
- [dio](https://pub.dev/packages/dio) para requisicoes HTTP e download de arquivos
- [media_kit](https://pub.dev/packages/media_kit) / media_kit_video para reproducao,
  incluindo selecao de faixa de audio/legenda
- [path_provider](https://pub.dev/packages/path_provider) para diretorios locais
- [uuid](https://pub.dev/packages/uuid) para identificadores
- [shelf](https://pub.dev/packages/shelf) para o servidor local do pareamento por QR code
- [qr_flutter](https://pub.dev/packages/qr_flutter) para renderizar o QR code

## Estrutura

```
lib/
  main.dart            Bootstrap (media_kit + ProviderScope)
  app.dart             MaterialApp / tema
  models/              Channel, Movie, Series, Episode, Playlist, DownloadItem, WatchHistoryEntry
  services/            m3u_parser, xtream_api_client, download_manager,
                        playlist_repository, watch_history_repository, database/ (drift),
                        qr_pairing_server (servidor local do cadastro por QR code)
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
