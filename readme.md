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

  These modules have the following features
- Landing detection (Touch down location, vertical velocity)
- Mode 3 Transponder Code
- Transponder Ident
- Accurate indicated altitude (based on what pilots see on their gauges)
- Total aircraft weigth (empty weight + fuel + pilot)
- Wind telemetry
- Local Time

**Note**: You may be asking, "Why are only two modules supported?". Great question, if we look at the required telemetry data for [SimAPI ](https://portal.sayintentions.ai/simapi/v1/input_variables.txt), we see two categories of data we need. 1) Generic telemetry that all aircraft share 2) Aircraft specific attributes such as Transponder Codes, Electrical System State, Com1/Com2 Frequencies, etc. 

Each of these aircraft specific attributes must be extracted uniquely for each aircraft as they all differ. This offer more granular customization of how each module will interact with the API and allows more compatible modules to be added by the community. 

## Example of SimAPI Expected simAPI_input.json file

```json
{
    "sim": {
        "adapter_version": "DCS_SIMAPI_V1",
        "exe": "DCS",
        "name": "DCS",
        "simapi_version": "v1",
        "variables": {
            "AIRSPEED INDICATED": 12,
            "AIRSPEED TRUE": 0,
            "AMBIENT WIND DIRECTION": 359,
            "AMBIENT WIND VELOCITY": 9,
            "CIRCUIT COM ON:1": 1,
            "CIRCUIT COM ON:2": 1,
            "COM ACTIVE FREQUENCY:1": 305,
            "COM ACTIVE FREQUENCY:2": 305,
            "COM RECEIVE:1": 1,
            "COM RECEIVE:2": 1,
            "COM TRANSMIT:1": 1,
            "COM TRANSMIT:2": 1,
            "ELECTRICAL MASTER BATTERY:0": 1,
            "ENGINE TYPE": 1,
            "INDICATED ALTITUDE": 1820,
            "LOCAL TIME": 65700,
            "MAGNETIC COMPASS": 117,
            "MAGVAR": -13,
            "PLANE ALTITUDE": 1848,
            "PLANE BANK DEGREES": 0,
            "PLANE HEADING DEGREES TRUE": 129,
            "PLANE LATITUDE": 36.227024019983,
            "PLANE LONGITUDE": -115.04815793843,
            "PLANE PITCH DEGREES": -1,
            "SEA LEVEL PRESSURE": 2992,
            "SIM ON GROUND": 1,
            "TOTAL WEIGHT": 35633,
            "TRANSPONDER CODE:1": 0,
            "TRANSPONDER IDENT": 0,
            "TRANSPONDER STATE:1": 0,
            "TYPICAL DESCENT RATE": 2500,
            "VERTICAL SPEED": -1,
            "WHEEL RPM:1": 0,
            "ZULU TIME": 65700
        },
        "version": "DCS Version: 2.9.14.83940  Module: FA-18C_hornet"
    }
}
```
