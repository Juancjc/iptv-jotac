#pragma once

#include <atomic>
#include <functional>
#include <string>
#include <thread>

namespace iptv {

// Dados enviados pelo navegador do celular pelo formulário de pareamento.
struct PairingSubmission {
    std::string name;
    bool isXtream = false;
    std::string m3uUrl;
    std::string xtreamHost;
    std::string xtreamUsername;
    std::string xtreamPassword;
};

// Porte de `lib/services/qr_pairing_server.dart` do app IPTV Jotac: um
// servidor HTTP mínimo na rede local com um formulário pra digitar a lista
// no celular (aberto pelo QR Code) em vez de no teclado do Switch.
//
// Com `initial`, o formulário edita uma lista existente: vem preenchido
// (menos a senha Xtream, que nunca vai pra página em HTTP puro — em branco
// mantém a senha atual) e o tipo da lista fica fixo.
class PairingServer {
  public:
    using SubmissionCallback = std::function<void(PairingSubmission)>;

    PairingServer(const PairingSubmission* initial, SubmissionCallback onSubmission);
    ~PairingServer();

    // Sobe o servidor; devolve a URL pra mostrar/codificar no QR, ou vazio
    // em caso de erro (ver `error()`).
    std::string start(int preferredPort = 58712);
    void stop();
    const std::string& error() const { return lastError; }

  private:
    bool editing = false;
    PairingSubmission initial;
    SubmissionCallback onSubmission;
    int listenFd = -1;
    std::atomic<bool> running{false};
    std::thread worker;
    std::string lastError;

    void serveLoop();
    void handleClient(int clientFd);
    std::string handlePost(const std::string& body);
    std::string formHtml() const;
};

}  // namespace iptv
