---
name: instalar-windows
description: Compila o IPTV Jotac e instala/atualiza no Windows local, desinstalando a versao anterior antes de instalar a nova. Use quando o usuario pedir para instalar, reinstalar, atualizar ou gerar o instalador do app no Windows.
---

# Instalar IPTV Jotac no Windows

Este skill builda o app em modo release, gera o instalador com Inno Setup e
instala no computador local, removendo automaticamente uma instalacao
anterior antes de colocar a nova (evita versoes antigas e arquivos residuais
quando o app e atualizado).

## Como executar

Rode o script abaixo a partir da raiz do repositorio usando a ferramenta
PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .claude\skills\instalar-windows\scripts\install.ps1
```

Parametros uteis:

- `-SkipBuild`: pula `flutter build windows --release` (usa o build existente
  em `build\windows\x64\runner\Release`). Use se o usuario so quer reempacotar
  / reinstalar sem recompilar.
- `-Silent`: instala sem abrir o assistente grafico (`/VERYSILENT /NORESTART`).
  Sem essa flag, o instalador abre normalmente e o usuario clica em "Avancar".

Exemplo para atualizar silenciosamente sem rebuild:

```powershell
powershell -ExecutionPolicy Bypass -File .claude\skills\instalar-windows\scripts\install.ps1 -SkipBuild -Silent
```

## O que o script faz

1. Verifica se `flutter` e o Inno Setup (`ISCC.exe`) estao disponiveis;
   se o `ISCC.exe` nao for encontrado nos caminhos padrao, avisa como instalar
   (https://jrsoftware.org/isdl.php) e para.
2. Roda `flutter build windows --release` (a menos que `-SkipBuild`).
3. Procura uma instalacao anterior do IPTV Jotac pelo AppId fixo do projeto
   no registro do Windows (`HKLM`/`HKCU`, 32 e 64 bits). Se encontrar, chama o
   `unins000.exe` dela em modo silencioso antes de prosseguir — assim a nova
   instalacao nao fica duplicada nem mistura arquivos de versoes diferentes.
4. Le a versao em `pubspec.yaml` e compila `installer\iptv_jotac.iss` com
   `ISCC.exe /DMyAppVersion=<versao>`, gerando
   `installer\Output\IPTV_Jotac_Setup.exe` ja com a versao certa (o `.iss`
   nao tem versao hardcoded; `pubspec.yaml` e a unica fonte de verdade,
   igual na skill `gerar-apk`).
5. Executa o instalador novo (silencioso ou interativo conforme `-Silent`).

## Observacoes

- Se o terminal reclamar que `pwsh` nao e reconhecido ao rodar comandos do
  Flutter, feche e abra um novo terminal (o PATH pode estar desatualizado
  apos instalar o PowerShell 7) antes de rodar este skill.
- O AppId do instalador esta fixo em `installer\iptv_jotac.iss`
  (`{8F2B6B8E-6B9B-4B0E-9B8E-7B6C2E7B6B8E}`) — e por causa dele que o script
  consegue achar e desinstalar versoes antigas corretamente. Nao altere esse
  AppId entre versoes, ou a deteccao de instalacao anterior para de funcionar.
