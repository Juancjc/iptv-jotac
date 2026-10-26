#pragma once

#include <optional>
#include <string>
#include <vector>

#include "data/catalog_types.hpp"
#include "data/xtream_client.hpp"
#include "third_party/nlohmann/json.hpp"

namespace iptv {

enum class AuthMode { Xtream, M3u };

// Mesmos nomes de campo (camelCase) de `storage.ts`'s `StoredAuth`.
// `listId`/`listName` identificam a lista na aba "Listas" (como no IPTV
// Jotac, várias listas podem ficar salvas; só uma fica conectada).
struct StoredAuth {
    AuthMode mode = AuthMode::Xtream;
    Credentials credentials;
    std::string m3uUrl;  // só quando mode == M3u
    std::string listId;
    std::string listName;
};

// Salva a lista (criando `listId` se vier vazio) e a marca como conectada.
void saveAuth(StoredAuth& auth);
std::optional<StoredAuth> loadAuth();
void clearAuth();

// Todas as listas salvas, na ordem em que foram adicionadas.
std::vector<StoredAuth> loadLists();
// Salva/atualiza a lista sem mudar qual está conectada.
void upsertList(StoredAuth& auth);
// Remove a lista; se era a conectada, nenhuma fica conectada.
void removeList(const std::string& listId);

// Porte de `FavoriteItem`/`HistoryEntry` de `storage.ts` — mesmos nomes de
// campo (camelCase) do formato usado nos outros clientes do projeto.
struct FavoriteItem {
    std::string id;
    ContentKind kind = ContentKind::Live;
    std::string name;
    std::string logo;
    std::string categoryName;
    long streamId = 0;
    std::string containerExtension;
    std::string url;  // m3uUrl, quando aplicável
};

FavoriteItem toFavoriteItem(const CatalogItem& item);
CatalogItem fromFavoriteItem(const FavoriteItem& item);

std::vector<FavoriteItem> loadFavorites();
bool isFavorite(const std::string& id);
// Alterna e já persiste — devolve a lista atualizada (igual `toggleFavorite` no web).
std::vector<FavoriteItem> toggleFavorite(const FavoriteItem& item);
void replaceFavorites(const std::vector<FavoriteItem>& items);

struct HistoryEntry : FavoriteItem {
    long long watchedAt = 0;
    // -1 = ausente (equivalente ao campo opcional do TypeScript).
    double positionSeconds = -1;
    double durationSeconds = -1;
};

nlohmann::json favoriteItemToJson(const FavoriteItem& item);
FavoriteItem favoriteItemFromJson(const nlohmann::json& j);
nlohmann::json historyEntryToJson(const HistoryEntry& entry);
HistoryEntry historyEntryFromJson(const nlohmann::json& j);

std::vector<HistoryEntry> loadHistory();
void recordHistory(const FavoriteItem& item);
void updateProgress(const std::string& id, double positionSeconds, double durationSeconds);
struct Progress {
    double positionSeconds = 0;
    double durationSeconds = 0;
};
std::optional<Progress> getProgress(const std::string& id);
void clearHistory();
void removeHistoryItem(const std::string& id);
void replaceHistory(const std::vector<HistoryEntry>& entries);

}  // namespace iptv
