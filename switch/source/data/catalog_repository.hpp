#pragma once

#include <string>
#include <vector>

#include "data/catalog_types.hpp"
#include "data/m3u_parser.hpp"
#include "data/storage.hpp"

namespace iptv {

enum class ContentTab { Live, Vod, Series };

struct CategoriesResult {
    bool ok = false;
    std::string error;
    std::vector<Category> categories;
};

// Porte de `getLiveCategories`/`getVodCategories`/`getSeriesCategories`.
CategoriesResult fetchCategories(const Credentials& creds, ContentTab tab);

struct ItemsResult {
    bool ok = false;
    std::string error;
    std::vector<CatalogItem> items;
};

// Porte de `getLiveStreams`/`getVodStreams`/`getSeries`. `categories` é usado
// só pra preencher `categoryName` (igual `categoryNameFor()` no web).
ItemsResult fetchItems(const Credentials& creds, ContentTab tab, const std::string& categoryId,
                        const std::vector<Category>& categories);

struct M3uCatalogResult {
    bool ok = false;
    std::string error;
    std::vector<M3uCategory> categories;
};

// Busca e faz o parse da playlist inteira de uma vez (M3U não tem endpoints
// separados por categoria como o Xtream). O resultado fica em cache por URL,
// já que as abas TV ao vivo/Filmes/Séries vêm da mesma playlist;
// `refresh` força baixar de novo. Seguro de chamar de várias threads.
M3uCatalogResult fetchM3uCatalog(const std::string& m3uUrl, bool refresh = false);

}  // namespace iptv
