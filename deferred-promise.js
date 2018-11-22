export class DeferredPromise {

    promise = null
    _resolver = null
    _rejecter = null

    constructor() {
        this._promise = new Promise((resolve, reject) => {
            this._resolver = resolve;
            this._rejecter = reject;
        });
    }

    resolve(data) {
        this._resolver(data);
    }

    reject(data) {
        this._rejecter(data);
    }

}