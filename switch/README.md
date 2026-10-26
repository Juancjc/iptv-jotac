# IPTV Jotac para Nintendo Switch

Versão homebrew (`.nro`) do IPTV Jotac para Nintendo Switch com Atmosphère e
Homebrew Launcher. Escrita em C++ com [borealis](https://github.com/dragonflylee/borealis)
(interface com navegação por controle) e [mpv](https://mpv.io/)/FFmpeg para
reprodução.

Baseada no [switchiptv](https://github.com/gomprime/switchiptv) de gomprime,
licenciado sob GPLv3 — por isso o conteúdo desta pasta `switch/` também é
GPLv3 (ver `LICENSE`). O resto do repositório (app Flutter) não é afetado.

## Instalação

1. Baixe o `IptvJotac.nro` do último build do workflow **Switch (.nro)** na
   aba Actions do GitHub (artefato `IptvJotac-switch-<número>`).
2. Copie para a pasta `/switch/` do cartão SD.
3. Abra pelo Homebrew Launcher.

Os dados (lista, favoritos, histórico) ficam em `sdmc:/switch/iptv-jotac/`.

## Compilação

O `.nro` é gerado pelo GitHub Actions (`.github/workflows/switch.yml`), com a
imagem Docker `devkitpro/devkita64` e as portlibs de curl/FFmpeg/libmpv do
Switchfin. Para compilar localmente com devkitPro:

```bash
git submodule update --init --recursive
git -C switch/library/borealis apply ../../patches/borealis-iptv.patch
cmake -S switch -B switch/build -DPLATFORM_SWITCH=ON
make -C switch/build IptvJotac.nro
```
