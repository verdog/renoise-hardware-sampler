# renoise-hardware-sampler
Automated creation of instruments based on recordings from a hardware device for Renoise

---

## How To

### Installation

Drag and drop `hack.dpp.hwsampler.xrnx` onto an active Renoise window.

### Usage

To use the tool, right click on the waveform editor and choose "Record Samples from MIDI Hardware".

#### Overview

The general idea of this tool is to automate the process of recording played notes from your hardware, trimming silence, normalizing volume, and mapping to key zones. The buttons you see when you open the menu change various things about how this is done.

#### Start, Stop, Recording Settings

##### Start

Starts the recording process.

##### Stop

Stops the recording process.

##### Recording Settings

Opens the Renoise sample recording window. **You must change the settings in this window to your liking manually**, although default usually works just fine too.

This is a good time to make sure that Renoise can hear your hardware. Play a note and the indicator at the top of the sample recorder window should react to the audio.

#### Midi Device

Midi device to send note commands to.

#### Low Octave, High Octave, Notes Matrix

In this section you decide which notes to actually sample.

##### Low Octave

The lowest octave to sample (inclusive). The octave settings correspond to the octave numbers in Renoise.

##### High Octave

The highest octave to sample (inclusive).

##### Notes Matrix

Select the notes you would like to sample in each of the selected octaves by clicking the note buttons. Dark grey means the note won't be sampled, and light grey means it will be sampled.

#### Note Mapping Style

This tool maps recorded notes in the following fashion:

For each recorded note, map it to its base note up to the next recorded note.

Extend the mapping of the lowest recorded note to C0.

Extend the mapping of the highest recorded note to B9.

##### Example

If we sample the following notes:

```
C4, E4, G#4
```

They would be mapped in the following way:

* The C4 sample would be mapped to C0 - D#4
* The E4 sample would be mapped to E4 - G4
* The G#4 sample would be mapped to G#4 - B9

#### Hold Time, Release Time

In this section you tweak the length of the recorded sample.

##### Hold Time

The amount of time in seconds that the recorded note will be held down.

##### Release Time

The amount of time to wait, after releasing the note, to stop recording the sample.

#### Normalize Sample Volumes, Trim Silences

These are post-processing options. Click these buttons after the recording process is finished. It is also possible to use these on samples recorded via other means than this tool -- the buttons simply process all current samples.

These functions can take some time when you have recorded a lot of samples. If the Renoise dialog asking to kill the script pops up, select no and wait patiently. :-)

##### Normalize Sample Volumes

Boost sample volume as much as possible, while maintaining the current relative volume levels between samples. In other words, find the loudest sample, maximize its volume, and increase the volume of all other samples by that amount.

##### Trim Silences

For each sample, remove any leading silence.

#### Inst. Name

Sets the instrument name after samples are recorded.

## Issues and Pull Requests

If you find a bug or would like an additional feature, feel free to open an issue or create a pull request.
