/* 
    nedb storage for react-native
*/
import { NativeModules } from "react-native";
import async from 'async';

const NeDBManager = NativeModules.NeDBManager;

class Storage {

    exists = (filename, callback) => {
        return new Promise(async (resolve, reject) => {
          const result = await NeDBManager.exists(filename);
          if (callback) callback(result);
          return resolve(result);
        })
    }

    rename = (filename, newFilename, callback) => {
        return new Promise(async (resolve, reject) => {
            try {
                const result = await NeDBManager.rename(filename, newFilename, {});
                if (callback) callback(null);
                return resolve(result);
            } catch (error) {
                if (callback) callback(error);
                return reject(error);
            }
        })
    }

    writeFile = (filename, contents, options, callback) => {
        if (typeof options === 'function') {
            callback = options;
        }
        return new Promise(async (resolve, reject) => {
            try {
                const result = await NeDBManager.writeFile(filename, contents, {});
                if (callback) callback(null);
                return resolve(result);
            } catch (error) {
                if (callback) callback(error);
                return reject(error);
            }
        })
    }

    unlink = (filename, callback) => {
        return new Promise(async (resolve, reject) => {
            try {
                const result = await NeDBManager.unlink(filename);
                if (callback) callback(null);
                resolve(result);
            } catch (error) {
                if (callback) callback(error);
                reject(error);
            }
        })
    }

    appendFile = (filename, contents, callback) => {
        if (typeof options === 'function') {
            callback = options;
        }
        return new Promise(async (resolve, reject) => {
            try {
                const result = await NeDBManager.appendFile(filename, contents);
                if (callback) callback(null);
                resolve(result);
            } catch (error) {
                if (callback) callback(error);
                reject(error);
            }
        })
    }

    readFile = (filename, options, callback) => {
        if (typeof options === 'function') {
            callback = options;
        }
        return new Promise(async (resolve, reject) => {
            try {
                const result = await NeDBManager.readFile(filename);
                if (callback) callback(null, result);
                resolve(result);
            } catch (error) {
                if (callback) callback(error, null);
                reject(error);
            }
        })
    }

    mkdirp = (dir, callback) => {
        return new Promise(async (resolve, reject) => {
            try {
                const result = await NeDBManager.mkdir(dir, {});
                if (callback) callback(null);
                resolve(result);
            } catch (error) {
                if (callback) callback(error);
                reject(error);
            }
        })
    }

    /**
     * Explicit name ...
     */
    ensureFileDoesntExist = (file, callback) => {
        this.exists(file, (exists) => {
            if (!exists) { return callback(null); }
        
            this.unlink(file, (err) => { return callback(err); });
        });
    }

    /**
     * Flush data in OS buffer to storage if corresponding option is set
     * @param {String} options.filename
     * @param {Boolean} options.isDir Optional, defaults to false
     * If options is a string, it is assumed that the flush of the file (not dir) called options was requested
     */
    flushToStorage = (options, callback) => {
        return callback(null);
    }

    /**
     * Fully write or rewrite the datafile, immune to crashes during the write operation (data will not be lost)
     * @param {String} filename
     * @param {String} data
     * @param {Function} cb Optional callback, signature: err
     */
    crashSafeWriteFile = (filename, data, cb) => {
        var callback = cb || function () {}
            , tempFilename = filename + '~';

        async.waterfall([
            async.apply(this.flushToStorage, { filename, isDir: true })
        , (cb) => {
            this.exists(filename, (exists) => {
                if (exists) {
                    this.flushToStorage(filename, function (err) { return cb(err); });
                } else {
                    return cb();
                }
            });
            }
        , (cb) => {
            this.writeFile(tempFilename, data, (err) => { return cb(err); });
            }
        , async.apply(this.flushToStorage, tempFilename)
        , (cb) => {
            this.rename(tempFilename, filename, (err) => { return cb(err); });
            }
        , async.apply(this.flushToStorage, { filename, isDir: true })
        ], (err) => { return callback(err); })
    }

    /**
     * Ensure the datafile contains all the data, even if there was a crash during a full file write
     * @param {String} filename
     * @param {Function} callback signature: err
     */
    ensureDatafileIntegrity = (filename, callback) => {
        var tempFilename = filename + '~';
        this.exists(filename, (filenameExists) => {
            // Write was successful
            if (filenameExists) { return callback(null); }

            this.exists(tempFilename, (oldFilenameExists) => {
            // New database
            if (!oldFilenameExists) {
                return this.writeFile(filename, '', function (err) { callback(err); });
            }

            // Write failed, use old version
            this.rename(tempFilename, filename, function (err) { return callback(err); });
            });
        });
    }
}

export default new Storage();
