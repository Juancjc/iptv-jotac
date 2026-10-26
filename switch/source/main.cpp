#include <borealis.hpp>
#include <curl/curl.h>

#include "activity/catalog_activity.hpp"
#include "activity/login_activity.hpp"
#include "data/auth_repository.hpp"
#include "data/updater.hpp"

/**
 * IPTV Jotac para homebrew de Nintendo Switch (borealis + mpv), baseado no
 * switchiptv (gomprime, GPLv3) e adaptado ao visual/fluxo do app IPTV Jotac.
 */
int main(int argc, char* argv[]) {
    for (int i = 1; i < argc; i++) {
        if (std::strcmp(argv[i], "-d") == 0) {
            brls::Logger::setLogLevel(brls::LogLevel::LOG_DEBUG);
        }
    }

    // Convenção do hbloader: argv[0] é o caminho absoluto do próprio .nro
    // em execução (ex.: "sdmc:/switch/IptvJotac.nro") — é isso
    // que o atualizador (data/updater.cpp) sobrescreve ao instalar uma
    // versão nova. Em plataformas sem esse argumento (build desktop), fica
    // vazio e o botão de atualizar simplesmente reporta erro.
    if (argc > 0 && argv[0] != nullptr) {
        iptv::setExecutablePath(argv[0]);
    }

    // Precisa rodar na thread principal, antes de qualquer chamada de rede —
    // curl_easy_init() faz essa inicialização sozinho se ninguém chamar antes,
    // mas a primeira chamada de rede do app (login) roda em thread de fundo
    // via brls::async(), e curl_global_init() não é thread-safe.
    curl_global_init(CURL_GLOBAL_DEFAULT);

    brls::Platform::APP_LOCALE_DEFAULT = brls::LOCALE_AUTO;

    if (!brls::Application::init()) {
        brls::Logger::error("Unable to init Borealis application");
        return EXIT_FAILURE;
    }

    brls::Application::createWindow("IPTV Jotac");
    brls::Application::getPlatform()->setThemeVariant(brls::ThemeVariant::DARK);
    brls::Application::setGlobalQuit(false);

    // Mesma paleta do app IPTV Jotac (lib/app.dart): vermelho sobre fundo
    // quase preto. Só o tema escuro importa (setThemeVariant acima sempre
    // força DARK).
    {
        NVGcolor jotacRed = nvgRGB(224, 72, 72);
        NVGcolor jotacDarkRed = nvgRGB(197, 50, 58);
        brls::Theme& dark = brls::Theme::getDarkTheme();
        dark.addColor("brls/background", nvgRGB(16, 14, 18));
        dark.addColor("brls/sidebar/background", nvgRGB(18, 16, 20));
        dark.addColor("brls/accent", jotacRed);
        dark.addColor("brls/click_pulse", nvgRGBA(224, 72, 72, 38));
        dark.addColor("brls/highlight/color1", jotacRed);
        dark.addColor("brls/highlight/color2", jotacDarkRed);
        dark.addColor("brls/sidebar/active_item", jotacRed);
        dark.addColor("brls/button/primary_enabled_background", jotacRed);
        dark.addColor("brls/button/primary_enabled_text", nvgRGB(255, 255, 255));
        dark.addColor("brls/button/highlight_enabled_text", jotacRed);
        dark.addColor("brls/button/highlight_disabled_text", jotacRed);
        dark.addColor("brls/list/listItem_value_color", jotacRed);
        dark.addColor("brls/slider/line_filled", jotacRed);
    }

    iptv::StoredAuth restoredAuth;
    if (iptv::tryRestoreAuth(restoredAuth)) {
        brls::Application::pushActivity(new CatalogActivity(restoredAuth));
    } else {
        brls::Application::pushActivity(new LoginActivity());
    }

    while (brls::Application::mainLoop())
        ;

    curl_global_cleanup();

    return EXIT_SUCCESS;
}
