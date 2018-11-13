
# react-native-nedb

## Getting started

`$ npm install react-native-nedb --save`

### Mostly automatic installation

`$ react-native link react-native-nedb`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-nedb` and add `RNNedb.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNNedb.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.nedb.RNNedbPackage;` to the imports at the top of the file
  - Add `new RNNedbPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-nedb'
  	project(':react-native-nedb').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-nedb/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-nedb')
  	```


## Usage
```javascript
import RNNedb from 'react-native-nedb';

// TODO: What to do with the module?
RNNedb;
```
  