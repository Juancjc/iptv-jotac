---
name: gerar-apk
description: Gera o APK de release do IPTV Jotac (Android/Fire TV) e copia o arquivo para a pasta Downloads do usuario. Use quando o usuario pedir para gerar, buildar ou exportar o APK Android.
---

# Gerar APK do IPTV Jotac

Builda o app em modo release para Android e copia o `.apk` resultante para a
pasta Downloads do Windows, com o numero de versao no nome do arquivo (ex.:
`IPTV_Jotac_1.0.0.apk`), para facilitar encontrar e enviar para o
celular/Fire TV.

## Como executar

```powershell
powershell -ExecutionPolicy Bypass -File .claude\skills\gerar-apk\scripts\build_apk.ps1
```

Parametros uteis:

- `-SplitPerAbi`: gera um APK menor por arquitetura (`armeabi-v7a`,
  `arm64-v8a`, `x86_64`) em vez de um unico APK universal maior. Util se o
  tamanho do arquivo for um problema para enviar ao aparelho; para a maioria
  dos celulares/Fire TV atuais, use sem essa flag e envie o `arm64-v8a`
  (ou o universal, mais simples).
- `-SkipBuild`: pula o `flutter build apk --release` e so copia o APK que ja
  existe em `build\app\outputs\flutter-apk\` para Downloads.
- `-NoBump`: nao incrementa a versao em `pubspec.yaml`; gera o APK com a
  versao que ja estiver la. Use para re-gerar o mesmo release (ex.: so
  mudou configuracao de build, nao o app).
- `-BumpMinor` / `-BumpMajor`: em vez do bump de patch padrao, incrementa
  MINOR ou MAJOR (zerando os campos a direita) para uma mudanca maior de
  verdade (nova funcionalidade grande / breaking change).

## Versionamento (padronizado)

`pubspec.yaml` e a **unica fonte de verdade** da versao: `version: X.Y.Z+N`.
`android/app/build.gradle.kts` le `flutter.versionName`/`flutter.versionCode`
direto dai — nunca tem versao hardcoded ali. Por convencao deste projeto,
o numero de build (`+N`) sempre acompanha o PATCH (`Z`), entao uma versao
tipica e `1.0.3+3`, nunca `1.0.0+3`.

Por padrao, toda execucao desta skill incrementa PATCH e BUILD em 1 antes
de buildar (ex.: `1.0.3+3` -> `1.0.4+4`). Use `-NoBump` se so quer re-gerar
o APK da versao atual sem avancar.

## O que o script faz

1. Le a versao atual em `pubspec.yaml` e aplica o bump (patch por padrao,
   ou nenhum/minor/major conforme as flags) escrevendo de volta no arquivo.
2. Roda `flutter build apk --release` (a menos que `-SkipBuild`).
3. Copia o(s) `.apk` gerado(s) de `build\app\outputs\flutter-apk\` para
   `%USERPROFILE%\Downloads\`, renomeando para `IPTV_Jotac_<versao>.apk`
   (ou `IPTV_Jotac_<versao>_<abi>.apk` com `-SplitPerAbi`).
4. Mostra o caminho final de cada arquivo copiado.

## Observacoes

- O APK e assinado com a chave de debug do Flutter (sem chave de release
  propria configurada) — normal para instalar via sideload em uso pessoal.
- Para instalar no aparelho depois de gerado, veja a secao "Instalacao no
  Android / Fire TV" do `README.md`.
- O bump de versao em `pubspec.yaml` fica como alteracao local; se quiser
  manter o historico, faca commit dele junto com o codigo que gerou o release.
