
# react-native-face-detector

## Getting started

`$ npm install react-native-face-detector --save`

### Installation

#### iOS

##### Via Pods
1. Append the following lines to your `Podfile` 
```
	pod 'React', :path => '../node_modules/react-native', :modular_headers => true #important!!!

  pod 'Firebase/Core'
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionFaceModel'

	pod 'RNFaceDetector', :path=> '../node_modules/react-native-face-detector/ios'

```
2. Add `$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)` to your project `Build Settings` -> `Library Search Paths`

##### Manualy (not tested)
1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-face-detector` and add `RNFaceDetector.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNFaceDetector.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)

#### Android (not supported yet, WIP)

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNFaceDetectorPackage;` to the imports at the top of the file
  - Add `new RNFaceDetectorPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-face-detector'
  	project(':react-native-face-detector').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-face-detector/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-face-detector')
  	```

#### Both platforms
Don't forget to setup `Firebase`:
1. iOS[https://firebase.google.com/docs/ios/setup]
2. Android[https://firebase.google.com/docs/android/setup]

## Usage
```javascript
import { FaceDetector, FaceDetectorCameraView, } from 'react-native-face-detector';

class Screen extends React.Component {

  cameraRef = React.createRef()

  render() {
    return (
      <FaceDetectorCameraView
        ref={this.cameraRef}
        style={styles.container}
        cameraType={this.state.camera}
        options={this.options}
        onFacesDetected={this.handleFacesDetection}
      />
    )
  }

  handleFacesDetection = ({ faces, width, height, recordingTime, }) => {
    // do whatever you want\
  }

  handleStartPress = () => {
    if (this.cameraRef) {
      this.cameraRef.current.startRecording()
        .then(({ path, }) => {})
        .catch((e) => {
          console.warn(e, 'Something whent wrong');
        });
    }
  }

  handleStopPress = () => {
    if (this.cameraRef) {
      this.cameraRef.current.stopRecording(); // will resolve startRecording call
    }
  }

}
```

## API

### Configuration constants

FaceDetector contain setup options constants `FaceDetector.OPTIONS`

| Name | Type | Example | Description |
| --- | --- | --- | --- |
| PERFOMANCE_MODE | `String` | `performanceMode: FaceDetector.OPTIONS.PERFOMANCE_MODE.FAST` | Face detection performance mode. Values: `FAST|ACCURATE`|
| LANDMARK_MODE | `String` | `landmarkMode: FaceDetector.OPTIONS.LANDMARK_MODE.NONE` | Face detection landmark mode, declare that model must detect landmarks. Values: `ALL|NONE`|
| CONTOUR_MODE | `String` | `contourMode: FaceDetector.OPTIONS.CONTOUR_MODE.NONE` | Face detection contour mode, declare that model must detect contours. Values: `ALL|NONE`|
| LANDMARK_MODE | `String` | `classificationMode: FaceDetector.OPTIONS.LANDMARK_MODE.NONE` | Face detection classification mode, declare that model must detect opened eyes and smile. Values: `ALL|NONE`|

... (WIP)