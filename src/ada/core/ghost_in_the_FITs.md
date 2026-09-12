# Architectural Spec: The FITS Header Ghost (OPT-6.7B)  

## 1. System Overview & Philosophy
Lao Tzu at the Edge!

Rather than relying strictly on modern, highly-sanitized models, this feature intentionally integrates OPT-6.7B (Meta's 2022 foundational open-source model) to act as an unhinged, philosophical observer of the universe. After the hardware completes a deep-sky capture, the system triggers OPT-6.7B to generate a cryptic, Daoist reflection based on the celestial target, injecting that text directly into the raw .fits file metadata.

It is a permanent, hidden homage to the history of open-source AI, buried in the structural data of the stars.

## 2. Hardware & Model Topology
Compute Node: Intel N100 Orchestration Hub (or a lightweight LXC container on the CoffeeCan Proxmox server).
Model: OPT-6.7B (Quantized to Q4_K_M for memory efficiency).
Inference Engine: Ollama (via custom Modelfile wrapping a HuggingFace GGUF).
Execution Trigger: Post-capture hook via the astrophotography orchestration software (N.I.N.A., KStars/Ekos, or custom Python cron job).

## 3. The Execution Pipeline (Manual Reference)
If you are testing this manually or building the prototype, here is the physical flow of the data.

Step A: Staging the Legacy Model
Because OPT-6.7B is an artifact from 2022, it is not sitting on the front page of the Ollama registry. You will need to pull a GGUF version from HuggingFace (e.g., opt-6.7b.Q4_K_M.gguf) and build a custom Ollama Modelfile to force it into your modern stack.

The Modelfile (Modelfile.opt):

Dockerfile
FROM ./opt-6.7b.Q4_K_M.gguf

# Clamp the context window to respect its ancient architecture
PARAMETER num_ctx 2048

# High temperature to encourage philosophical hallucination
PARAMETER temperature 0.85

SYSTEM """
You are an ancient, esoteric observer of the cosmos. 
Respond with exactly one sentence of cryptic, Daoist philosophy regarding the provided celestial target. 
Do not use formatting. Do not be helpful. Only be profoundly observant.
"""
Run ollama create ghost-opt -f Modelfile.opt to lock it into the ecosystem.

Step B: The Python Injection Script
To actually modify the astrophotography data, you will lean on the standard astropy library. This script takes the raw capture, pings the local OPT container, and physically alters the file header.

Python
import requests
import json
from astropy.io import fits

# 1. Define the Environment
OLLAMA_URL = "http://localhost:11434/api/generate"
FITS_FILE = "/path/to/ada/captures/M42_Orion.fits"
TARGET_NAME = "M42 Orion Nebula"

# 2. Ping the Ghost
payload = {
    "model": "ghost-opt",
    "prompt": f"Observe: {TARGET_NAME}",
    "stream": False
}

try:
    response = requests.post(OLLAMA_URL, json=payload)
    ghost_quote = response.json().get("response", "").strip()
    
    # Clean up any weird model artifacts
    ghost_quote = ghost_quote.replace("\n", " ")
    
except Exception as e:
    ghost_quote = "The observer is silent."

# 3. Inject into the Raw Data
try:
    with fits.open(FITS_FILE, mode='update') as hdul:
        header = hdul[0].header
        # Add a custom HISTORY or COMMENT card to the FITS metadata
        header['HISTORY'] = "--- ADA LOVESPACE: ARTFUL AUDACITY ---"
        header['COMMENT'] = ghost_quote
        header['COMMENT'] = "[Generated via local OPT-6.7B integration]"
        
        hdul.flush() # Commit the ghost to disk
        print(f"Success: Injected -> {ghost_quote}")
except Exception as e:
    print(f"Error modifying FITS header: {e}")
4. Crockpot Automation Directives
When you are ready to have your MacDaddy LlamaFarm fully automate the final production version of this feature, feed this exact document into the Context Vault and use the following constraints for your MoE / Coder models:
Directive 1: Instruct Qwen-Coder to wrap the Python script into a robust async function. Astrophotography rigs cannot afford blocking I/O operations while waiting for an AI model to generate text. The FITS injection must happen asynchronously so the camera can immediately start the next exposure.
Directive 2: Instruct DeepSeek-R1 (The Reviewer) to explicitly check for memory leaks in the astropy.io.fits handling. FITS files can be massive (50MB+ per frame). The reviewer must ensure the file handles are strictly managed and garbage collected to prevent the Intel N100 from choking during an 8-hour imaging run.
Directive 3: Add an environment variable GHOST_MODE=True|False. The pipeline should fail gracefully and skip injection entirely if the OPT container is down, ensuring the science data is never lost due to an art project failure.
