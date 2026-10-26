#include "data/pairing_server.hpp"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <map>

namespace iptv {

namespace {

constexpr size_t kMaxRequestBytes = 64 * 1024;
constexpr int kClientTimeoutMs = 5000;

std::string trim(const std::string& s) {
    size_t start = s.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    size_t end = s.find_last_not_of(" \t\r\n");
    return s.substr(start, end - start + 1);
}

std::string toLower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

int hexValue(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

// Decodifica application/x-www-form-urlencoded ("+" = espaço, "%XX").
std::string formDecode(const std::string& value) {
    std::string out;
    out.reserve(value.size());
    for (size_t i = 0; i < value.size(); i++) {
        char c = value[i];
        if (c == '+') {
            out += ' ';
        } else if (c == '%' && i + 2 < value.size() && hexValue(value[i + 1]) >= 0 && hexValue(value[i + 2]) >= 0) {
            out += static_cast<char>(hexValue(value[i + 1]) * 16 + hexValue(value[i + 2]));
            i += 2;
        } else {
            out += c;
        }
    }
    return out;
}

std::map<std::string, std::string> parseForm(const std::string& body) {
    std::map<std::string, std::string> fields;
    size_t pos = 0;
    while (pos <= body.size()) {
        size_t amp = body.find('&', pos);
        std::string pair = body.substr(pos, amp == std::string::npos ? std::string::npos : amp - pos);
        size_t eq = pair.find('=');
        if (eq != std::string::npos) fields[formDecode(pair.substr(0, eq))] = formDecode(pair.substr(eq + 1));
        if (amp == std::string::npos) break;
        pos = amp + 1;
    }
    return fields;
}

std::string htmlEscape(const std::string& value) {
    std::string out;
    for (char c : value) {
        switch (c) {
            case '&': out += "&amp;"; break;
            case '<': out += "&lt;"; break;
            case '>': out += "&gt;"; break;
            case '"': out += "&quot;"; break;
            case '\'': out += "&#39;"; break;
            default: out += c;
        }
    }
    return out;
}

const char* kSharedCss = R"CSS(
  body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
    background:#100E12;color:#F2EDF2;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;padding:16px;box-sizing:border-box}
  .card{width:100%;max-width:420px;background:#1C181D;border:1px solid #494149;border-radius:16px;padding:24px}
  h1{font-size:20px;margin:0 0 16px;color:#E04848}
  label{display:block;margin:14px 0 6px;font-size:14px;color:#C9C2C9}
  input,select{width:100%;box-sizing:border-box;padding:12px;border-radius:10px;border:1px solid #494149;
    background:#29262C;color:#F2EDF2;font-size:16px}
  input:focus,select:focus{outline:2px solid #E04848}
  .btn{display:block;width:100%;margin-top:20px;padding:14px;border:none;border-radius:10px;
    background:#E04848;color:#fff;font-size:16px;font-weight:600;text-align:center;text-decoration:none;
    box-sizing:border-box}
  .seg{display:flex;gap:8px;margin-top:4px}
  .seg label{flex:1;margin:0;text-align:center;padding:10px;border-radius:10px;border:1px solid #494149;
    background:#29262C;cursor:pointer}
  .seg input{display:none}
  .seg input:checked + span{color:#E04848;font-weight:700}
  .success{color:#4CD964}
  .error{color:#FF5A5F}
  .hidden{display:none}
)CSS";

std::string pageHtml(const std::string& message, bool isError) {
    return std::string("<!doctype html><html lang=\"pt-BR\"><head><meta charset=\"utf-8\">"
                       "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
                       "<title>IPTV Jotac</title><style>") +
           kSharedCss + "</style></head><body><div class=\"card\"><h1>IPTV Jotac</h1><p class=\"" +
           (isError ? "error" : "success") + "\">" + htmlEscape(message) + "</p>" +
           (isError ? "<a class=\"btn\" href=\"javascript:history.back()\">Voltar</a>" : "") +
           "</div></body></html>";
}

std::string httpResponse(int status, const std::string& body) {
    std::string statusText = status == 200 ? "200 OK" : status == 404 ? "404 Not Found" : "400 Bad Request";
    return "HTTP/1.1 " + statusText +
           "\r\nContent-Type: text/html; charset=utf-8\r\nCache-Control: no-store\r\nContent-Length: " +
           std::to_string(body.size()) + "\r\nConnection: close\r\n\r\n" + body;
}

void sendAll(int fd, const std::string& data) {
    size_t sent = 0;
    while (sent < data.size()) {
        ssize_t n = send(fd, data.data() + sent, data.size() - sent, 0);
        if (n <= 0) return;
        sent += static_cast<size_t>(n);
    }
}

// Lê do socket com timeout; devolve false em erro/timeout/conexão fechada.
bool recvSome(int fd, std::string& buffer) {
    struct pollfd pfd = {fd, POLLIN, 0};
    if (poll(&pfd, 1, kClientTimeoutMs) <= 0) return false;
    char chunk[4096];
    ssize_t n = recv(fd, chunk, sizeof(chunk), 0);
    if (n <= 0) return false;
    buffer.append(chunk, static_cast<size_t>(n));
    return true;
}

std::string localIPv4() {
#ifdef __SWITCH__
    // No libnx, gethostid() devolve o IP atual do console (é o que o
    // netloader do hbmenu usa pra mostrar o endereço).
    struct in_addr addr;
    addr.s_addr = static_cast<in_addr_t>(gethostid());
    if (addr.s_addr != 0 && addr.s_addr != htonl(INADDR_LOOPBACK)) return inet_ntoa(addr);
#endif
    // Desktop: um socket UDP "conectado" revela a interface de saída sem
    // mandar nenhum pacote.
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0) return "127.0.0.1";
    struct sockaddr_in remote;
    std::memset(&remote, 0, sizeof(remote));
    remote.sin_family = AF_INET;
    remote.sin_port = htons(53);
    remote.sin_addr.s_addr = inet_addr("8.8.8.8");
    std::string ip = "127.0.0.1";
    if (connect(fd, reinterpret_cast<struct sockaddr*>(&remote), sizeof(remote)) == 0) {
        struct sockaddr_in local;
        socklen_t len = sizeof(local);
        if (getsockname(fd, reinterpret_cast<struct sockaddr*>(&local), &len) == 0) ip = inet_ntoa(local.sin_addr);
    }
    close(fd);
    return ip;
}

}  // namespace

PairingServer::PairingServer(const PairingSubmission* initial, SubmissionCallback onSubmission)
    : editing(initial != nullptr), onSubmission(std::move(onSubmission)) {
    if (initial) this->initial = *initial;
}

PairingServer::~PairingServer() {
    stop();
}

std::string PairingServer::start(int preferredPort) {
    listenFd = socket(AF_INET, SOCK_STREAM, 0);
    if (listenFd < 0) {
        lastError = "Não foi possível abrir o socket de rede.";
        return "";
    }
    int yes = 1;
    setsockopt(listenFd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

    struct sockaddr_in addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    // Porta fixa e incomum primeiro (mais fácil de digitar à mão); se
    // estiver ocupada, qualquer porta livre.
    addr.sin_port = htons(static_cast<uint16_t>(preferredPort));
    if (bind(listenFd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) != 0) {
        addr.sin_port = 0;
        if (bind(listenFd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) != 0) {
            lastError = "Não foi possível reservar uma porta de rede.";
            close(listenFd);
            listenFd = -1;
            return "";
        }
    }
    if (listen(listenFd, 4) != 0) {
        lastError = "Não foi possível iniciar o servidor local.";
        close(listenFd);
        listenFd = -1;
        return "";
    }

    struct sockaddr_in bound;
    socklen_t len = sizeof(bound);
    int port = preferredPort;
    if (getsockname(listenFd, reinterpret_cast<struct sockaddr*>(&bound), &len) == 0) port = ntohs(bound.sin_port);

    running = true;
    worker = std::thread([this]() { serveLoop(); });
    return "http://" + localIPv4() + ":" + std::to_string(port);
}

void PairingServer::stop() {
    if (!running.exchange(false)) return;
    if (worker.joinable()) worker.join();
    if (listenFd >= 0) {
        close(listenFd);
        listenFd = -1;
    }
}

void PairingServer::serveLoop() {
    while (running) {
        // Espera com timeout curto pra perceber o stop() rápido.
        struct pollfd pfd = {listenFd, POLLIN, 0};
        if (poll(&pfd, 1, 250) <= 0) continue;
        int clientFd = accept(listenFd, nullptr, nullptr);
        if (clientFd < 0) continue;
        handleClient(clientFd);
        close(clientFd);
    }
}

void PairingServer::handleClient(int clientFd) {
    std::string request;
    size_t headerEnd;
    while ((headerEnd = request.find("\r\n\r\n")) == std::string::npos) {
        if (request.size() > kMaxRequestBytes || !recvSome(clientFd, request)) return;
    }

    std::string headers = request.substr(0, headerEnd);
    std::string method = headers.substr(0, headers.find(' '));

    if (method == "GET") {
        sendAll(clientFd, httpResponse(200, formHtml()));
        return;
    }
    if (method != "POST") {
        sendAll(clientFd, httpResponse(404, "not found"));
        return;
    }

    size_t contentLength = 0;
    std::string lowerHeaders = toLower(headers);
    size_t clPos = lowerHeaders.find("content-length:");
    if (clPos != std::string::npos) {
        contentLength = static_cast<size_t>(std::strtoul(headers.c_str() + clPos + 15, nullptr, 10));
    }
    if (contentLength > kMaxRequestBytes) {
        sendAll(clientFd, httpResponse(400, pageHtml("Dados grandes demais.", true)));
        return;
    }
    std::string body = request.substr(headerEnd + 4);
    while (body.size() < contentLength) {
        if (!recvSome(clientFd, body)) return;
    }
    body.resize(contentLength);

    sendAll(clientFd, httpResponse(200, handlePost(body)));
}

std::string PairingServer::handlePost(const std::string& body) {
    std::map<std::string, std::string> fields = parseForm(body);
    PairingSubmission submission;
    submission.name = trim(fields["name"]);
    // Na edição o tipo da lista não muda, mesmo que o formulário mande outro.
    submission.isXtream = editing ? initial.isXtream : fields["type"] == "xtream";

    if (submission.name.empty()) return pageHtml("Informe um nome para a lista.", true);

    if (submission.isXtream) {
        submission.xtreamHost = trim(fields["host"]);
        submission.xtreamUsername = trim(fields["user"]);
        submission.xtreamPassword = trim(fields["pass"]);
        if (submission.xtreamPassword.empty() && editing) submission.xtreamPassword = initial.xtreamPassword;
        if (submission.xtreamHost.empty() || submission.xtreamUsername.empty() || submission.xtreamPassword.empty()) {
            return pageHtml("Preencha host, usuário e senha.", true);
        }
    } else {
        submission.m3uUrl = trim(fields["url"]);
        if (submission.m3uUrl.find("://") == std::string::npos) return pageHtml("URL inválida.", true);
    }

    if (onSubmission) onSubmission(submission);
    return pageHtml(editing ? "Alterações enviadas! O Switch vai salvar e conectar a lista."
                            : "Lista enviada! Pode voltar para o Switch, ela já vai aparecer lá.",
                    false);
}

std::string PairingServer::formHtml() const {
    bool xtream = editing && initial.isXtream;
    std::string typeSelector =
        editing ? std::string("<input type=\"hidden\" name=\"type\" value=\"") + (xtream ? "xtream" : "m3u") + "\">"
                : R"HTML(
    <div class="seg">
      <label><input type="radio" name="type" value="m3u" checked onchange="toggleType()"><span>URL M3U</span></label>
      <label><input type="radio" name="type" value="xtream" onchange="toggleType()"><span>Xtream Codes</span></label>
    </div>)HTML";

    std::string html;
    html += "<!doctype html><html lang=\"pt-BR\"><head><meta charset=\"utf-8\">"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">";
    html += std::string("<title>IPTV Jotac - ") + (editing ? "Editar" : "Adicionar") + " lista</title><style>";
    html += kSharedCss;
    html += "</style></head><body><div class=\"card\">";
    html += std::string("<h1>") + (editing ? "Editar lista no Switch" : "Adicionar lista no Switch") + "</h1>";
    html += "<form method=\"post\">" + typeSelector;
    html += "<label for=\"name\">Nome da lista</label>"
            "<input id=\"name\" name=\"name\" type=\"text\" required placeholder=\"Minha lista\" value=\"" +
            htmlEscape(initial.name) + "\">";
    html += std::string("<div id=\"m3u-fields\"") + (xtream ? " class=\"hidden\"" : "") + ">" +
            "<label for=\"url\">URL do M3U/M3U8</label>"
            "<input id=\"url\" name=\"url\" type=\"url\" placeholder=\"http://exemplo.com/lista.m3u8\" value=\"" +
            htmlEscape(initial.m3uUrl) + "\"></div>";
    html += std::string("<div id=\"xtream-fields\"") + (xtream ? "" : " class=\"hidden\"") + ">" +
            "<label for=\"host\">Host (http(s)://host:porta)</label>"
            "<input id=\"host\" name=\"host\" type=\"text\" placeholder=\"http://exemplo.com:8080\" value=\"" +
            htmlEscape(initial.xtreamHost) + "\">" +
            "<label for=\"user\">Usuário</label>"
            "<input id=\"user\" name=\"user\" type=\"text\" value=\"" +
            htmlEscape(initial.xtreamUsername) + "\">" +
            "<label for=\"pass\">Senha</label>"
            "<input id=\"pass\" name=\"pass\" type=\"password\"" +
            (editing ? " placeholder=\"Deixe em branco para manter a senha atual\"" : "") + "></div>";
    html += std::string("<button class=\"btn\" type=\"submit\">") +
            (editing ? "Salvar no Switch" : "Enviar para o Switch") + "</button></form></div>";
    html += std::string("<script>var editing = ") + (editing ? "true" : "false") + ";";
    html += R"JS(
function toggleType() {
  var xtream = document.querySelector('input[name=type]:checked, input[name=type][type=hidden]').value === 'xtream';
  document.getElementById('m3u-fields').classList.toggle('hidden', xtream);
  document.getElementById('xtream-fields').classList.toggle('hidden', !xtream);
  document.getElementById('url').required = !xtream;
  document.getElementById('host').required = xtream;
  document.getElementById('user').required = xtream;
  document.getElementById('pass').required = xtream && !editing;
}
toggleType();
</script></body></html>)JS";
    return html;
}

}  // namespace iptv
