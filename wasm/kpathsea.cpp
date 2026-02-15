#include <kpathsea/kpathsea.h>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <string>
#include <vector>
#include <sys/stat.h>
#include <map>
#include <emscripten.h>

const char *KPSEVERSION = "kpathsea version 6.3.2";
int kpse_make_tex_discard_errors = 0;

void kpse_set_program_name(const char *argv0, const char *progname) {}
void kpse_set_program_enabled(kpse_file_format_type format, int enabled, kpse_src_type src) {}

static bool file_exists(const char *path) {
    struct stat buffer;
    return (stat(path, &buffer) == 0);
}

// External JS function to load file from remote server
extern "C" {
    extern int kpse_load_file_remote(const char *name, int format);
}

static std::string make_absolute(const char *path) {
    if (path[0] == '/') return path;
    return "/" + std::string(path);
}

char *kpse_find_file(const char *name, kpse_file_format_type format, int must_exist) {
    if (file_exists(name)) {
        return strdup(make_absolute(name).c_str());
    }

    // Try common extensions if not present
    static std::map<kpse_file_format_type, std::vector<std::string>> extensions = {
        {kpse_tfm_format, {".tfm"}},
        {kpse_type1_format, {".pfb", ".pfa"}},
        {kpse_vf_format, {".vf"}},
        {kpse_mf_format, {".mf"}},
        {kpse_truetype_format, {".ttf", ".ttc"}},
        {kpse_opentype_format, {".otf"}},
        {kpse_fontmap_format, {".map"}},
        {kpse_cmap_format, {"", ".cmap"}},
        {kpse_enc_format, {".enc"}},
    };

    auto it = extensions.find(format);
    if (it != extensions.end()) {
        for (const auto& ext : it->second) {
            std::string full_name = std::string(name) + ext;
            if (file_exists(full_name.c_str())) {
                return strdup(make_absolute(full_name.c_str()).c_str());
            }
            // Try to load from remote
            if (kpse_load_file_remote(full_name.c_str(), (int)format)) {
                return strdup(make_absolute(full_name.c_str()).c_str());
            }
        }
    }
    
    // Try original name from remote
    if (kpse_load_file_remote(name, (int)format)) {
        return strdup(make_absolute(name).c_str());
    }

    return nullptr;
}

char *kpse_make_tex(kpse_file_format_type format, const char *name) {
    return nullptr;
}

char *kpse_var_value(const char *var) {
    if (strcmp(var, "SELFAUTOLOC") == 0) {
        return strdup(".");
    }
    return nullptr;
}

char *concat(const char *s1, const char *s2) {
    char *res = (char*)malloc(strlen(s1) + strlen(s2) + 1);
    strcpy(res, s1);
    strcat(res, s2);
    return res;
}
