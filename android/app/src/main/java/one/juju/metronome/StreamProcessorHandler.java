package one.juju.metronome;

import be.tarsos.dsp.AudioProcessor;

public interface StreamProcessorHandler {
    AudioProcessor getProcessor();
}
