
import React, { PureComponent, } from 'react';
import { View, StyleSheet, ViewPropTypes, NativeModules, requireNativeComponent, } from 'react-native';
import PropTypes from 'prop-types'
import { DeferredPromise, } from './deferred-promise';

const { FaceDetector, FaceDetectorCameraViewManager, } = NativeModules;

const RNFaceDetectorCameraView = requireNativeComponent("FaceDetectorCameraView")


const {
    OPTIONS: {
        PERFOMANCE_MODE: {
            FAST: PMFast,
            ACCURATE: PMAccurate,
        },
        LANDMARK_MODE: {
            NONE: LMNone,
            ALL: LMAll,
        },
        CONTOUR_MODE: {
            NONE: CnMNone,
            ALL: CnMAll,
        },
        CLASSIFICATION_MODE: {
            NONE: ClMNone,
            ALL: ClMAll,
        },
    },
    LANDMARK: { },
    CONTOUR: { },
} = FaceDetector;


class FaceDetectorCameraView extends PureComponent {

    static propTypes = {
        style: ViewPropTypes.style,
        cameraType: PropTypes.oneOf(['back', 'front']),
        onFacesDetected: PropTypes.func,
        options: PropTypes.shape({
            performanceMode: PropTypes.oneOf([PMFast, PMAccurate]),
            landmarkMode: PropTypes.oneOf([LMNone, LMAll]),
            contourMode: PropTypes.oneOf([CnMNone, CnMAll]),
            classificationMode: PropTypes.oneOf([ClMNone, ClMAll]),
            minFaceSize: PropTypes.number,
            isTrackingEnabled: PropTypes.bool,
        }),
    }

    static defaultProps = {
        cameraType: 'back',
        options: {
            performanceMode: PMFast,
            landmarkMode: LMAll,
            contourMode: CnMNone,
            classificationMode: ClMNone,
            minFaceSize: 0.2,
            isTrackingEnabled: false,
        }
    }

    cameraRef = React.createRef()

    recordingPromise = null

    recordingStarted = false

    render() {
        const { style, cameraType, options, } = this.props;

        const cameraStyles = StyleSheet.flatten([
            styles.camera,
            style ? style : null,
        ])

        return (
            <RNFaceDetectorCameraView
                ref={this.cameraRef}
                style={cameraStyles}
                cameraType={cameraType}
                options={options}
                onFacesDetected={this.handleFaceDetection}
            />
        )
    }

    handleFaceDetection = ({ nativeEvent, }) => {
        if (typeof this.props.onFacesDetected === 'function') {
            this.props.onFacesDetected(nativeEvent)
        }
    }

    startRecording = (options = {}) => {
        if (this.cameraRef && !this.recordingStarted) {
            this.recordingPromise = new DeferredPromise();
            const reactNode = findNodeHandle(this.cameraRef.current);
            FaceDetectorCameraViewManager.startRecording(reactNode, options, (isRecordingStarted, error) => {
                if (!isRecordingStarted) {
                    this.recordingPromise.reject(error);
                }
                this.recordingStarted = isRecordingStarted;
            });
            return this.recordingPromise.promise;
        }
        return Promise.reject('Camera already recording');
    }

    stopRecording = () => {
        if (this.cameraRef && this.recordingStarted) {
            const reactNode = findNodeHandle(this.cameraRef.current);
            FaceDetectorCameraViewManager.stopRecording(reactNode, {}, (res) => {
                this.recordingStarted = false;
                if (!res.hasError) {
                    this.recordingPromise.resolve(res);
                } else {
                    this.recordingPromise.reject(res.errorMessage);
                }
                this.recordingPromise = null;
            });
        }
    }

}

const styles = StyleSheet.create({
    camera: {
        flex: 1,
    },
})

export { FaceDetector, FaceDetectorCameraView, };
