# renoise-hardware-sampler
Automated creation of instruments based on recordings from a hardware device for Renoise

![GUI](img/menu.png)

---

## How To

### Building

Run `./package.sh` to create the .xrnx file.

You can also download the latest .xrnx in the releases section.

### Installation

Drag and drop `hack.dpp.hwsampler.xrnx` onto an active Renoise window.

### Overview

The general idea of this tool is to automate the process of recording played notes from your hardware, trimming silence, normalizing volume, and mapping to key zones. The buttons you see when you open the menu change various things about how this is done.

### Usage

To use the tool, right click on the waveform editor and choose "Record Samples from MIDI Hardware".

### Tool Configuration and Features

##### Recording Settings

Opens the Renoise sample recording window. **You must change the settings in this window to your liking manually**, although default usually works just fine too.

This is a good time to make sure that Renoise can hear your hardware. Play a note and the indicator at the top of the sample recorder window should react to the audio.

**Note* make sure the "Create a new Instrument on each take" option in the Sample Recorder window is unchecked.

#### Midi and note options

In this section you configure your midi device and decide which notes to actually sample.

##### Midi Device

Midi device to send note commands to.

##### Low Octave

The lowest octave to sample (inclusive). The octave settings correspond to the octave numbers in Renoise.

##### High Octave

The highest octave to sample (inclusive).

##### Vel. Layers

For each sampled note, record this many samples of equally spaced velocities.

##### Notes Matrix

Select the notes you would like to sample in each of the selected octaves by clicking the note buttons. Dark gray means the note won't be sampled, and light gray means it will be sampled.

##### Mapping Style

This setting decides how samples will be mapped to keyzones. Specifically, it decides in which direction the keyzone will grow from the base note to make up for samples that are missing.

The lowest sample will always be mapped starting at C0, and the highest ending at B9.

###### Up

The key zone starts at the base note and extends upwards in pitch to the next note.

###### Down

Like up, but instead of extending to a higher note, the key zone is extended downward to a lower note.

###### Middle

The keyzone is extended in both directions. Any note that doesn't have a direct mapping to a sample will be mapped to the one closest in pitch.

##### Hold Time

The amount of time in seconds that the recorded note will be held down.

##### Release Time

The amount of time to wait, after releasing the note, to stop recording the sample.

##### Between Time

Time between the end of each sample recording and the start of the next one. Increase this if you find that not every sample gets stored into its slot in time because Renoise is still processing the recorded sample when the next sample recording starts.

#### Start, Stop, Recording Settings

##### Start

Starts the recording process.

##### Stop

Stops the recording process.

#### Normalize and Trim samples after recordings

When this is enabled, normalization and trimming of the samples will take place imediately after the sample recording job has finished. The "Process in background" feature will apply here as well.

#### Insert ADSR

When enabled, a "Volume AHDSR" envelope will be inserted into the **first** slot of the instrument's Modulation settings. When toggled off, the module will be removed but only if it's in the **first** slot of the instrument's Modulation settings.

**Note**, if the "Pad" or "Strings" tags are selected, the Release time of the envelope will be set to around 4 seconds. If any tags, including none, are selected, the default 1 second Release time will be applied.


#### Trigger as One-Shot

When enabled, all samples will be triggered as one-shot. When disabled, the default trigger value will be applied.

#### Post processing

These are post-processing options. Click these buttons after the recording process is finished. It is also possible to use these on samples recorded via other means than this tool -- the buttons simply process all current samples.

##### Process in background

When checked, the post processing options will use less CPU and process in the background, allowing you to close the tool window and use Renoise elsewhere. 

When not checked, more CPU is allocated to the post processing functions and they will finish more quickly. Closing the window will stop the processes in this case.

##### Normalize Sample Volumes

Boost sample volume as much as possible, while maintaining the current relative volume levels between samples. In other words, find the loudest sample, maximize its volume, and increase the volume of all other samples by the same amount.

##### Trim Silences

For each sample, remove any leading silence.

#### Instrument Naming

There are a few ways to construct an instrument's name. At a minimum, only the Instrument Name field is required. If using the Hardware Name and Tag options, the following naming pattern will be applied:

`HardwareName_Tags-Instrument Name`

For example:

```
MicroKorg_Pad-Fancy Darkness
```

Multiple tags can be included and will be applied in alphabetical order.

Tags can still be used even if a Hardware Name is not provided. The name format applied will be:

`Tag-Instrument Name`

For example:

```
Pad-Fancy Darkness
```

##### Instrument Name

This is the primary name of the instrument and is the only required name element.

##### Auto-Name button

The Auto-Name button generates a random instrument name. This is useful for when you've run out of naming ideas ;)

##### Hardware Name

An optional field that can help identify the hardware source of the sampled instrument.

##### Tag Matrix

Optional tags may be applied to assist in identifying the type of sound the instrument makes. More than one tag can be used at a time.

## Issues and Pull Requests

If you find a bug or would like an additional feature, feel free to open an issue or create a pull request.
