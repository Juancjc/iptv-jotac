#include "ui/lists_content_view.hpp"

#include "activity/catalog_activity.hpp"
#include "activity/login_activity.hpp"

void connectToList(iptv::StoredAuth list) {
    brls::sync([list]() mutable {
        iptv::saveAuth(list);
        brls::Application::clear();
        brls::Application::pushActivity(new CatalogActivity(list));
    });
}

ListsContentView::ListsContentView(iptv::StoredAuth connected) : connected(std::move(connected)) {
    this->setAxis(brls::Axis::COLUMN);
    this->setPadding(20, 30, 20, 30);

    brls::Box* header = new brls::Box();
    header->setAxis(brls::Axis::ROW);
    header->setAlignItems(brls::AlignItems::CENTER);
    header->setMarginBottom(16);

    brls::Label* title = new brls::Label();
    title->setText("Minhas listas");
    title->setFontSize(28);
    title->setGrow(1.0f);
    header->addView(title);

    brls::Button* addButton = (brls::Button*)brls::Button::create();
    addButton->setText("Adicionar lista");
    addButton->registerClickAction([](brls::View*) {
        brls::Application::pushActivity(new LoginActivity());
        return true;
    });
    header->addView(addButton);
    this->addView(header);

    brls::ScrollingFrame* scroll = new brls::ScrollingFrame();
    scroll->setGrow(1.0f);
    listColumn = new brls::Box();
    listColumn->setAxis(brls::Axis::COLUMN);
    scroll->setContentView(listColumn);
    this->addView(scroll);

    rebuild();
}

void ListsContentView::rebuild() {
    listColumn->clearViews();
    std::vector<iptv::StoredAuth> lists = iptv::loadLists();
    if (lists.empty()) {
        brls::Label* empty = new brls::Label();
        empty->setText("Nenhuma lista salva. Use \"Adicionar lista\".");
        listColumn->addView(empty);
        return;
    }
    for (const auto& list : lists) {
        listColumn->addView(buildListRow(list, list.listId == connected.listId));
    }
}

brls::View* ListsContentView::buildListRow(const iptv::StoredAuth& list, bool isConnected) {
    brls::Box* row = new brls::Box();
    row->setAxis(brls::Axis::ROW);
    row->setAlignItems(brls::AlignItems::CENTER);
    row->setPadding(14, 16, 14, 16);
    row->setMarginBottom(10);
    row->setCornerRadius(12);
    row->setBackgroundColor(isConnected ? nvgRGBA(224, 72, 72, 40) : nvgRGB(41, 38, 44));

    brls::Box* info = new brls::Box();
    info->setAxis(brls::Axis::COLUMN);
    info->setGrow(1.0f);
    info->setMarginRight(16);

    brls::Label* name = new brls::Label();
    name->setText(isConnected ? list.listName + "  (conectada)" : list.listName);
    name->setFontSize(22);
    if (isConnected) name->setTextColor(nvgRGB(224, 72, 72));
    info->addView(name);

    brls::Label* detail = new brls::Label();
    std::string source = list.mode == iptv::AuthMode::M3u ? "M3U  |  " + list.m3uUrl
                                                          : "Xtream  |  " + list.credentials.serverUrl;
    detail->setText(source);
    detail->setFontSize(15);
    detail->setSingleLine(true);
    detail->setTextColor(nvgRGB(143, 133, 143));
    info->addView(detail);
    row->addView(info);

    iptv::StoredAuth listCopy = list;

    brls::Button* connectButton = (brls::Button*)brls::Button::create();
    connectButton->setText(isConnected ? "Conectada" : "Conectar");
    connectButton->setMarginRight(8);
    connectButton->registerClickAction([listCopy, isConnected](brls::View*) {
        if (!isConnected) connectToList(listCopy);
        return true;
    });
    row->addView(connectButton);

    brls::Button* editButton = (brls::Button*)brls::Button::create();
    editButton->setText("Editar");
    editButton->setMarginRight(8);
    editButton->registerClickAction([listCopy](brls::View*) {
        brls::Application::pushActivity(new LoginActivity(listCopy, true));
        return true;
    });
    row->addView(editButton);

    brls::Button* removeButton = (brls::Button*)brls::Button::create();
    removeButton->setText("Excluir");
    removeButton->registerClickAction([this, listCopy](brls::View*) {
        confirmRemove(listCopy);
        return true;
    });
    row->addView(removeButton);

    return row;
}

void ListsContentView::confirmRemove(const iptv::StoredAuth& list) {
    brls::Dialog* dialog = new brls::Dialog("Excluir a lista \"" + list.listName + "\"?");
    iptv::StoredAuth listCopy = list;
    bool wasConnected = list.listId == connected.listId;
    dialog->addButton("Excluir", [listCopy, wasConnected]() {
        iptv::removeList(listCopy.listId);
        std::vector<iptv::StoredAuth> remaining = iptv::loadLists();
        if (remaining.empty()) {
            brls::sync([]() {
                brls::Application::clear();
                brls::Application::pushActivity(new LoginActivity());
            });
            return;
        }
        // Recria a tela principal em vez de remover a linha na hora: o foco
        // ainda está no botão "Excluir" dela, e destruí-lo agora deixaria a
        // borealis com um ponteiro de foco inválido.
        iptv::StoredAuth next = remaining.front();
        if (!wasConnected) {
            if (auto active = iptv::loadAuth()) next = *active;
        }
        connectToList(next);
    });
    dialog->addButton("Cancelar", []() {});
    dialog->open();
}
