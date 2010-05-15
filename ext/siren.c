#include "siren.h"
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

static inline Sample32 clip(Sample32 samp)
{
  return samp > 1.0 ? 1.0 :
         samp < -1.0 ? -1.0 : samp;
}

int InitDSPSystem()
{
  init_memory_pool(POOL_SIZE, pool);

  if (Pa_Initialize()) {
    fprintf(stderr, "Error initializing PortAudio");
    return 1;
  }

  return 0;
}

int NewDSPKernel(DSPKernel **outKernel)
{
  DSPKernel *kernel = malloc(sizeof(DSPKernel));
  PaError err;
  err = Pa_OpenDefaultStream(&kernel->stream,
                             0, 1,
                             paFloat32, 44100.0,
                             256,
                             (PaStreamCallback *)DSPKernelCallback,
                             kernel);
  if (paNoError != err) {
    fprintf(stderr, "Couldn't initialize audio stream: %s.\n", Pa_GetErrorText(err));
    return 1;
  }
  kernel->voiceList = NULL;
  *outKernel = kernel;
  return 0;
}

int DisposeDSPKernel(DSPKernel *kernel)
{
  free(kernel);
  return 0;
}

int DSPKernelCallback(const void *bufferIn, void *bufferOut,
                      unsigned long frameCount,
                      const PaStreamCallbackTimeInfo *timeInfo,
                      PaStreamCallbackFlags statusFlags,
                      DSPKernel *kernel)
{
  Sample32 *out = (Sample32 *)bufferOut;
  int frame;
  Sample32 sampleOut;
  Voice *voice;

  for (frame = 0; frame < frameCount; frame++) {
    sampleOut = 0.0;
    for (voice = kernel->voiceList; voice != NULL; voice = voice->next) {
      sampleOut += voice->render(voice->state);
      voice->trans(voice->state);
    }
    *out++ = clip(sampleOut);
  }

  return paContinue;
}

int DSPKernelStart(DSPKernel *kernel)
{
  PaError err = Pa_StartStream(kernel->stream);
  if (paNoError != err) {
    fprintf(stderr, "Couldn't start stream: %s.\n", Pa_GetErrorText(err));
    return 1;
  }
  return 0;
}

int DSPKernelStop(DSPKernel *kernel)
{
  PaError err = Pa_StopStream(kernel->stream);
  if (paNoError != err) {
    fprintf(stderr, "Couldn't stop stream: %s.\n", Pa_GetErrorText(err));
    return 1;
  }
  return 0;
}

VoiceID NewVoice(DSPKernel *kernel, RenderFunc render, TransitionFunc trans, void *state)
{
  Voice *voice = malloc_ex(sizeof(Voice), pool);
  voice->render = render;
  voice->trans = trans;
  voice->state = state;
  voice->next = kernel->voiceList;
  kernel->voiceList = voice;
  return (VoiceID)voice;
}

int RemoveVoice(DSPKernel *kernel, Voice *remove)
{
  Voice *voice = kernel->voiceList;

  if (kernel->voiceList == remove) {
    kernel->voiceList = remove->next;
    free_ex(remove, pool);
    return 0;
  }
  
  while (voice->next && voice->next != remove) {
    voice = voice->next;
  }

  if (voice->next) {
    voice->next = remove->next;
    free_ex(remove, pool);
    return 0;		
  } else {             
    return -1;
  }
}

Sample32 noise()
{
  return (Sample32)rand()/RAND_MAX;
}
