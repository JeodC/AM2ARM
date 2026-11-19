// A rolling Arachnus that reaches the spikes enters its stunned recovery state.
if (other.state == 4) with (other) {
    state = 90;
    statetime = 0;
}

