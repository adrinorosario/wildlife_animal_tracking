# Animap (Wildlife Tracker)

A real-time wildlife helpline and conservation platform with on-device AI recognition and GPS-based emergency features.

## Objective
Animap aims to streamline the reporting and management of wildlife incidents by enabling rangers, tourists, and locals to instantly report injuries, sightings, or lost animals. It combines mobile accessibility with edge intelligence to provide rapid response capabilities.

## Problem it Solves
Manual reporting of wildlife incidents is often slow and lacks precise location or species data. Animap provides an integrated solution for immediate, data-rich alerts to vets and forest officers.

## Why it Matters
Efficient conservation efforts rely on real-time data. By automating species recognition and location mapping, Animap minimizes the response time for injured or displaced wildlife, potentially saving animal lives and mitigating human-wildlife conflict.

## Constraints
* **Edge Inference**: AI models must be lightweight enough for real-time mobile inference ($224 \times 224$ input size).
* **Connectivity**: Must handle intermittent network coverage in remote forest areas (broadcast-first, upload-later logic).
* **User Safety**: SOS features must be intuitive and functional under pressure.

## Approach
* **Mobile-First Development**: A cross-platform Flutter application for wide accessibility.
* **Edge AI Integration**: Utilizing TFLite and ONNX for on-device species identification without persistent internet connectivity.
* **Cloud Infrastructure**: Firebase-backed authentication and data management for real-time incident updates.

## Architecture
* **Frontend**: **Flutter (Dart)** with Material 3 design and customized Savannah theme.
* **Backend**: **Firebase** for authentication, real-time database, and image storage.
* **Edge AI**: **TFLite** based classification using an `AnimalClassifier` for local inference.
* **APIs**: **Google Maps API** for geolocation and incident pinning.

## Implementation Notes
* **Recognition**: Model trained on fine-grain animal species, integrated using the `tflite_flutter` package.
* **Pre-processing**: On-device image resizing and normalization to $224 \times 224$ pixels.
* **Offline Logic**: Incident credentials (metadata) are broadcast immediately via SMS/low-bandwidth protocols, with high-res image upload deferred until connectivity is restored.

## Results
* **Alert Categories & Response Times**:
  * **Injury (Red)**: $2$ days timeframe.
  * **Sighting (Blue)**: $6$ hours timeframe.
  * **Lost (Yellow)**: $1$ day timeframe.
  * **Displaced (Orange)**: $12$ hours timeframe (emits radius alert).

## Trade-offs
* **Latency vs. Accuracy**: Edge inference provides immediate results but is limited by mobile GPU/NPU power compared to cloud inference.
* **Memory Footprint**: Keeping model size small to ensure compatibility across a wide range of mobile devices.

## Reflection
Integrating computer vision into a mobile workflow transforms the passive process of observing wildlife into an active tool for conservation. The next logical step is integrating multi-modal data (audio/acoustic sensors) for even more robust identification.

## Tech Stack
* **Framework**: Flutter (Dart)
* **Backend**: Firebase (Auth, Database)
* **AI Engine**: TFLite, ONNX
* **APIs**: Google Maps, Firebase Cloud Messaging

## Project Type
AI / Computer Vision / Mobile Application
