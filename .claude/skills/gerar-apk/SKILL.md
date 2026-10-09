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

## O que o script faz

1. Roda `flutter build apk --release` (a menos que `-SkipBuild`).
2. Le a versao em `pubspec.yaml` (`version: X.Y.Z+N`).
3. Copia o(s) `.apk` gerado(s) de `build\app\outputs\flutter-apk\` para
   `%USERPROFILE%\Downloads\`, renomeando para `IPTV_Jotac_<versao>.apk`
   (ou `IPTV_Jotac_<versao>_<abi>.apk` com `-SplitPerAbi`).
4. Mostra o caminho final de cada arquivo copiado.

## Observacoes

- O APK e assinado com a chave de debug do Flutter (sem chave de release
  propria configurada) — normal para instalar via sideload em uso pessoal.
- Para instalar no aparelho depois de gerado, veja a secao "Instalacao no
  Android / Fire TV" do `README.md`.
