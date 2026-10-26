#include "data/m3u_parser.hpp"

#include <algorithm>
#include <sstream>
#include <unordered_map>
#include <utility>

#include "data/text_utils.hpp"

namespace iptv {

namespace {

std::string trim(const std::string& s) {
    size_t start = s.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) return "";
    size_t end = s.find_last_not_of(" \t\r\n");
    return s.substr(start, end - start + 1);
}

std::string getAttr(const std::string& line, const std::string& key) {
    std::string pattern = key + "=\"";
    size_t pos = line.find(pattern);
    if (pos == std::string::npos) return "";
    pos += pattern.size();
    size_t end = line.find('"', pos);
    if (end == std::string::npos) return "";
    return line.substr(pos, end - pos);
}

struct PendingChannel {
    std::string name;
    std::string logo;
    std::string group;
};

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}

// Lê de 1 a `maxDigits` dígitos a partir de `pos`; devolve quantos leu.
size_t readNumber(const std::string& s, size_t pos, size_t maxDigits, int& value) {
    size_t count = 0;
    value = 0;
    while (pos + count < s.size() && count < maxDigits && isDigit(s[pos + count])) {
        value = value * 10 + (s[pos + count] - '0');
        count++;
    }
    return count;
}

struct SeasonEpisode {
    bool found = false;
    size_t start = 0;
};

// Procura "S01E02"/"S1 E2" ou "1x02" no nome — equivalente ao regex
// `(?:S(\d{1,2})\s*E(\d{1,3}))|(?:(\d{1,2})x(\d{1,3}))` do app Flutter,
// escrito à mão porque std::regex é lento demais pra listas grandes.
SeasonEpisode findSeasonEpisode(const std::string& name) {
    for (size_t i = 0; i < name.size(); i++) {
        char c = name[i];
        int value = 0;
        if (c == 'S' || c == 's') {
            // Tenta com 2 e depois 1 dígito de temporada, como o regex faria.
            for (size_t digits = 2; digits >= 1; digits--) {
                size_t read = readNumber(name, i + 1, digits, value);
                if (read != digits) continue;
                size_t j = i + 1 + read;
                while (j < name.size() && (name[j] == ' ' || name[j] == '\t')) j++;
                if (j < name.size() && (name[j] == 'E' || name[j] == 'e') && readNumber(name, j + 1, 3, value) > 0) {
                    return {true, i};
                }
            }
        }
        if (isDigit(c)) {
            for (size_t digits = 2; digits >= 1; digits--) {
                size_t read = readNumber(name, i, digits, value);
                if (read != digits) continue;
                size_t j = i + read;
                if (j < name.size() && name[j] == 'x' && readNumber(name, j + 1, 3, value) > 0) {
                    return {true, i};
                }
            }
        }
    }
    return {};
}

std::string toLowerAscii(std::string s) {
    for (char& c : s) {
        if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
    }
    return s;
}

// Extensão do arquivo no fim da URL (ignorando a query string).
std::string urlExtension(const std::string& url) {
    std::string path = url.substr(0, url.find('?'));
    size_t dot = path.find_last_of('.');
    size_t slash = path.find_last_of('/');
    if (dot == std::string::npos || (slash != std::string::npos && dot < slash)) return "";
    std::string ext = toLowerAscii(path.substr(dot + 1));
    for (char c : ext) {
        if (!((c >= 'a' && c <= 'z') || isDigit(c))) return "";
    }
    return ext;
}

struct M3uClassification {
    M3uSection section = M3uSection::Live;
    std::string extension;
    std::string seriesTitle;
};

M3uClassification classifyEntry(const PendingChannel& info, const std::string& url) {
    M3uClassification result;
    result.extension = urlExtension(url);
    std::string group = toLowerAscii(info.group);

    // No app Flutter o grupo "Séries" só marca a entrada como candidata; ela
    // só vira episódio se o nome tiver o marcador de temporada/episódio.
    SeasonEpisode marker = findSeasonEpisode(info.name);
    if (marker.found) {
        std::string title = trim(info.name.substr(0, marker.start));
        while (!title.empty() && (title.back() == '-' || title.back() == '_')) title.pop_back();
        title = trim(title);
        result.section = M3uSection::Series;
        result.seriesTitle = title.empty() ? info.name : title;
        return result;
    }

    static const char* const kVodExtensions[] = {"mp4", "mkv", "avi", "m4v", "mov", "wmv"};
    bool isVodExtension = false;
    for (const char* ext : kVodExtensions) {
        if (result.extension == ext) isVodExtension = true;
    }
    if (isVodExtension || group.find("filme") != std::string::npos || group.find("movie") != std::string::npos ||
        group.find("vod") != std::string::npos) {
        result.section = M3uSection::Movies;
    }
    return result;
}

}  // namespace

std::vector<M3uCategory> parseM3u(const std::string& text) {
    std::istringstream stream(text);
    std::string line;

    std::vector<std::pair<PendingChannel, std::string>> channels;
    bool hasPending = false;
    PendingChannel pending;

    while (std::getline(stream, line)) {
        std::string trimmed = trim(line);
        if (trimmed.empty()) continue;

        if (trimmed.rfind("#EXTINF", 0) == 0) {
            pending.logo = getAttr(trimmed, "tvg-logo");
            pending.group = stripEmoji(getAttr(trimmed, "group-title"));
            if (pending.group.empty()) pending.group = "Sem categoria";
            // O nome do canal é tudo depois da primeira vírgula (os atributos
            // são separados por espaço, não vírgula, então normalmente há só
            // uma na linha) — igual `m3uParser.ts`.
            size_t commaPos = trimmed.find(',');
            pending.name = commaPos != std::string::npos ? stripEmoji(trim(trimmed.substr(commaPos + 1))) : "Sem nome";
            if (pending.name.empty()) pending.name = "Sem nome";
            hasPending = true;
            continue;
        }

        if (trimmed[0] == '#') continue;

        if (hasPending) {
            channels.emplace_back(pending, trimmed);
            hasPending = false;
        }
    }

    std::vector<M3uCategory> result;
    // (aba, categoria) -> posição em `result`. Listas grandes têm centenas de
    // milhares de entradas; procurar a categoria linearmente a cada uma
    // deixava o carregamento muito lento.
    std::unordered_map<std::string, size_t> indexByKey;
    for (auto& entry : channels) {
        const PendingChannel& info = entry.first;
        const std::string& url = entry.second;
        const M3uClassification classification = classifyEntry(info, url);

        const std::string& categoryName = classification.section == M3uSection::Series ? classification.seriesTitle
                                                                                         : info.group;
        std::string key = std::to_string(static_cast<int>(classification.section)) + '\n' + categoryName;
        auto found = indexByKey.find(key);
        size_t index;
        if (found == indexByKey.end()) {
            index = result.size();
            indexByKey.emplace(std::move(key), index);
            result.push_back(M3uCategory{categoryName, classification.section, {}});
        } else {
            index = found->second;
        }

        CatalogItem item;
        item.id = "m3u-" + url;
        switch (classification.section) {
            case M3uSection::Live:
                item.kind = ContentKind::Live;
                break;
            case M3uSection::Movies:
                item.kind = ContentKind::Vod;
                break;
            case M3uSection::Series:
                item.kind = ContentKind::Episode;
                break;
        }
        item.name = info.name;
        item.logo = info.logo;
        item.categoryId = categoryName;
        item.categoryName = categoryName;
        item.containerExtension = classification.extension;
        item.m3uUrl = url;
        result[index].channels.push_back(std::move(item));
    }
    return result;
}

}  // namespace iptv
