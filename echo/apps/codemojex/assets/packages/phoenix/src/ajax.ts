import {
  global,
  XHR_STATES
} from "./constants"

export default class Ajax {

  // `body` is caller-dynamic (string | FormData | …) and stays `any`.
  // `global as any` probes browser globals (incl. the IE-only XDomainRequest, absent from lib.dom).
  static request(method: string, endPoint: string, headers: Record<string, string>, body: any, timeout?: number, ontimeout?: () => void, callback?: (response?: any) => void | Promise<void>): any {
    if((global as any).XDomainRequest){
      let req = new (global as any).XDomainRequest() // IE8, IE9
      return this.xdomainRequest(req, method, endPoint, body, timeout, ontimeout, callback)
    } else if((global as any).XMLHttpRequest){
      let req: XMLHttpRequest = new (global as any).XMLHttpRequest() // IE7+, Firefox, Chrome, Opera, Safari
      return this.xhrRequest(req, method, endPoint, headers, body, timeout, ontimeout, callback)
    } else if((global as any).fetch && (global as any).AbortController){
      // Fetch with AbortController for modern browsers
      return this.fetchRequest(method, endPoint, headers, body, timeout, ontimeout, callback)
    } else {
      throw new Error("No suitable XMLHttpRequest implementation found")
    }
  }

  static fetchRequest(method: string, endPoint: string, headers: Record<string, string>, body: any, timeout?: number, ontimeout?: () => void, callback?: (response?: any) => void | Promise<void>): AbortController | null {
    // body stays `any` (caller-dynamic request body forwarded straight to fetch).
    let options: {method: string, headers: Record<string, string>, body: any, signal?: AbortSignal} = {
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
      .then((response: Response) => response.text())
      .then((data: string) => this.parseJSON(data))
      // parseJSON yields dynamic JSON, so `data` here is `any`.
      .then((data: any) => callback && callback(data))
      // err is an unknown rejection reason; `name` is read, so a minimal shape is enough.
      .catch((err: {name?: string}) => {
        if(err.name === "AbortError" && ontimeout){
          ontimeout()
        } else {
          callback && callback(null)
        }
      })
    return controller
  }

  // req is the IE-only XDomainRequest object — absent from lib.dom, so genuinely `any`.
  static xdomainRequest(req: any, method: string, endPoint: string, body: any, timeout?: number, ontimeout?: () => void, callback?: (response?: any) => void | Promise<void>): any {
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

  // body stays `any` (caller-dynamic request body forwarded to req.send).
  static xhrRequest(req: XMLHttpRequest, method: string, endPoint: string, headers: Record<string, string>, body: any, timeout?: number, ontimeout?: () => void, callback?: (response?: any) => void | Promise<void>): XMLHttpRequest {
    req.open(method, endPoint, true)
    // `!` is type-only: assigning undefined matches the prior `any`-typed behaviour (XHR coerces to 0).
    req.timeout = timeout!
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

  // Returns parsed JSON of arbitrary shape (or null) — genuinely dynamic, so `any`.
  static parseJSON(resp: string): any {
    if(!resp || resp === ""){ return null }

    try {
      return JSON.parse(resp)
    } catch {
      console && console.log("failed to parse JSON response", resp)
      return null
    }
  }

  // values are dynamic (string | number | nested object), so the value type is `any`.
  static serialize(obj: Record<string, any>, parentKey?: string): string {
    // Annotated `string[]` (not bare `[]`): strict src lets the array evolve from the
    // `.push(string)` calls, but the test scope sets noImplicitAny:false, which disables
    // that evolution and would otherwise freeze it to `never[]`. Type-only, runtime-neutral.
    let queryStr: string[] = []
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

  // `object` matches the caller (Socket passes `params(): object`); the cast to the
  // index-accessible shape `serialize` consumes is type-only.
  static appendParams(url: string, params: object): string {
    if(Object.keys(params).length === 0){ return url }

    let prefix = url.match(/\?/) ? "&" : "?"
    return `${url}${prefix}${this.serialize(params as Record<string, any>)}`
  }
}
