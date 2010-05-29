#ifndef __SIREN_H
#define __SIREN_H

#include <portaudio.h>
#include <tlsf.h>
#include <libkern/OSAtomic.h>

#define POOL_SIZE 1024 * 1024

static char pool[POOL_SIZE];

int InitDSPSystem();

typedef float Sample32; 

typedef void (*TransitionFunc)(void *);
typedef Sample32 (*RenderFunc)(void *);

typedef struct _Voice {
  RenderFunc render;
  TransitionFunc trans;
  void *state;
  struct _Voice *next;
} Voice;

typedef Voice *VoiceID;

typedef struct _DSPKernel {
  double fs;
  PaStream *stream;
  Voice *voiceList;
  OSSpinLock lock;
} DSPKernel;

int NewDSPKernel(double fs, DSPKernel **outKernel);

int DisposeDSPKernel(DSPKernel *kernel);

void *DSPKernelMalloc(DSPKernel *kernel, size_t sz);

int DSPKernelFree(DSPKernel *kernel, void *p);

static inline void DSPKernelLock(DSPKernel *kernel);

static inline void DSPKernelUnlock(DSPKernel *kernel);

int DSPKernelCallback(const void *input, void *output,
                      unsigned long frameCount,
                      const PaStreamCallbackTimeInfo *timeInfo,
                      PaStreamCallbackFlags statusFlags,
                      DSPKernel *kernel);

int DSPKernelStart(DSPKernel *kernel);

int DSPKernelStop(DSPKernel *kernel);

Voice *NewVoice(DSPKernel *kernel, RenderFunc render, TransitionFunc trans, void *state);

int RemoveVoice(DSPKernel *kernel, Voice *remove);

#endif

