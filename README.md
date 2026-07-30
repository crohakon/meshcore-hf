# VHF/UHF LoRa Mesh Bridge (Modem73 + socat)

An open-source, deployable container stack that bridges local LoRa mesh networks (MeshCore) across 20-50 mile regional gaps using standard VHF/UHF mobile radios. 

By replacing unreliable acoustic coupling with direct electronic PTT/Audio interfaces (Digirig or AIOC) and leveraging [modem73](https://github.com/RFnexus/modem73) for extreme noise-floor decoding, this setup provides a highly resilient, off-grid text backbone for isolated communities.

## System Architecture

This bridge acts as a smart RF Gateway between two different radio bands:
1. **Local Layer (915MHz LoRa):** A locally attached MeshCore node ingests text packets from the neighborhood mesh network.
2. **Translation (Raspberry Pi):** The packets are routed via `socat` into `modem73` (KISS over TCP), which encodes them into multicarrier OFDM/MFSK audio.
3. **Regional Layer (VHF/UHF):** The audio is sent through a Digirig or AIOC to a high-power VHF/UHF mobile transceiver, blasting the data over line-of-sight to a distant receiving node.

## Hardware Requirements

* **Host:** Raspberry Pi (3, 4, or 5) running a standard Linux OS with Docker installed.
* **Local Gateway:** Any MeshCore-compatible LoRa node (e.g., Heltec, T-Deck) configured for serial/KISS output over USB.
* **PTT/Audio Interface:** 
  * [Digirig Mobile](https://digirig.net/) OR
  * [AIOC (All-In-One-Cable)](https://github.com/skuep/AIOC)
* **Radio:** Any standard VHF/UHF mobile transceiver.

## Quick Start (Auto-Detection)

This container is designed to be plug-and-play. The startup script automatically scans your USB tree and detects standard AIOCs, Digirigs, and CH340-based MeshCore nodes.

1. Plug in your Digirig/AIOC and your MeshCore node to the Raspberry Pi.
2. Clone this repository:
   ```bash
   git clone https://github.com/crohakon/meshcore-hf.git
   cd meshcore-hf
   ```
3. Build and launch the stack:
   ```bash
   docker compose up -d --build
   ```
4. Verify the logs to ensure hardware was detected:
   ```bash
   docker compose logs -f
   ```

## Custom Hardware Configuration

If you are using clone USB serial chips or hardware that isn't automatically detected, you do not need to mess with Linux `udev` rules. You can override the hardware detection directly in the `docker-compose.yml` file.

Uncomment the `environment:` block in `docker-compose.yml` and provide your specific USB Vendor ID (VID) and Product ID (PID). *(You can find these by running `lsusb` on your host).*

```yaml
    environment:
      # Override PTT Interface (e.g., custom CP2102)
      - PTT_VID=10c4
      - PTT_PID=ea60
      # Override MeshCore Gateway (e.g., custom CH340)
      - MESH_VID=1a86
      - MESH_PID=7523
```

Rebuild the container (`docker compose up -d --build`) and the startup script will bind your specific chips to the internal bridge.

## Contributing

This is a community-driven off-grid project. Pull requests are welcome! If you find a new standard USB chip that should be added to the auto-detection script, please open an issue or submit a PR for `entrypoint.sh`.

## License

[MIT License](LICENSE) - Free to use, modify, and distribute.
