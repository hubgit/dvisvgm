#ifndef KPATHSEA_H
#define KPATHSEA_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    kpse_tfm_format,
    kpse_ofm_format,
    kpse_type1_format,
    kpse_vf_format,
    kpse_mf_format,
    kpse_truetype_format,
    kpse_opentype_format,
    kpse_fontmap_format,
    kpse_cmap_format,
    kpse_tex_format,
    kpse_enc_format,
    kpse_tex_ps_header_format,
    kpse_sfd_format,
    kpse_pict_format,
    kpse_last_format
} kpse_file_format_type;

typedef enum {
    kpse_src_env
} kpse_src_type;

extern const char *KPSEVERSION;
extern int kpse_make_tex_discard_errors;

void kpse_set_program_name(const char *argv0, const char *progname);
void kpse_set_program_enabled(kpse_file_format_type format, int enabled, kpse_src_type src);
char *kpse_find_file(const char *name, kpse_file_format_type format, int must_exist);
char *kpse_make_tex(kpse_file_format_type format, const char *name);
char *kpse_var_value(const char *var);
char *concat(const char *s1, const char *s2);

#ifdef __cplusplus
}
#endif

#endif
