#ifndef __SIREN_H
#define __SIREN_H

#include <portaudio.h>
#include <tlsf.h>
#include <libkern/OSAtomic.h>

#define POOL_SIZE 1024 * 1024

static char pool[POOL_SIZE];

int InitDSPSystem();

typedef float Sample32; 

typedef Sample32 (*RenderFunc)(float, float, int, void *);

typedef struct _Voice {
  RenderFunc render;
  int frame;
  void *state;
  struct _Voice *next;
} Voice;

typedef Voice *VoiceID;

typedef struct _DSPKernel {
  double fs;
  double ts;
  PaStream *stream;
  int channels;
  int frame;
  Voice *voiceList;
  OSSpinLock lock;
} DSPKernel;

int DSPKernelDeviceCount();

void DSPKernelDeviceName(int deviceID, const char **outDeviceName);

int NewDSPKernel(int deviceID, int channels, double fs, DSPKernel **outKernel);

int DisposeDSPKernel(DSPKernel *kernel);

static inline void DSPKernelLock(DSPKernel *kernel);

static inline void DSPKernelUnlock(DSPKernel *kernel);

int DSPKernelCallback(const void *input, void *output,
                      unsigned long frameCount,
                      const PaStreamCallbackTimeInfo *timeInfo,
                      PaStreamCallbackFlags statusFlags,
                      DSPKernel *kernel);

int DSPKernelStart(DSPKernel *kernel);

int DSPKernelStop(DSPKernel *kernel);

Voice *NewVoice(DSPKernel *kernel, RenderFunc render, void *state);

int RemoveVoice(DSPKernel *kernel, Voice *remove);

#endif

