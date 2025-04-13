# DCS - SayIntentionsAI Adapter

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/papiplanes/sayintentions-dcs-adapter/blob/main/LICENSE)
![Platform](https://img.shields.io/badge/platform-DCS-blue)
![Status](https://img.shields.io/badge/status-active-brightgreen)

## ✈️ Overview

**DCS - SayIntentionsAI Adapter** is a lightweight integration layer that exports live telemetry data from **Digital Combat Simulator (DCS)** to the [SayIntentions.AI](https://www.sayintentions.ai/) platform using their [SimAPI](https://sayintentionsai.freshdesk.com/support/solutions/articles/154000221017-simapi-developer-howto-integrating-sayintentions-ai-with-any-flight-simulator).

SayIntentions.AI provides AI-powered ATC for flight simulators — this adapter allows DCS pilots to tap into that realism by transmitting aircraft position, heading, altitude, and other key data points in real-time.

## 🔧 Setup Instructions

1. Download the latest release zip file
2. Upack the release zip to get "SayIntentions" folder
3. Put the `SayIntentions` folder in `<USER>/Saved Games/<DCS>/Scripts/`
4. Add the following line to `Export.lua`. If the file does not exist, create it and add the following line. 

```bash
local dcssilfs=require('lfs');dofile(dcssilfs.writedir()..'Scripts\\SayIntentions\\connector.lua')
```

## ✅ Supported Modules

The adapter is designed to support a wide range of flyable aircraft in DCS. Currently tested and confirmed working with:

- F/A-18C Hornet
- UH-1H

**Note**: You may be asking, "Why are only two modules supported?". Great question, if we look at the required telemetry data for [SimAPI ](https://portal.sayintentions.ai/simapi/v1/input_variables.txt), we see two categories of data we need. 1) Generic telemetry that all aircraft share 2) Aircraft specific attributes such as Transponder Codes, Electrical System State, Com1/Com2 Frequencies, etc. 

Each of these aircraft specific attributes must be extracted uniquely for each aircraft as they all differ. This offer more granular customization of how each module will interact with the API and allows more compatible modules to be added by the community. 

