#include "activity/pairing_activity.hpp"

#include "activity/catalog_activity.hpp"
#include "data/auth_repository.hpp"
#include "ui/qr_code_view.hpp"

PairingActivity::PairingActivity(std::optional<iptv::StoredAuth> editing) : editing(std::move(editing)) {}

PairingActivity::~PairingActivity() {
    *alive = false;
    // Para e espera a thread do servidor antes de liberar esta tela.
    server.reset();
}

brls::View* PairingActivity::createContentView() {
    brls::Box* box = new brls::Box();
    box->setAxis(brls::Axis::COLUMN);
    box->setAlignItems(brls::AlignItems::CENTER);
    box->setJustifyContent(brls::JustifyContent::CENTER);
    box->setGrow(1.0f);
    box->setPadding(20);

    brls::Label* instructions = new brls::Label();
    instructions->setText("Aponte a câmera do celular para o QR Code abaixo.\n"
                          "O celular precisa estar no mesmo Wi-Fi do Switch.");
    instructions->setHorizontalAlign(brls::HorizontalAlign::CENTER);
    instructions->setFontSize(20);
    instructions->setMarginBottom(20);
    box->addView(instructions);

    qrView = new QrCodeView();
    qrView->setMarginBottom(16);
    box->addView(qrView);

    brls::Label* orLabel = new brls::Label();
    orLabel->setText("Ou acesse pelo navegador do celular:");
    orLabel->setFontSize(16);
    orLabel->setTextColor(nvgRGB(143, 133, 143));
    box->addView(orLabel);

    urlLabel = new brls::Label();
    urlLabel->setText("Iniciando...");
    urlLabel->setFontSize(24);
    urlLabel->setMarginBottom(16);
    box->addView(urlLabel);

    statusLabel = new brls::Label();
    statusLabel->setText("Aguardando dados do celular...");
    statusLabel->setFontSize(18);
    statusLabel->setHorizontalAlign(brls::HorizontalAlign::CENTER);
    box->addView(statusLabel);

    // O AppletFrame lê o título do item da view de conteúdo ao montá-la.
    std::string title = editing ? "Editar lista pelo celular" : "Adicionar lista pelo celular";
    box->getAppletFrameItem()->title = title;
    brls::AppletFrame* frame = new brls::AppletFrame(box);
    frame->setTitle(title);
    return frame;
}

void PairingActivity::onContentAvailable() {
    std::optional<iptv::PairingSubmission> initial;
    if (editing) {
        iptv::PairingSubmission prefill;
        prefill.name = editing->listName;
        prefill.isXtream = editing->mode == iptv::AuthMode::Xtream;
        prefill.m3uUrl = editing->m3uUrl;
        prefill.xtreamHost = editing->credentials.serverUrl;
        prefill.xtreamUsername = editing->credentials.username;
        prefill.xtreamPassword = editing->credentials.password;
        initial = prefill;
    }

    // O servidor chama de volta numa thread própria: só agenda o trabalho
    // na thread principal, e só se esta tela ainda existir.
    auto aliveFlag = alive;
    server = std::make_unique<iptv::PairingServer>(initial ? &*initial : nullptr,
                                                   [this, aliveFlag](iptv::PairingSubmission submission) {
                                                       brls::sync([this, aliveFlag, submission]() {
                                                           if (!*aliveFlag) return;
                                                           handleSubmission(submission);
                                                       });
                                                   });

    std::string url = server->start();
    if (url.empty()) {
        urlLabel->setText("-");
        setStatus(server->error(), true);
        return;
    }
    urlLabel->setText(url);
    qrView->setText(url);
}

void PairingActivity::setStatus(const std::string& text, bool isError) {
    statusLabel->setText(text);
    statusLabel->setTextColor(isError ? nvgRGB(255, 90, 95) : nvgRGB(201, 194, 201));
}

void PairingActivity::handleSubmission(const iptv::PairingSubmission& submission) {
    if (busy) return;
    busy = true;
    setStatus("Lista recebida! Conectando...", false);

    iptv::LoginInput input;
    input.listName = submission.name;
    if (editing) input.listId = editing->listId;
    if (submission.isXtream) {
        input.formMode = iptv::LoginFormMode::Xtream;
        input.serverUrl = submission.xtreamHost;
        input.username = submission.xtreamUsername;
        input.password = submission.xtreamPassword;
    } else {
        input.formMode = iptv::LoginFormMode::M3uDirect;
        input.serverUrl = submission.m3uUrl;
    }

    auto aliveFlag = alive;
    brls::async([this, aliveFlag, input]() {
        iptv::LoginOutcome outcome = iptv::performLogin(input);
        brls::sync([this, aliveFlag, outcome]() {
            if (!*aliveFlag) return;
            busy = false;
            if (!outcome.ok) {
                setStatus("Não foi possível conectar: " + outcome.error + "\nCorrija no celular e envie de novo.", true);
                return;
            }
            iptv::StoredAuth auth = outcome.auth;
            brls::Application::clear();
            brls::Application::pushActivity(new CatalogActivity(auth));
        });
    });
}
