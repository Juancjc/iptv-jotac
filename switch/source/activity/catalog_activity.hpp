#pragma once

#include <borealis.hpp>
#include <functional>
#include <memory>
#include <vector>

#include "data/catalog_types.hpp"
#include "data/storage.hpp"
#include "data/updater.hpp"

// Tela principal — `brls::TabFrame` padrão (barra lateral própria com as
// abas do IPTV Jotac: TV ao vivo/Filmes/Séries/Favoritos/Assistidos/Listas)
// e o painel da aba atual ao lado.
class CatalogActivity : public brls::Activity {
  public:
    explicit CatalogActivity(iptv::StoredAuth auth);
    ~CatalogActivity() override;

    brls::View* createContentView() override;
    void onContentAvailable() override;

  private:
    iptv::StoredAuth auth;
    brls::TabFrame* tabFrame = nullptr;
    std::shared_ptr<bool> alive = std::make_shared<bool>(true);

    void triggerSearch();
    void showAbout();
    std::function<void(iptv::CatalogItem, std::vector<iptv::CatalogItem>)> buildOnSelect();

    // `manual`: true quando veio do botão em "Sobre" (mostra diálogo mesmo
    // sem atualização/erro); false na checagem silenciosa de abertura do
    // app (só aparece algo na tela se achar versão nova).
    void checkForUpdates(bool manual);
    void promptInstallUpdate(const iptv::UpdateCheckResult& update);
    void performUpdateDownload(const std::string& downloadUrl, const std::string& latestVersion);
};
