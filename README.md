## Connect Docker containers to INET using TAP interfaces

This repository shows a minimal setup to connect Docker containers to an INET/OMNeT++ emulation using TAP interfaces. The architecture is based on the n3s tutorial and INET emulation showcases:

- n3s tutorial: https://www.sei.cmu.edu/blog/how-to-use-docker-and-ns-3-to-create-realistic-network-simulations/
- INET emulation showcase: https://inet.omnetpp.org/docs/showcases/emulation/videostreaming/doc/index.html

### Quick start

1. Create TAP devices and configure networking:

```bash
./setup_devices.sh
```

2. Start the INET simulation (either in the IDE or from the console):

```bash
inet -u Cmdenv -f omnetpp.ini
```

3. Run your emulation experiments.

4. When finished, remove the TAP devices and restore local networking:

```bash
./teardown.sh
```

