//
//  Listener.swift
//  TutorOverlay server
//
//  Created by Bert Freudenberg on 04.07.16.
//  Copyright © 2016 Bert Freudenberg. All rights reserved.
//

import Foundation

func start_listening() {
    let queue = dispatch_queue_create("server-thread", DISPATCH_QUEUE_CONCURRENT)
    dispatch_async(queue, listen_loop)
}

func listen_loop() {
    // See Info.plist for actual port
    var addr = "127.0.0.1"
    var port = 49087
    if let a = NSBundle.mainBundle().objectForInfoDictionaryKey("ListenAddress") as? String {
        addr = a
    }
    if let p = NSBundle.mainBundle().objectForInfoDictionaryKey("ListenPort") as? Int {
        port = p
    }
    let server: TCPServer = TCPServer(addr: addr, port: port)
    let (success,msg) = server.listen()
    if success {
        print("listening on \(server.addr):\(server.port)")
        while true {
            if let client = server.accept() {
                receive_loop(client: client)
            } else {
                print("accept error")
            }
        }
    } else {
        print(msg)
    }

}

func receive_loop(client c: TCPClient) {
    print("new client from \(c.addr):\(c.port)")
    defer {
        c.close()
        print("disconnected \(c.addr):\(c.port)")
    }
    while (true) {
        c.send(str: "Tutor> ")
        if let bytes = c.read(1024*10) {
            print("received \(bytes.count) bytes: \(bytes)");
            if (bytes.count == 1 && bytes[0] == 4) {
                // treat a single ^D as end of connection
                c.send(str: "\r\nBYE\r\n")
                return;
            }
            if let string = String(bytes: bytes, encoding: NSUTF8StringEncoding) {
                let response = handle_command(string)
                print(response)
                c.send(str: response + "\r\n")
            } else {
                print("ERROR invalid utf8")
                c.send(str: "ERROR invalid utf8\r\n")
            }
        } else {
            return
        }
    }
}

func handle_command(cmd: String) -> String {
    if let response = overlayView?.receive_command_in_background(cmd) {
        return response
    } else {
        return "ERROR no overlay view"
    }
}
