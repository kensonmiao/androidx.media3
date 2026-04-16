## Build Guide - Windows + Docker

This guide walks you through building the FFmpeg libraries using Docker on Windows.

### Prerequisites

- Docker Desktop installed on Windows
- Android NDK (recommended: r26d)

### Step-by-Step Instructions

#### Step 1: Download Android NDK
Download the Android NDK r26d (Linux version) from the official Google repository:

[Android NDK Downloads](https://developer.android.com/ndk/downloads)

Tested version: `android-ndk-r26d-linux.zip`

#### Step 2: Start Docker Container

Open **PowerShell** or **Command Prompt** and run:

```powershell
docker run -it `
  -v "D:\Your\Workspace\Path":/workspace `
  -v "D:\Path\To\NDK":/ndk `
  --name ffmpeg-build `
  ubuntu:latest bash
```

#### Step 3: Install Dependencies (Inside Docker)

```bash
apt update && apt install -y \
  git wget unzip \
  build-essential \
  yasm nasm \
  pkg-config \
  cmake
```

#### Step 4: Go to Workspace

```bash
cd /workspace
```

#### Step 5: Clone the Project (Inside Docker only!)

```bash
git clone https://github.com/yourusername/your-project.git
cd your-project
```
⚠️ **Important**: Do **NOT** clone or unzip on Windows. Use only inside Docker to prevent CRLF line ending issues.

#### Step 6: Navigate to Build Folder

```bash
cd libraries/decoder_ffmpeg/src/main/jni
```

#### Step 7: Extract NDK Inside Docker

```bash
unzip /ndk/android-ndk-r26d-linux.zip -d /ndk
```

#### Step 8: Set NDK Path

```bash
export ANDROID_NDK_HOME=/ndk/android-ndk-r26d
```

#### Step 9: Clone FFmpeg Source

```bash
git clone https://github.com/FFmpeg/FFmpeg.git
```
⚠️ **Important**: Do **NOT** clone on Windows. Use only inside Docker to prevent CRLF line ending issues.

#### Step 10: Build FFmpeg

```bash
./build_ffmpeg_multi_platform.sh $PWD/.. $ANDROID_NDK_HOME linux-x86_64 h264 aac ac3 mp3 flac vp9 av1 hevc eac3
```

#### Step 11: Build the Android Library
1. Open the project in Android Studio (the root folder of the Media3 project).
2. Wait for Gradle sync to finish.
3. Open the Terminal in Android Studio (usually at the bottom).
4. Run the following command in the project root folder:

```powershell
.\gradlew :lib-decoder-ffmpeg:assembleRelease
```

Output Location:
```powershell
libraries\decoder_ffmpeg\buildout\outputs\aar
```

### Important Notes

- Always perform git clone and unzip inside the Docker container.
- Windows line endings (CRLF) will break the build scripts.
- You can change the decoder list as needed.

### Common Issues

- Script permission error: Run chmod +x build_ffmpeg_multi_platform.sh
- NDK not found: Verify your volume mounts and ANDROID_NDK_HOME
- Line ending errors: Re-clone the project inside Docker