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

int DSPKernelDeviceCount()
{
  return Pa_GetDeviceCount();
}

void DSPKernelDeviceName(int deviceID, const char **outDeviceName)
{
  const PaDeviceInfo *device = Pa_GetDeviceInfo(deviceID);
  *outDeviceName = device ? device->name : NULL;
}

int NewDSPKernel(int deviceID, int channels, double fs, DSPKernel **outKernel)
{
  DSPKernel *kernel = malloc(sizeof(DSPKernel));
  kernel->fs = fs;
  kernel->ts = 1.0/fs;

  PaStreamParameters outParameters = { deviceID, channels, paFloat32, 0.0, NULL };
  PaError err;
  err = Pa_OpenStream(&kernel->stream,
                      NULL,
                      &outParameters,
                      fs,
                      256,
                      0,
                      (PaStreamCallback *)DSPKernelCallback,
                      kernel);
  if (paNoError != err) {
    fprintf(stderr, "Couldn't initialize audio stream: %s.\n", Pa_GetErrorText(err));
    return 1;
  }
  kernel->frame = 0;
  kernel->channels = 2;
  kernel->voiceList = NULL;
  kernel->lock = OS_SPINLOCK_INIT;
  *outKernel = kernel;
  return 0;
}

int DisposeDSPKernel(DSPKernel *kernel)
{
  free(kernel);
  return 0;
}

static inline void DSPKernelLock(DSPKernel *kernel)
{
  OSSpinLockLock(&kernel->lock);
}

static inline void DSPKernelUnlock(DSPKernel *kernel)
{
  OSSpinLockUnlock(&kernel->lock);
}

int DSPKernelCallback(const void *bufferIn, void *bufferOut,
                      unsigned long frameCount,
                      const PaStreamCallbackTimeInfo *timeInfo,
                      PaStreamCallbackFlags statusFlags,
                      DSPKernel *kernel)
{
  Sample32 *out = (Sample32 *)bufferOut;
  int frame;
  int channel;
  Sample32 sampleOut;
  Voice *voice;

  DSPKernelLock(kernel);
  for (frame = 0; frame < frameCount; frame++) {
    for (channel = 0; channel < kernel->channels; channel++) {
      sampleOut = 0.0;
      for (voice = kernel->voiceList; voice != NULL; voice = voice->next) {
        sampleOut += voice->render(kernel->frame * kernel->ts,
                                   voice->frame * kernel->ts,
                                   channel, voice->state);
      }
      *out++ = clip(sampleOut);
    }
    for (voice = kernel->voiceList; voice != NULL; voice = voice->next) {
      voice->frame++;
    }
    kernel->frame++;
  }
  DSPKernelUnlock(kernel);

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

VoiceID NewVoice(DSPKernel *kernel, RenderFunc render, void *state)
{
  Voice *voice = malloc_ex(sizeof(Voice), pool);
  voice->render = render;
  voice->frame = 0;
  voice->state = state;
  voice->next = kernel->voiceList;
  DSPKernelLock(kernel);
  kernel->voiceList = voice;
  DSPKernelUnlock(kernel);
  return (VoiceID)voice;
}

int RemoveVoice(DSPKernel *kernel, Voice *remove)
{
  Voice *voice = kernel->voiceList;
  DSPKernelLock(kernel);

  if (kernel->voiceList == remove) {
    kernel->voiceList = remove->next;
    free_ex(remove, pool);
    DSPKernelUnlock(kernel);
    return 0;
  }
  
  while (voice->next && voice->next != remove) {
    voice = voice->next;
  }

  int result;
  if (voice->next) {
    voice->next = remove->next;
    free_ex(remove, pool);
    result = 0;		
  } else {             
    result = -1;
  }

  DSPKernelUnlock(kernel);
  return result;
}

Sample32 noise()
{
  return (Sample32)rand()/RAND_MAX;
}
