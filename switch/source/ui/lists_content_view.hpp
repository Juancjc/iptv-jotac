#pragma once

#include <borealis.hpp>

#include "data/storage.hpp"

// Aba "Listas" — igual à do IPTV Jotac: mostra as listas salvas e permite
// conectar, editar, excluir e adicionar. Só uma lista fica conectada por vez
// (a que alimenta TV ao vivo/Filmes/Séries).
class ListsContentView : public brls::Box {
  public:
    explicit ListsContentView(iptv::StoredAuth connected);

  private:
    iptv::StoredAuth connected;
    brls::Box* listColumn = nullptr;

    void rebuild();
    brls::View* buildListRow(const iptv::StoredAuth& list, bool isConnected);
    void confirmRemove(const iptv::StoredAuth& list);
};

// Troca a lista conectada recriando a tela principal (adiada pro próximo
// frame: quem chama é uma view que será destruída junto).
void connectToList(iptv::StoredAuth list);
