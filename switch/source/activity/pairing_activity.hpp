#pragma once

#include <borealis.hpp>
#include <memory>
#include <optional>

#include "data/pairing_server.hpp"
#include "data/storage.hpp"

class QrCodeView;

// "Pelo celular (QR Code)" — igual ao do app Android: mostra um QR Code com
// o endereço de um formulário servido pelo próprio Switch na rede local. O
// servidor só fica no ar enquanto esta tela está aberta.
class PairingActivity : public brls::Activity {
  public:
    // Com `editing`, o formulário edita essa lista em vez de criar outra.
    explicit PairingActivity(std::optional<iptv::StoredAuth> editing = std::nullopt);
    ~PairingActivity() override;

    brls::View* createContentView() override;
    void onContentAvailable() override;

  private:
    std::optional<iptv::StoredAuth> editing;
    std::unique_ptr<iptv::PairingServer> server;
    std::shared_ptr<bool> alive = std::make_shared<bool>(true);
    bool busy = false;

    QrCodeView* qrView = nullptr;
    brls::Label* urlLabel = nullptr;
    brls::Label* statusLabel = nullptr;

    void handleSubmission(const iptv::PairingSubmission& submission);
    void setStatus(const std::string& text, bool isError);
};
