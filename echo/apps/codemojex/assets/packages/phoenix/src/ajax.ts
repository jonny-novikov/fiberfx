import {
  global,
  XHR_STATES
} from "./constants"

export default class Ajax {

  static request(method: string, endPoint: string, headers: any, body: any, timeout?: number, ontimeout?: any, callback?: (response?: any) => void | Promise<void>): any {
    if((global as any).XDomainRequest){
      let req = new (global as any).XDomainRequest() // IE8, IE9
      return this.xdomainRequest(req, method, endPoint, body, timeout, ontimeout, callback)
    } else if((global as any).XMLHttpRequest){
      let req = new (global as any).XMLHttpRequest() // IE7+, Firefox, Chrome, Opera, Safari
      return this.xhrRequest(req, method, endPoint, headers, body, timeout, ontimeout, callback)
    } else if((global as any).fetch && (global as any).AbortController){
      // Fetch with AbortController for modern browsers
      return this.fetchRequest(method, endPoint, headers, body, timeout, ontimeout, callback)
    } else {
      throw new Error("No suitable XMLHttpRequest implementation found")
    }
  }

  static fetchRequest(method: string, endPoint: string, headers: any, body: any, timeout?: number, ontimeout?: any, callback?: (response?: any) => void | Promise<void>): AbortController | null {
    let options: {method: string, headers: any, body: any, signal?: AbortSignal} = {
      method,
      headers,
      body,
    }
    let controller: AbortController | null = null
    if(timeout){
      controller = new AbortController()
      const _timeoutId = setTimeout(() => controller!.abort(), timeout)
      options.signal = controller.signal
    }
    ;(global as any).fetch(endPoint, options)
      .then((response: any) => response.text())
      .then((data: any) => this.parseJSON(data))
      .then((data: any) => callback && callback(data))
      .catch((err: any) => {
        if(err.name === "AbortError" && ontimeout){
          ontimeout()
        } else {
          callback && callback(null)
        }
      })
    return controller
  }

  static xdomainRequest(req: any, method: string, endPoint: string, body: any, timeout?: number, ontimeout?: any, callback?: (response?: any) => void | Promise<void>): any {
    req.timeout = timeout
    req.open(method, endPoint)
    req.onload = () => {
      let response = this.parseJSON(req.responseText)
      callback && callback(response)
    }
    if(ontimeout){ req.ontimeout = ontimeout }

    // Work around bug in IE9 that requires an attached onprogress handler
    req.onprogress = () => { }

    req.send(body)
    return req
  }

  static xhrRequest(req: any, method: string, endPoint: string, headers: any, body: any, timeout?: number, ontimeout?: any, callback?: (response?: any) => void | Promise<void>): any {
    req.open(method, endPoint, true)
    req.timeout = timeout
    for(let [key, value] of Object.entries(headers)){
      req.setRequestHeader(key, value)
    }
    req.onerror = () => callback && callback(null)
    req.onreadystatechange = () => {
      if(req.readyState === XHR_STATES.complete && callback){
        let response = this.parseJSON(req.responseText)
        callback(response)
      }
    }
    if(ontimeout){ req.ontimeout = ontimeout }

    req.send(body)
    return req
  }

  static parseJSON(resp: string): any {
    if(!resp || resp === ""){ return null }

    try {
      return JSON.parse(resp)
    } catch {
      console && console.log("failed to parse JSON response", resp)
      return null
    }
  }

  static serialize(obj: any, parentKey?: string): string {
    let queryStr = []
    for(var key in obj){
      if(!Object.prototype.hasOwnProperty.call(obj, key)){ continue }
      let paramKey = parentKey ? `${parentKey}[${key}]` : key
      let paramVal = obj[key]
      if(typeof paramVal === "object"){
        queryStr.push(this.serialize(paramVal, paramKey))
      } else {
        queryStr.push(encodeURIComponent(paramKey) + "=" + encodeURIComponent(paramVal))
      }
    }
    return queryStr.join("&")
  }

  static appendParams(url: string, params: any): string {
    if(Object.keys(params).length === 0){ return url }

    let prefix = url.match(/\?/) ? "&" : "?"
    return `${url}${prefix}${this.serialize(params)}`
  }
}
