#include "ui/qr_code_view.hpp"

#include <algorithm>

#include "third_party/qrcodegen/qrcodegen.hpp"

QrCodeView::QrCodeView() {
    this->setWidth(260);
    this->setHeight(260);
}

void QrCodeView::setText(const std::string& text) {
    qrcodegen::QrCode qr = qrcodegen::QrCode::encodeText(text.c_str(), qrcodegen::QrCode::Ecc::MEDIUM);
    size = qr.getSize();
    modules.assign(static_cast<size_t>(size * size), false);
    for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) modules[static_cast<size_t>(y * size + x)] = qr.getModule(x, y);
    }
}

void QrCodeView::draw(NVGcontext* vg, float x, float y, float width, float height, brls::Style style,
                      brls::FrameContext* ctx) {
    float side = std::min(width, height);
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x, y, side, side, 12);
    nvgFillColor(vg, nvgRGB(255, 255, 255));
    nvgFill(vg);
    if (size == 0) return;

    // 4 módulos de margem branca em volta, como pede a especificação.
    const int quietZone = 4;
    float cell = side / static_cast<float>(size + quietZone * 2);
    nvgBeginPath(vg);
    for (int row = 0; row < size; row++) {
        for (int col = 0; col < size; col++) {
            if (!modules[static_cast<size_t>(row * size + col)]) continue;
            // +0.5 evita frestas entre módulos vizinhos por arredondamento.
            nvgRect(vg, x + (col + quietZone) * cell, y + (row + quietZone) * cell, cell + 0.5f, cell + 0.5f);
        }
    }
    nvgFillColor(vg, nvgRGB(0, 0, 0));
    nvgFill(vg);
}
