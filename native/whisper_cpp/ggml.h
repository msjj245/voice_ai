// Placeholder for ggml.h
// This is a minimal header for compilation
// Download actual file from: https://github.com/ggerganov/whisper.cpp

#ifndef GGML_H
#define GGML_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Basic types
typedef uint16_t ggml_fp16_t;

// Tensor structure
struct ggml_tensor {
    int     type;
    int     n_dims;
    int64_t ne[4];
    size_t  nb[4];
    void  * data;
    char    name[64];
};

// Context
struct ggml_context {
    size_t mem_size;
    void * mem_buffer;
    bool   mem_buffer_owned;
    bool   no_alloc;
};

// Initialize
struct ggml_context * ggml_init(struct ggml_init_params params);
void ggml_free(struct ggml_context * ctx);

// Operations
struct ggml_tensor * ggml_new_tensor_1d(struct ggml_context * ctx, int type, int64_t ne0);
struct ggml_tensor * ggml_new_tensor_2d(struct ggml_context * ctx, int type, int64_t ne0, int64_t ne1);
struct ggml_tensor * ggml_new_tensor_3d(struct ggml_context * ctx, int type, int64_t ne0, int64_t ne1, int64_t ne2);

#ifdef __cplusplus
}
#endif

#endif // GGML_H