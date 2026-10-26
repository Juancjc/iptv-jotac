#pragma once

#include <borealis.hpp>
#include <string>
#include <vector>

// Desenha um QR Code (preto sobre fundo branco, com margem) usando o
// qrcodegen da Nayuki (MIT, em third_party/qrcodegen).
class QrCodeView : public brls::View {
  public:
    QrCodeView();

    void setText(const std::string& text);

    void draw(NVGcontext* vg, float x, float y, float width, float height, brls::Style style,
              brls::FrameContext* ctx) override;

  private:
    int size = 0;
    std::vector<bool> modules;
};
