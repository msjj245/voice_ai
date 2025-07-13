// Placeholder for whisper.h
// Download actual file from: https://github.com/ggerganov/whisper.cpp

#ifndef WHISPER_H
#define WHISPER_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque context
struct whisper_context;
typedef struct whisper_context * whisper_context_ptr;

// Available sampling strategies
enum whisper_sampling_strategy {
    WHISPER_SAMPLING_GREEDY,
    WHISPER_SAMPLING_BEAM_SEARCH,
};

// Model information
struct whisper_model_info {
    int n_vocab;
    int n_audio_ctx;
    int n_audio_state;
    int n_audio_head;
    int n_audio_layer;
    int n_text_ctx;
    int n_text_state;
    int n_text_head;
    int n_text_layer;
    int n_mels;
    int ftype;
};

// Parameters for the whisper_full() function
struct whisper_full_params {
    enum whisper_sampling_strategy strategy;
    
    int n_threads;
    int n_max_text_ctx;
    int offset_ms;
    int duration_ms;
    
    bool translate;
    bool no_context;
    bool single_segment;
    bool print_special;
    bool print_progress;
    bool print_realtime;
    bool print_timestamps;
    
    const char * language;
    const char * initial_prompt;
    
    float temperature;
    float temperature_inc;
    float entropy_thold;
    float logprob_thold;
    float no_speech_thold;
};

// Initialize whisper context from file
struct whisper_context * whisper_init_from_file(const char * path_model);

// Free whisper context
void whisper_free(struct whisper_context * ctx);

// Run the entire model: PCM -> log mel spectrogram -> encoder -> decoder -> text
int whisper_full(
    struct whisper_context * ctx,
    struct whisper_full_params params,
    const float * samples,
    int n_samples);

// Number of segments
int whisper_full_n_segments(struct whisper_context * ctx);

// Get segment text
const char * whisper_full_get_segment_text(struct whisper_context * ctx, int i_segment);

// Get segment start time
int64_t whisper_full_get_segment_t0(struct whisper_context * ctx, int i_segment);

// Get segment end time  
int64_t whisper_full_get_segment_t1(struct whisper_context * ctx, int i_segment);

#ifdef __cplusplus
}
#endif

#endif // WHISPER_H