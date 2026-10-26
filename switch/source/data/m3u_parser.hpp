#pragma once

#include <string>
#include <vector>

#include "data/catalog_types.hpp"

namespace iptv {

// Aba do IPTV Jotac em que uma entrada M3U aparece — mesmas regras de
// `PlaylistRepository._classifyM3uEntry` do app Flutter.
enum class M3uSection { Live, Movies, Series };

struct M3uCategory {
    std::string name;
    M3uSection section = M3uSection::Live;
    std::vector<CatalogItem> channels;
};

// Porte de `m3uParser.ts::parseM3u` — já devolve `CatalogItem` prontos
// (m3uUrl=url do canal), agrupados por aba e categoria. Canais ficam
// agrupados pelo `group-title`, filmes também, e episódios de série pelo
// nome da série (ex.: "Lost S01E02" fica na categoria "Lost").
std::vector<M3uCategory> parseM3u(const std::string& text);

}  // namespace iptv
